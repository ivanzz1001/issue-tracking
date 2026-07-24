#!/bin/bash
# RPS: bond1 64 Rx 队列绑定到 NUMA node0 CPU

BOND="bond1"

NUMA0_CPUS=(
     0  1  2  3  4  5  6  7  8  9
    10 11 12 13 14 15 16 17 18 19
    20 21 22 23 24 25 26 27
    56 57 58 59 60 61 62 63 64 65
    66 67 68 69 70 71 72 73 74 75
    76 77 78 79 80 81 82 83
)

mask_for_cpu() {
    local cpu=$1
    local g0="00000000" g1="00000000" g2="00000000" g3="00000000"
    if   [ "$cpu" -le 31 ]; then g3=$(printf "%08x" $(( 1 << cpu )))
    elif [ "$cpu" -le 63 ]; then g2=$(printf "%08x" $(( 1 << (cpu - 32) )))
    elif [ "$cpu" -le 95 ]; then g1=$(printf "%08x" $(( 1 << (cpu - 64) )))
    else g0=$(printf "%08x" $(( 1 << (cpu - 96) )))
    fi
    echo "${g0},${g1},${g2},${g3}"
}

for i in $(seq 0 63); do
    cpu=${NUMA0_CPUS[$(( i % 56 ))]}
    mask=$(mask_for_cpu $cpu)
    echo "$mask" > "/sys/class/net/${BOND}/queues/rx-${i}/rps_cpus"
    printf "rx-%-3d -> CPU %-3d   mask: %s\n" "$i" "$cpu" "$mask"
done

echo "RPS done."
