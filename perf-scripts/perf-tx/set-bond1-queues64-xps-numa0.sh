#!/bin/bash
# ============================================================
# bond1 64 Tx 队列 XPS 绑定到 NUMA node0 CPU
# 
# NUMA0 CPUs: 0-27, 56-83 (共 56 核)
# 策略: 轮询分配，每个队列绑定 1 个 CPU
#   queue_i -> NUMA0_CPU[i % 56]
#
# XPS mask 格式（112 位 = 系统 112 核，组顺序与 CPU 范围相反）:
#   G0(16bit,CPU 96-111):XXXX,G1(32bit,CPU 64-95):XXXXXXXX,
#   G2(32bit,CPU 32-63):XXXXXXXX,G3(32bit,CPU 0-31):XXXXXXXX
# ============================================================

set -e

BOND="bond1"
TX_QUEUES=64

# NUMA node0 CPU 列表（按顺序）
NUMA0_CPUS=(
     0  1  2  3  4  5  6  7  8  9
    10 11 12 13 14 15 16 17 18 19
    20 21 22 23 24 25 26 27
    56 57 58 59 60 61 62 63 64 65
    66 67 68 69 70 71 72 73 74 75
    76 77 78 79 80 81 82 83
)
NUMA0_COUNT=${#NUMA0_CPUS[@]}

echo layer3+4 > /sys/class/net/bond1/bonding/xmit_hash_policy

echo "NUMA node0 CPUs: ${NUMA0_CPUS[*]}"
echo "Total NUMA0 CPUs: $NUMA0_COUNT"
echo "bond1 Tx queues: $TX_QUEUES"
echo "Mapping: queue_i -> NUMA0_CPU[i % $NUMA0_COUNT]"
echo ""

# 生成 XPS cpumask
# G0(16bit,CPU 96-111) | G1(32bit,CPU 64-95) | G2(32bit,CPU 32-63) | G3(32bit,CPU 0-31)
mask_for_cpu() {
    local cpu=$1
    local g0="00000000"
    local g1="00000000"
    local g2="00000000"
    local g3="00000000"

    if   [ "$cpu" -le 31 ]; then
        g3=$(printf "%08x" $(( 1 << cpu )))
    elif [ "$cpu" -le 63 ]; then
        g2=$(printf "%08x" $(( 1 << (cpu - 32) )))
    elif [ "$cpu" -le 95 ]; then
        g1=$(printf "%08x" $(( 1 << (cpu - 64) )))
    else
        g0=$(printf "%08x" $(( 1 << (cpu - 96) )))
    fi

    echo "${g0},${g1},${g2},${g3}"
}

# 先清空所有 XPS
for q in /sys/class/net/${BOND}/queues/tx-*/xps_cpus; do
    echo 0 > "$q" 2>/dev/null
done

# 绑定
for i in $(seq 0 $((TX_QUEUES - 1))); do
    cpu_idx=$(( i % NUMA0_COUNT ))
    cpu=${NUMA0_CPUS[$cpu_idx]}
    mask=$(mask_for_cpu $cpu)

    echo "$mask" > "/sys/class/net/${BOND}/queues/tx-${i}/xps_cpus"

    printf "tx-%-3d -> CPU %-3d   mask: %s\n" "$i" "$cpu" "$mask"
done

echo ""
echo "=== 绑定完成 ==="
