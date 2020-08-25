#!/bin/env python
# cheng_fa_biao.py

from __future__ import print_function

for x in range(1, 10):
    for y in range(1, x + 1):
        print(x, "x", y, end='  ')
    print()
