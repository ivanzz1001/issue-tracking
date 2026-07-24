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
