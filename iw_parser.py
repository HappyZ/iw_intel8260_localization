#!/usr/bin/python


import os
import argparse

from numpy import min, max, median, mean, std


def wrapper(args):
    if not args['filepath'] or not os.path.isfile(args['filepath']):
        return
    results = []
    with open(args['filepath']) as f:
        for line in f:
            tmp = line.rstrip().split(', ')
            status = int(tmp[1].split(' ')[1])
            if status is not 0:
                continue
            psec = int(tmp[2].split(' ')[1])
            distance = int(tmp[3].split(' ')[1])
            if distance < -1000:
                continue
            results.append(distance * args['cali'][0] + args['cali'][1])
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
