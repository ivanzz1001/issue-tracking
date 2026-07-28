#!/bin/bash

# eth20 → 绑 CPU 0-27（NUMA0 前半）
idx=0
for irq in $(grep "mlx5_comp.*4b:00.0" /proc/interrupts | awk '{print $1}' | tr -d ':'); do
    cpu=$(( (idx * 2) % 28 ))
    cpu2=$(( cpu + 1 ))
    echo "$cpu-$cpu2" > /proc/irq/$irq/smp_affinity_list
    idx=$((idx + 1))
done

# eth21 → 绑 CPU 56-83（NUMA0 后半，与 eth20 零重叠）
idx=0
for irq in $(grep "mlx5_comp.*4b:00.1" /proc/interrupts | awk '{print $1}' | tr -d ':'); do
    cpu=$(( 56 + (idx * 2) % 28 ))
    cpu2=$(( cpu + 1 ))
    echo "$cpu-$cpu2" > /proc/irq/$irq/smp_affinity_list
    idx=$((idx + 1))
done
