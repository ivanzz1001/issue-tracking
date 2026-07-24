#!/bin/bash
# rx-0  ~ rx-8:  CPU 0-27    (w0)
# rx-9  ~ rx-10: CPU 56-63   (w1)
# rx-11 ~ rx-15: CPU 64-83   (w2)

echo "00000000,00000000,00000000,00000007" > /sys/class/net/bond1/queues/rx-0/rps_cpus
echo "00000000,00000000,00000000,00000038" > /sys/class/net/bond1/queues/rx-1/rps_cpus
echo "00000000,00000000,00000000,000001c0" > /sys/class/net/bond1/queues/rx-2/rps_cpus
echo "00000000,00000000,00000000,00000e00" > /sys/class/net/bond1/queues/rx-3/rps_cpus
echo "00000000,00000000,00000000,00007000" > /sys/class/net/bond1/queues/rx-4/rps_cpus
echo "00000000,00000000,00000000,00038000" > /sys/class/net/bond1/queues/rx-5/rps_cpus
echo "00000000,00000000,00000000,001c0000" > /sys/class/net/bond1/queues/rx-6/rps_cpus
echo "00000000,00000000,00000000,00e00000" > /sys/class/net/bond1/queues/rx-7/rps_cpus
echo "00000000,00000000,00000000,0f000000" > /sys/class/net/bond1/queues/rx-8/rps_cpus
echo "00000000,00000000,0f000000,00000000" > /sys/class/net/bond1/queues/rx-9/rps_cpus
echo "00000000,00000000,f0000000,00000000" > /sys/class/net/bond1/queues/rx-10/rps_cpus
echo "00000000,0000000f,00000000,00000000" > /sys/class/net/bond1/queues/rx-11/rps_cpus
echo "00000000,000000f0,00000000,00000000" > /sys/class/net/bond1/queues/rx-12/rps_cpus
echo "00000000,00000f00,00000000,00000000" > /sys/class/net/bond1/queues/rx-13/rps_cpus
echo "00000000,0000f000,00000000,00000000" > /sys/class/net/bond1/queues/rx-14/rps_cpus
echo "00000000,000f0000,00000000,00000000" > /sys/class/net/bond1/queues/rx-15/rps_cpus

echo "done"
