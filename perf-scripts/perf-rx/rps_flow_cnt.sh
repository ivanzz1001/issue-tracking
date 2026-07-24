# 设置全局流表大小（当前已是 131072，够用）
sysctl -w net.core.rps_sock_flow_entries=131072

# 为 bond1 分配流表（平分到 64 个队列: 131072 / 64 = 2048）
for f in /sys/class/net/bond1/queues/rx-*/rps_flow_cnt; do
    echo 2048 > "$f"
done
