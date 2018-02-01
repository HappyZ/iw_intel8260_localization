#!/usr/bin/python


import os
import argparse

from numpy import min, max, median, mean, std


def wrapper(args):
    if not args['filepath'] or not os.path.isfile(args['filepath']):
        return
    results = []
    regex = (
        r"Target: (([0-9a-f]{2}:*){6}), " +
        r"status: ([0-9]), rtt: ([0-9\-]+) \(±([0-9\-]+)\) psec, " +
        r"distance: ([0-9\-]+) \(±([0-9\-]+)\) cm, rssi: ([0-9\-]+) dBm"
    )
    with open(args['filepath']) as f:
        for line in f:
            match = re.search(regex, line)
            if match:
                mac = match.group(1)
                status = int(match.group(3))
                rtt = int(match.group(4))
                rtt_var = int(match.group(5))
                raw_distance = int(match.group(6))
                raw_distance_var = int(match.group(7))
                rssi = int(match.group(8))
            else:
                continue
            if status is not 0 or raw_distance < -1000:
                continue
            results.append(raw_distance * args['cali'][0] + args['cali'][1])
    print('statics of results')
    print('* num of valid data: {0}'.format(len(results)))
    print('* min: {0:.2f}cm'.format(min(results)))
    print('* max: {0:.2f}cm'.format(max(results)))
    print('* mean: {0:.2f}cm'.format(mean(results)))
    print('* median: {0:.2f}cm'.format(median(results)))
    print('* std: {0:.2f}cm'.format(std(results)))


def main():
    p = argparse.ArgumentParser(description='iw parser')
    p.add_argument(
        'filepath',
        help="input file path for result"
    )
    p.add_argument(
        '--cali',
        nargs=2,
        default=(0.9234, 534.7103),
        type=float,
        help="calibrate final result"
    )
    try:
        args = vars(p.parse_args())
    except Exception as e:
        print(e)
        sys.exit()
    wrapper(args)



if __name__ == '__main__':
    main()
