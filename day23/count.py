#!/usr/bin/env python3

import fileinput

total = 0
for line in fileinput.input():
    num = 0
    for char in line.strip():
        if char != '#':
            num += 1
    print(num)
    total += num
print(total)
