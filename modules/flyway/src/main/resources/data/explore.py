#!/usr/bin/python

import sys
import csv


if __name__ == "__main__":
    field=sys.argv[2]
    with open(sys.argv[1], 'rb') as csvfile:
        reader = csv.DictReader(csvfile, delimiter=',', quotechar='"')
        for row in reader:
            print(row[field])
