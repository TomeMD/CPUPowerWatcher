#!/usr/bin/env python3

import random, sys

def generate_uniform(n, min, max, split_point, p_low):
    for _ in range(n):
        v = random.randint(min, split_point) if random.random() < p_low else random.randint(split_point, max)
        print(v)

if __name__ == '__main__':
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <n> <min> <max> [<split_point> <p_low>]")
        sys.exit(1)

    n, min, max = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]) # number of samples, minimum and maximum
    split_point = int(sys.argv[4]) if len(sys.argv) >= 6 else min # point to split distribution in two ranges
    p_low = float(sys.argv[5]) if len(sys.argv) >= 6 else -1 # probability of the low range

    if not min <= split_point <= max:
        print(f"Split point not valid ({split_point}). It must be between min ({min}) and max ({max})")

    generate_uniform(n, min, max, split_point, p_low)