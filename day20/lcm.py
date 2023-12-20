#!/usr/bin/env python
# Trying to reproduce my one-character typo on day 20.

import math

nums = [*"3739 3797 3919 4003"]

def strlcm(s):
    return math.lcm(*[int(x) for x in s.split(' ')])


for i, c in enumerate(nums):
    if c >= '0' and c <= '9':
        for n in range(0, 10):
            copy = [*nums]
            copy[i] = str(n)
            if strlcm(''.join(copy)) == 222377836299437:
                print(''.join(copy))
