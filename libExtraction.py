#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import time
import argparse


def separateMAC(fp):
    results = {}
    nameLine = None
    startLine = None
    endLine = None
    with open(fp, 'r') as f:
        for line in f:
            if nameLine is None:
                nameLine = line
                continue
            if 'ff:ff:ff:ff:ff:ff' in line:
                if startLine is None:
                    startLine = line
                elif endLine is None:
                    endLine = line
                continue
            mac = line.split(',')[0]
            if mac not in results:
                print('* Find MAC: {0}'.format(mac))
                results[mac] = []
            results[mac].append(line)
    return results, nameLine, startLine, endLine


def extract_each(fp):
    results, nameLine, startLine, endLine = separateMAC(fp)
    base, ext = os.path.splitext(fp)
    base = '_'.join(base.split('_')[:-1])  # remove time stamp
    t = int(time.time())
    for mac in results:
        with open(
            '{0}_{1}{2}'
            .format(base, t, ext), 'w'
        ) as f:
            f.write(nameLine)
            if startLine:
                f.write(startLine)
            for line in results[mac]:
                f.write(line)
            if endLine:
                f.write(endLine)


def wrapper(args):
    if not os.path.isfile(args['filepath']):
        return
    extract_each(args['filepath'])


def main():
    p = argparse.ArgumentParser(description='separate data from MAC addr')
    p.add_argument(
        'filepath',
        help="file path"
    )
    p.add_argument(
        '--verbose', '-v',
        default=False,
        action="store_true",
        help="if set, show detailed messages"
    )
    try:
        args = vars(p.parse_args())
    except Exception as e:
        print(str(e))
        sys.exit()
    args['time_of_exec'] = int(time.time())
    wrapper(args)


if __name__ == '__main__':
    main()
