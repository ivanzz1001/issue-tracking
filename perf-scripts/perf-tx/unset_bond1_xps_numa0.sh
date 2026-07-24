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

echo layer3+4 > /sys/class/net/bond1/bonding/xmit_hash_policy


# 先清空所有 XPS
for q in /sys/class/net/${BOND}/queues/tx-*/xps_cpus; do
    # echo 0 > "$q" 2>/dev/null
    echo "$q"
done


echo ""
echo "=== 解除绑定完成 ==="
