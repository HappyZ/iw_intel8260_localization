#!/usr/bin/python


import re
import os
import time
import argparse
import subprocess

from numpy import median


def which(program):
    '''
    check if a certain program exists
    '''
    def is_executable(fp):
        return os.path.isfile(fp) and os.access(fp, os.X_OK)
    fp, fn = os.path.split(program)
    if fp:
        if is_executable(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            path = path.strip('"')
            exec_file = os.path.join(path, program)
            if is_executable(exec_file):
                return exec_file
    return None


class Measurement(object):
    def __init__(self, interface, ofp=None, cali=(1.0, 0.0)):
        self.outf = None
        self.interface = interface
        # default file path for config for iw ftm_request
        self.config_fp = '/tmp/config_entry'
        if ofp:
            try:
                self.outf = open(ofp, 'w')
                self.outf.write(
                    'MAC,caliDist(cm),rawRTT(psec),rawDist(cm),time(sec)\n'
                )
            except Exception as e:
                print(str(e))
        self.regex = (
            r"Target: (([0-9a-f]{2}:*){6}), " +
            r"status: ([0-9]), rtt: ([0-9\-]+) psec, " +
            r"distance: ([0-9\-]+) cm"
        )
        self.cali = cali
        if not self.check_iw_validity():
            exit(127)  # command not found

    def check_iw_validity(self):
        '''
        check if iw exists and support FTM commands
        '''
        iwPath = which('iw')
        if iwPath is None:
            print('Err: iw command not found!')
            return False
        p = subprocess.Popen(
            "iw --help | grep FTM",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=True
        )
        out, err = p.communicate()
        if err:
            print('Err: {0}'.format(err))
            return False
        if 'FTM' not in out:
            print('Err: iw command does not support FTM')
            return False
        return True

    def prepare_config_file(self, targets):
        if not isinstance(targets, dict):
            return False
        with open(self.config_fp, 'w') as of:
            for bssid in targets:
                of.write(
                    "{0} bw={1} cf={2} retries=5 asap\n".format(
                        bssid,
                        targets[bssid]['bw'],
                        targets[bssid]['cf']
                    )
                )
        return True

    def get_distance_once(self):
        p = subprocess.Popen(
            "iw wlp58s0 measurement ftm_request " +
            "{0}".format(self.config_fp),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=True
        )
        out, err = p.communicate()
        if err:
            print(err)
            return []
        matches = re.finditer(self.regex, out)
        if not matches:
            return []
        result = []
        for match in matches:
            mac = match.group(1)
            status = int(match.group(3))
            rtt = int(match.group(4))
            raw_distance = int(match.group(5))
            if status is not 0 or raw_distance < -1000:
                continue
            distance = self.cali[0] * raw_distance + self.cali[1]
            result.append((mac, distance, rtt, raw_distance))
            if self.outf is not None:
                self.outf.write(
                    "{0},{1:.2f},{2},{3},{4:.6f}\n".format(
                        mac, distance, rtt, raw_distance, time.time()
                    )
                )
        return result

    def get_distance_median(self, rounds=10):
        '''
        use median instead of mean for less bias with small number of rounds
        '''
        result = {}
        avg_result = {}
        for i in range(rounds):
            # no guarantee that all rounds are successful
            for each in self.get_distance_once():
                if each[0] not in result:
                    result[each[0]] = []
                result[each[0]].append(each[1:])
        for mac in result:
            median_result[mac] = median([x[0] for x in result[mac]])
        return median_result

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        # properly close the file when destroying the object
        if self.outf is not None:
            self.outf.close()


def wrapper(args):
    args['config_entry'] = {
        '34:f6:4b:5e:69:1f': {
            'bw': 20,
            'cf': 2462
        }
    }
    counter = 1
    with Measurement(
        args['interface'],
        ofp=args['filepath'], cali=args['cali']
    ) as m:
        while 1:
            print('Round {0}'.format(counter))
            try:
                m.prepare_config_file(args['config_entry'])
                # only print out results
                results = m.get_distance_median(rounds=args['rounds'])
                for mac in results:
                    print('* {0} is {1:.4f}cm away.'.format(mac, results[mac]))
            except KeyboardInterrupt:
                break
            except Exception as e:
                print(str(e))
                break
            counter += 1


def main():
    p = argparse.ArgumentParser(description='iw measurement tool')
    p.add_argument(
        '--cali',
        nargs=2,
        default=(0.9084, 526.8163),
        type=float,
        help="calibrate final result"
    )
    p.add_argument(
        '--filepath', '-f',
        default=None,
        help="if set, will write raw fetched data to file"
    )
    p.add_argument(
        '--rounds',
        default=10,
        type=int,
        help="how many rounds to run one command; default is 10"
    )
    p.add_argument(
        '--interface', '-i',
        default='wlp58s0',
        help="set the wireless interface"
    )
    try:
        args = vars(p.parse_args())
    except Exception as e:
        print(str(e))
        sys.exit()
    wrapper(args)


if __name__ == '__main__':
    main()
