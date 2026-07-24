#!/bin/bash

# 先 down 掉 bond 并从 bond 中移除子接口
ip link set bond1 down
echo '-eth20' > /sys/class/net/bond1/bonding/slaves
echo '-eth21' > /sys/class/net/bond1/bonding/slaves
ip link delete bond1

# 重新加载模块
modprobe -r bonding && modprobe bonding

# 重新创建 bond1
ip link add bond1 type bond mode 802.3ad xmit_hash_policy layer3+4
echo '+eth20' > /sys/class/net/bond1/bonding/slaves
echo '+eth21' > /sys/class/net/bond1/bonding/slaves
ip addr add 172.31.16.99/26 dev bond1
ip addr add 172.31.16.120/26 dev bond1
ip link set bond1 up
