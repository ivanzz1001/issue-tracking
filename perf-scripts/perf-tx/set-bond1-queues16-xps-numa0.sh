#!/bin/bash
# Step 1: 恢复均匀 hash
echo layer3+4 > /sys/class/net/bond1/bonding/xmit_hash_policy

# Step 2: XPS 绑定（先清空）
for q in /sys/class/net/bond1/queues/tx-*/xps_cpus; do echo 0 > "$q"; done

# tx-0  ~ tx-8:  CPU 0-27    (w0)
# tx-9  ~ tx-10: CPU 56-63   (w1)
# tx-11 ~ tx-15: CPU 64-83   (w2)

echo "00000000,00000000,00000000,00000007" > /sys/class/net/bond1/queues/tx-0/xps_cpus
echo "00000000,00000000,00000000,00000038" > /sys/class/net/bond1/queues/tx-1/xps_cpus
echo "00000000,00000000,00000000,000001c0" > /sys/class/net/bond1/queues/tx-2/xps_cpus
echo "00000000,00000000,00000000,00000e00" > /sys/class/net/bond1/queues/tx-3/xps_cpus
echo "00000000,00000000,00000000,00007000" > /sys/class/net/bond1/queues/tx-4/xps_cpus
echo "00000000,00000000,00000000,00038000" > /sys/class/net/bond1/queues/tx-5/xps_cpus
echo "00000000,00000000,00000000,001c0000" > /sys/class/net/bond1/queues/tx-6/xps_cpus
echo "00000000,00000000,00000000,00e00000" > /sys/class/net/bond1/queues/tx-7/xps_cpus
echo "00000000,00000000,00000000,0f000000" > /sys/class/net/bond1/queues/tx-8/xps_cpus
echo "00000000,00000000,0f000000,00000000" > /sys/class/net/bond1/queues/tx-9/xps_cpus
echo "00000000,00000000,f0000000,00000000" > /sys/class/net/bond1/queues/tx-10/xps_cpus
echo "00000000,0000000f,00000000,00000000" > /sys/class/net/bond1/queues/tx-11/xps_cpus
echo "00000000,000000f0,00000000,00000000" > /sys/class/net/bond1/queues/tx-12/xps_cpus
echo "00000000,00000f00,00000000,00000000" > /sys/class/net/bond1/queues/tx-13/xps_cpus
echo "00000000,0000f000,00000000,00000000" > /sys/class/net/bond1/queues/tx-14/xps_cpus
echo "00000000,000f0000,00000000,00000000" > /sys/class/net/bond1/queues/tx-15/xps_cpus

echo "done"
