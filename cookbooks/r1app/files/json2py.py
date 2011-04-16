#!/usr/bin/env python

import sys

try:
    import simplejson as json
except ImportError:
    import json

def main(args):
    if len(args) >= 1:
        input = open(args[0])
    else:
        input = sys.stdin

    
    data = json.load(input)
    text = repr(data)

    if len(args) >= 2:
        output = open(args[1],'w')
        try:
            output.write(text)
        finally:
            output.close()
    else:
        print text

if __name__ == '__main__':
    main(sys.argv[1:])
    sys.exit(0)
