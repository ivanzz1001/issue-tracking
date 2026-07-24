# 1. MTU 变了吗？
cat /sys/class/net/bond1/mtu

# 2. 硬件 offload 还开着吗？
ethtool -k bond1 2>/dev/null | grep -E "receive-offload|segmentation|checksum"

# 3. NIC coalesce 参数
ethtool -c eth20 | head -10

# 4. 平均包大小（pps vs bps）
sar -n DEV 1 1 2>/dev/null | grep bond1 | tail -1

# 5. ring buffer 大小
ethtool -g eth20 | tail -5

# 6. 各 CPU 的 softirq 分布（应该从 5 个核的 40% 变成 20+ 个核的 10-15%）
mpstat -P ALL 1 5

# 7. NIC 丢包是否下降（rx_discards_phy 增量应明显减少）
watch -n 5 'ethtool -S eth20 | grep "rx_discards_phy\|rx_out_of_buffer\|rx_cache_full"'

# 8. bond1 吞吐是否提升
sar -n DEV 1 10 | grep bond1
