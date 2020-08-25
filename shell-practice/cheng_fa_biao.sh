#!/bin/bash
# cheng_fa_biao.sh

for x in {1..9}; do
    for y in $(seq 1 $x); do
        #echo -n "$x x $y = $((x*y)) "
        echo -n "$x x $y  "
    done
    echo
done
