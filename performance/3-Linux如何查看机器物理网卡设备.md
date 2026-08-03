# Linux如何查看机器物理网卡设备


如果你想查看 Linux 机器上实际存在的物理网卡设备，建议从几个层次看.

## 1. 最直接：查看网卡及 PCI 地址

```bash
# lspci | grep -i -E 'ethernet|network'
31:00.0 Ethernet controller: Intel Corporation Ethernet Controller X710 for 10GbE SFP+ (rev 02)
31:00.1 Ethernet controller: Intel Corporation Ethernet Controller X710 for 10GbE SFP+ (rev 02)
4b:00.0 Ethernet controller: Mellanox Technologies MT28908 Family [ConnectX-6]
4b:00.1 Ethernet controller: Mellanox Technologies MT28908 Family [ConnectX-6]
```

上面`31:00.0`、`31:00.1`、`4b:00.0`、`4b:00.1`就是PCIe设备地址。

> ps: 上面命令可能并不能保证列出所有物理网卡

## 2. 查看 Linux 网卡设备

```bash
# ip -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
enp49s0f0        DOWN           ac:ce:92:fd:8c:bc <BROADCAST,MULTICAST> 
enp49s0f1        DOWN           ac:ce:92:fd:8c:be <BROADCAST,MULTICAST> 
eth20            UP             a0:88:c2:58:bd:55 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
ibp177s0f0       DOWN           00:00:00:72:fe:80:00:00:00:00:00:00:a0:88:c2:03:00:58:bc:bc <BROADCAST,MULTICAST> 
ibp177s0f1       DOWN           00:00:01:cf:fe:80:00:00:00:00:00:00:a0:88:c2:03:00:58:bc:bd <BROADCAST,MULTICAST> 
bond1            UP             a0:88:c2:58:bd:55 <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> 
eth21            UP             a0:88:c2:58:bd:55 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
```
上面命令可以看到所有网卡设备，但是有一些可能是虚拟设备，不是物理网卡。

我们也可以通过如下的方式来查看:
```bash
# ls -l /sys/class/net/
total 0
lrwxrwxrwx 1 root root    0 Jul 27 00:31 bond1 -> ../../devices/virtual/net/bond1
-rw-r--r-- 1 root root 4096 Jul 27 12:02 bonding_masters
lrwxrwxrwx 1 root root    0 Feb  9 18:27 enp49s0f0 -> ../../devices/pci0000:30/0000:30:02.0/0000:31:00.0/net/enp49s0f0
lrwxrwxrwx 1 root root    0 Feb  9 18:27 enp49s0f1 -> ../../devices/pci0000:30/0000:30:02.0/0000:31:00.1/net/enp49s0f1
lrwxrwxrwx 1 root root    0 Feb  9 18:27 eth20 -> ../../devices/pci0000:4a/0000:4a:02.0/0000:4b:00.0/net/eth20
lrwxrwxrwx 1 root root    0 Jul 28 10:13 eth21 -> ../../devices/pci0000:4a/0000:4a:02.0/0000:4b:00.1/net/eth21
lrwxrwxrwx 1 root root    0 Feb  9 18:27 ibp177s0f0 -> ../../devices/pci0000:b0/0000:b0:02.0/0000:b1:00.0/net/ibp177s0f0
lrwxrwxrwx 1 root root    0 Feb  9 18:27 ibp177s0f1 -> ../../devices/pci0000:b0/0000:b0:02.0/0000:b1:00.1/net/ibp177s0f1
lrwxrwxrwx 1 root root    0 Apr 23 14:20 lo -> ../../devices/virtual/net/lo
```

## 3. 判断某个网卡是不是物理 PCIe 网卡

使用如下命令:
```bash
# readlink -f /sys/class/net/eth20/device
```

- 如果返回值类似于`/sys/devices/pci0000:40/0000:40:00.0/0000:4b:00.0`，则说明 eth20 对应的是 PCIe 物理设备

- 如果返回值类似于`/sys/devices/virtual/net/bond1`，则说明它是虚拟网络设备

## 4. 一次性列出所有物理 PCI 网卡及对应接口

```bash
for i in /sys/class/net/*; do
    dev=$(basename "$i")
    if [ -e "$i/device" ]; then
        echo "$dev -> $(readlink -f "$i/device")"
    fi
done
```
例如:
```text
eth20 -> /sys/devices/pci0000:40/0000:40:00.0/0000:4b:00.0
eth21 -> /sys/devices/pci0000:40/0000:40:00.1/0000:4b:00.1
```
这比单独看`ip link`更有用

## 5. 查看网卡驱动

```bash
# ethtool -i eth20
driver: mlx5_core
version: 25.10-1.7.1
firmware-version: 20.39.3004 (MT_0000000224)
expansion-rom-version: 
bus-info: 0000:4b:00.0
supports-statistics: yes
supports-test: yes
supports-eeprom-access: no
supports-register-dump: no
supports-priv-flags: yes
```

上面的`bus-info: 0000:4b:00.0`可以和`lspci -s 4b:00.0`对应起来。

## 6. 查看物理网卡对应的 NUMA Node

可以使用如下的命令:
```bash
# cat /sys/class/net/eth20/device/numa_node
# cat /sys/class/net/eth21/device/numa_node
```

也可以使用:
```bash
# lspci -vv -s 4b:00.0 | grep -i numa
```

## 7. 查看完整 PCIe 拓扑

```bash
# lspci -tv
```


