#!/usr/bin/python
# -*- coding: utf-8 -*-


import re
import os
import time
import json
import argparse
from numpy import nanstd, nanmedian, sqrt
from libExtraction import separateMAC
from libLocalization import deriveLocation, get_distance


def get_known_locs(results, args):
    database = json.load(open(args['json'], 'r'))
    for mac in database.keys():
        if mac not in results:
            del database[mac]
    for mac in results.keys():
        if mac not in database:
            del results[mac]
    return database


def wrapper(args):
    if not os.path.isfile(args['filepath']):
        return
    results, nameLine, startLine, endLine = separateMAC(args['filepath'])
    args['config_entry'] = get_known_locs(results, args)
    # method 1: average and then compute single loc
    final_result = {}
    for mac in results:
        dists = []
        for line in results[mac]:
            try:
                # tmp = float(line.split(',')[4])
                # ugly hack
                # if mac == '34:f6:4b:5e:69:1f':
                #     tmp = tmp * 0.7927 + 483.3157  # med school fit for 1f
                # elif mac == '34:f6:4b:5e:69:0b':
                #     tmp = tmp * 0.6927 + 400.3157  # med school fit for 0b
                tmp = float(line.split(',')[1])  # already fitted result
                dists.append(tmp)
            except Exception as e:
                print(e)
        final_result[mac] = (nanmedian(dists), nanstd(dists))
    print('est:', final_result)
    loc = deriveLocation(args, final_result)
    print('loc:', loc)
    # # method 2: do localization first for every pair and then average
    # all_locs = {}
    # if results:
    #     keys = results.keys()
    #     idxs = [0] * len(keys)
    #     locs = []
    #     while all([idxs[i] < len(results[keys[i]]) for i in range(len(idxs))]):
    #         lines = [results[keys[i]][idxs[i]] for i in range(len(idxs))]
    #         times = [float(x.split(',')[7]) for x in lines]
    #         maxT = max(times)
    #         if all([abs(t - maxT) < 0.01 for t in times]):
    #             dists = [
    #                 (float(x.split(',')[1]), sqrt(float(x.split(',')[5])))
    #                 for x in lines
    #             ]
    #             loc = deriveLocation(args, dict(zip(keys, dists)))
    #             print('{0:.4f},{1:.4f}'.format(loc[0], loc[1]))
    #             locs.append(loc)
    #             for i in range(len(idxs)):
    #                 idxs[i] += 1
    #         else:
    #             for i in range(len(idxs)):
    #                 if abs(times[i] - maxT) > 0.01:
    #                     idxs[i] += 1
    #     x, y = zip(*locs)
    #     loc = (nanmedian(x), nanmedian(y))
    #     locstd = (nanstd(x), nanstd(y))
    #     print(loc)
    #     print(locstd)
    match = re.search(r"static_([0-9.]+)_([0-9.]+)_", args['filepath'])
    if match:
        trueX = float(match.group(1)) * 100
        trueY = float(match.group(2)) * 100
        true_result = {}
        for mac in args['config_entry']:
            mac_loc = args['config_entry'][mac]['location'].split(',')
            mac_loc = (float(mac_loc[0]), float(mac_loc[1]))
            true_result[mac] = (get_distance(mac_loc, (trueX, trueY)), 0)
        print('true:', true_result)
        err = get_distance(loc, (trueX, trueY))
        print('err:', err)


def main():
    p = argparse.ArgumentParser(description='separate data from MAC addr')
    p.add_argument(
        'filepath',
        help="file path"
    )
    p.add_argument(
        '--outfp', '-f',
        default=None,
        help="if set, will write raw fetched data to file"
    )
    p.add_argument(
        '--json', '-j',
        default='config_entry.default',
        help="load a config json file"
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
    # TODO: manually add bounds
    args['loc_bounds'] = {'y_min': 0}
    wrapper(args)


if __name__ == '__main__':
    main()
