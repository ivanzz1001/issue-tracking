#!/bin/bash
# ============================================================
# mlx5 中断亲和性再均衡脚本
#
# 将 bond1 所用两个 mlx5 端口的 comp IRQ 均匀绑定到 NUMA0 CPU
#   - eth20 (pci:4b:00.0): IRQ 981-1043 共 63 个
#   - eth21 (pci:4b:00.1): IRQ 1045-1107 共 63 个
#   每个 IRQ 绑定 2 个 NUMA0 CPU，轮询分配
# 
# 说明: 不同机器IRQ中断序号可能不一样 
# ============================================================

set -e

# NUMA node0 CPU 列表
NUMA0_CPUS=(
     0  1  2  3  4  5  6  7  8  9
    10 11 12 13 14 15 16 17 18 19
    20 21 22 23 24 25 26 27
    56 57 58 59 60 61 62 63 64 65
    66 67 68 69 70 71 72 73 74 75
    76 77 78 79 80 81 82 83
)
NUMA0_COUNT=${#NUMA0_CPUS[@]}

# eth20 port0 comp IRQ 范围
# ethtool -i eth0 | grep bus-info                                                              //查询网卡PCIe地址
# grep mlx5_comp /proc/interrupts | grep '4b:00.0' | awk '{print $1}'                          //获取中断序号
#
# // 也可以通过如下的命令来直接获取
# grep "mlx5_comp.*0000:4b:00.0" /proc/interrupts | awk -F: '{print $1}' | sort -n | head -1     # 起始
# grep "mlx5_comp.*0000:4b:00.0" /proc/interrupts | awk -F: '{print $1}' | sort -n | tail -1     # 结束
PORT0_FIRST=981
PORT0_LAST=1043

# eth21 port1 comp IRQ 范围
PORT1_FIRST=1045
PORT1_LAST=1107

echo "=========================================="
echo " mlx5 IRQ 亲和性再均衡"
echo " NUMA0 CPUs: ${NUMA0_COUNT} 核 (${NUMA0_CPUS[0]}-${NUMA0_CPUS[27]}, ${NUMA0_CPUS[28]}-${NUMA0_CPUS[55]})"
echo " eth20 (port0): IRQ ${PORT0_FIRST}-${PORT0_LAST}"
echo " eth21 (port1): IRQ ${PORT1_FIRST}-${PORT1_LAST}"
echo " 策略: 每 IRQ 绑 2 个 CPU，轮询分配"
echo "=========================================="
echo ""

bind_irq() {
    local irq=$1
    local cpu_idx=$2
    local port_name=$3
    local comp_name=$4

    local cpu1_idx=$(( cpu_idx % NUMA0_COUNT ))
    local cpu2_idx=$(( (cpu_idx + 1) % NUMA0_COUNT ))
    local cpu1=${NUMA0_CPUS[$cpu1_idx]}
    local cpu2=${NUMA0_CPUS[$cpu2_idx]}

    echo "${cpu1},${cpu2}" > "/proc/irq/${irq}/smp_affinity_list" 2>/dev/null

    printf "%-6s %-10s IRQ %-5s -> CPU %-3s,%-3s\n" \
        "$port_name" "$comp_name" "$irq" "$cpu1" "$cpu2"
}

echo "=== eth20 (pci:0000:4b:00.0) ==="
irq_idx=0
for irq in $(seq $PORT0_FIRST $PORT0_LAST); do
    comp="comp$(( irq - PORT0_FIRST ))"
    bind_irq "$irq" "$irq_idx" "port0" "$comp"
    irq_idx=$(( irq_idx + 2 ))
done

echo ""
echo "=== eth21 (pci:0000:4b:00.1) ==="
# port1 从中间偏移开始，避免和 port0 完全重叠
# port0 用掉了 63*2=126 个 slot，port1 从 slot 28 开始（错开 14 组 CPU pair）
irq_idx=28
for irq in $(seq $PORT1_FIRST $PORT1_LAST); do
    comp="comp$(( irq - PORT1_FIRST ))"
    bind_irq "$irq" "$irq_idx" "port1" "$comp"
    irq_idx=$(( irq_idx + 2 ))
done

echo ""
echo "=== 验证前 10 个 IRQ 亲和性 ==="
for irq in 981 982 983 984 985 1045 1046 1047 1048 1049; do
    name=$(grep -o "mlx5_comp[0-9]*@pci.*" /proc/interrupts 2>/dev/null | grep "^\s*${irq}:" | head -1 || echo "IRQ $irq")
    aff=$(cat /proc/irq/${irq}/smp_affinity_list 2>/dev/null || echo "N/A")
    echo "  IRQ $irq : CPUs [$aff]"
done

echo ""
echo "Done."
