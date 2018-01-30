#!/usr/bin/python


import re
import os
import argparse
import subprocess

from numpy import min, max, median, mean, std


class Measurement(object):
    def __init__(self, interface, ofp=None, cali=(1.0, 0.0)):
        self.outf = None
        self.interface = interface
        self.config_fp = '/tmp/config_entry'
        if ofp:
            try:
                self.outf = open(ofp, 'w')
            except Exception as e:
                print(str(e))
        self.regex = (
            r"Target: (([0-9a-f]{2}:*){6}), " +
            r"status: ([0-9]), rtt: ([0-9\-]+) psec, " +
            r"distance: ([0-9\-]+) cm"
        )
        self.cali = cali

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
        return result

    def get_distance_avg(self, rounds=10):
        result = {}
        avg_result = {}
        for i in range(rounds):
            for each in self.get_distance_once():
                if each[0] not in result:
                    result[each[0]] = []
                result[each[0]].append(each[1:])
        for mac in result:
            avg_result[mac] = median([x[0] for x in result[mac]])
        return avg_result

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
    with Measurement(
        args['interface'],
        ofp=args['filepath'], cali=args['cali']
    ) as m:
        m.prepare_config_file(args['config_entry'])
        # print(m.get_distance_once())
        print(m.get_distance_avg())


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
