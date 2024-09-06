#!/usr/bin/python3

from math import sqrt

def sqr(x):
    return x*x

d=32
max_val = 255
idx = 0

for y in range(d//2):
	for x in range(d//2):
		cx = d/2
		cy = d/2
		dist_sq = sqr(cx-x) + sqr(cy-y)
		dist = sqrt(dist_sq)

		val = max_val / (dist if dist >= 1 else 1)

		print('bs[%d] = 8\'h%02x;' % (idx, int(max(val-9,0))))
		idx += 1
