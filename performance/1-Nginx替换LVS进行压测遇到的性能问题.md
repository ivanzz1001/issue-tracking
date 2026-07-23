# 记录Nginx替换LVS进行压测遇到的性能问题

背景：在Nginx替换LVS时需要对两者的转发性能做一次压力测试，使用wrk进行`4M`文件的上传，发现两者的流量均只能打到约16GB，打不满200Gb的网卡。性能测试部署架构如下
```txt
┌──────────┐            ┌──────────┐              ┌──────────┐
│ Client A ├───────────→│          ├─────────────→│ Backend 1│
│ .16.98   │            │   LVS    │              │  .16.95  │
└──────────┘            │  FNAT    ├─────────────→│ Backend 2│
                        │ .16.99   │              │  .16.96  │
┌──────────┐            │          ├─────────────→│ Backend 3│
│ Client B ├───────────→│          │              │  .16.97  │
│ .16.82   │            └──────────┘              └──────────┘
└──────────┘
```
所有节点的基本信息如下:

- CPU信息
```bash
# lscpu
Architecture:                x86_64
  CPU op-mode(s):            32-bit, 64-bit
  Address sizes:             46 bits physical, 57 bits virtual
  Byte Order:                Little Endian
CPU(s):                      112
  On-line CPU(s) list:       0-111
Vendor ID:                   GenuineIntel
  Model name:                Intel(R) Xeon(R) Gold 6348 CPU @ 2.60GHz
    CPU family:              6
    Model:                   106
    Thread(s) per core:      2
    Core(s) per socket:      28
    Socket(s):               2
    Stepping:                6
    CPU max MHz:             3500.0000
    CPU min MHz:             800.0000
    BogoMIPS:                5200.00
    Flags:                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc
                              cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fau
                             lt epb cat_l3 invpcid_single intel_ppin ssbd mba ibrs ibpb stibp ibrs_enhanced tpr_shadow vnmi flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a avx512f avx512dq rdseed adx smap avx
                             512ifma clflushopt clwb intel_pt avx512cd sha_ni avx512bw avx512vl xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local split_lock_detect wbnoinvd dtherm ida arat pln pts hwp hwp_act_window hwp_e
                             pp hwp_pkg_req avx512vbmi umip pku ospke avx512_vbmi2 gfni vaes vpclmulqdq avx512_vnni avx512_bitalg tme avx512_vpopcntdq la57 rdpid fsrm md_clear pconfig flush_l1d arch_capabilities
Virtualization features:     
  Virtualization:            VT-x
Caches (sum of all):         
  L1d:                       2.6 MiB (56 instances)
  L1i:                       1.8 MiB (56 instances)
  L2:                        70 MiB (56 instances)
  L3:                        84 MiB (2 instances)
NUMA:                        
  NUMA node(s):              2
  NUMA node0 CPU(s):         0-27,56-83
  NUMA node1 CPU(s):         28-55,84-111
```

- 网卡信息
```bash
#  ethtool bond1
Settings for bond1:
        Supported ports: [  ]
        Supported link modes:   Not reported
        Supported pause frame use: No
        Supports auto-negotiation: No
        Supported FEC modes: Not reported
        Advertised link modes:  Not reported
        Advertised pause frame use: No
        Advertised auto-negotiation: No
        Advertised FEC modes: Not reported
        Speed: 200000Mb/s
        Duplex: Full
        Auto-negotiation: off
        Port: Other
        PHYAD: 0
        Transceiver: internal
        Link detected: yes
# ethtool -l eth20
Channel parameters for eth20:
Pre-set maximums:
RX:             n/a
TX:             n/a
Other:          n/a
Combined:       63
Current hardware settings:
RX:             n/a
TX:             n/a
Other:          n/a
Combined:       63
# ethtool -l eth21
Channel parameters for eth21:
Pre-set maximums:
RX:             n/a
TX:             n/a
Other:          n/a
Combined:       63
Current hardware settings:
RX:             n/a
TX:             n/a
Other:          n/a
Combined:       63
```
网卡`eth20`和`eth21`做bond。

## 1. 使用perf分析当前性能瓶颈

1) **安装perf**
```bash
apt-get install linux-tools-common linux-tools-$(uname -r) -y
```

2) **抓取内核热点**(5秒采样)

```bash
# # -e cycles:k      只采样内核态 CPU 周期
# -g               记录调用栈
# -a               所有 CPU
# -o               输出文件
perf record -g -a -e cycles:k -o /tmp/perf.data -- sleep 5
```
压测跑着的时候执行，抓 5 秒就够

3) **看报告**

```bash
# --stdio          纯文本输出（不用 TUI）
# --no-children    不展开子函数调用（只看函数自身的开销）
perf report -i /tmp/perf.data --stdio --no-children | head -120
```
输出的前三就是:

```txt
Overhead  Symbol
────────────────────────────────────
16.88%   mwait_idle_with_hints      ← CPU 空闲时间
 7.83%   mlx5e_skb_from_cqe_mpwrq   ← 网卡 RX 收包
 3.50%   _raw_spin_lock             ← 🔴 锁竞争！
```

4) **展开 _raw_spin_lock 看谁在抢锁**
```bash
# 只展开 _raw_spin_lock 的调用栈，不截断
perf report -i /tmp/perf.data --stdio --no-children 2>/dev/null | grep -A 50 "_raw_spin_lock"
```
就会看到关键路径:

```txt
_raw_spin_lock
  → __dev_xmit_skb              ← TX 队列锁
    → bond_dev_queue_xmit       ← bond 驱动
      → __bond_start_xmit
        → bond_start_xmit
          → ...
            → ip_vs_nat_send_or_cont   ← IPVS NAT 发包路径
              → ip_vs_nat_xmit
                → ip_vs_in
```
这一行就说明了一切：每个 IPVS 转发的包，发出去时都要抢 TX 队列锁

## 2. 原因分析

结合上面perf分析，这就完美解释你所看到的所有现象:

|         现象     |                       解释                  |
|:-----------------|:-------------------------------------------|
|CPU 30-50%，没跑满 | CPU 的时间在 spin 等待锁，不是在算东西          |
|加客户端反而吞吐下降 | 更多 CPU 抢同一把锁 → 竞争更激烈 → 有效吞吐反而降 |
|RPS 没用          | 锁在 TX 路径上，RX 怎么分都没用                 |

这就是经典的 TX 队列锁竞争瓶颈。56 个 CPU 同时在往 bond1 的 TX 队列里塞包，每塞一个包都要先拿下队列的 spin_lock。CPU 越多，抢锁越激烈，“大家都在等，没人真干活”

### 2.1 RPS与XPS

1) **RPS（Receive Packet Steering）**

  - 全称：Receive Packet Steering（接收数据包导向）
  - 主要作用：当网卡收到数据包时，它会触发中断。如果网卡只支持单队列，或者硬件队列数少于服务器的 CPU 核心数，所有的网络中断处理就会堆积在少数几个 CPU 上造成瓶颈。
  - 工作原理：RPS 是在软件层面实现的将接收到的数据包分发给不同的 CPU 处理的技术。它通过计算数据包的哈希值（如 IP 和端口），把包转发给不同的 CPU，从而实现负载均衡

2) **XPS（Transmit Packet Steering）**
  
  - 全称：Transmit Packet Steering（发送数据包导向）
  - 主要作用：它是针对发送数据包的队列选择优化。对于多队列网卡，系统在发送数据时可能会随机选择队列，导致跨 CPU 竞争发送锁，从而降低性能。
  - 工作原理：XPS 允许用户建立 CPU 与网卡发送队列（TX Queue）之间的映射关系。当某个 CPU 需要发送数据时，内核会自动选择与该 CPU 关联的发送队列，避免多核竞争并最大化缓存命中率


## 3. 对症优化

1) **改 bond xmit_hash_policy 为 layer2+3**

```bash
echo layer2+3 > /sys/class/net/bond1/bonding/xmit_hash_policy
```
`layer3+4` 把 src_ip + src_port + dst_ip + dst_port 都哈希，变化太少时容易聚到少数 slave。layer2+3 加入 MAC 地址，分布更均匀。

按上面的方法修改之后，发现当前网卡可以打到17.5GB:

![hash-policy](https://raw.githubusercontent.com/ivanzz1001/issue-tracking/master/performance/image/bond-traffic-1.jpg)

我们看到采用此方法虽然bond整体流量已经到了`17.5GB`了，但是出现了严重的流量倾斜，其中`eth21`网卡流量几乎要打满，而`eth20`网卡流量过少。

2) **限制 XPS，让每个 CPU 只用自己的 TX 队列（减少锁竞争）**

```bash
# ls /sys/class/net/bond1/queues/       //可以看到有16个发送队列,实际上两个物理网卡是有64个发送队列(说明网卡bond应该也有问题)
rx-0  rx-1  rx-10  rx-11  rx-12  rx-13  rx-14  rx-15  rx-2  rx-3  rx-4  rx-5  rx-6  rx-7  rx-8  rx-9  tx-0  tx-1  tx-10  tx-11  tx-12  tx-13  tx-14  tx-15  tx-2  tx-3  tx-4  tx-5  tx-6  tx-7  tx-8  tx-9
```
使用如下的脚本将这16个发送队列分别绑定到NUMA0对应的CPU上:

```bash
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
```
做上述操作之后重新压测，可以看到200Gb的网卡也可以打到17.5GB:

![xps-bind-cpu](https://raw.githubusercontent.com/ivanzz1001/issue-tracking/master/performance/image/bond-traffic-2.jpg)

我们看到采用此方法虽然bond整体流量已经到了`17.5GB`了，并且两个网卡的流量基本就一致了。目前两个网卡没有打满，猜测的原因可能是发送队列过少.


3) **拆掉 bond，用 ECMP 双 IP**

```txt
eth20: 172.31.16.99  (VIP1)
eth21: 172.31.16.120 (VIP2)
```
上游交换机 ECMP 把流量分到两个 IP，两个 NIC 独立，各自有自己的 TX 队列锁，锁竞争直接减半。



## 总结与应用

在实际的高并发、高网络吞吐量（如 10Gbps 及以上）服务器运维中，管理员通常会配合使用这两项技术，外加 RSS（硬件级的接收端扩展，Hardware RSS）和 RFS（应用感知的流量导向），以达到最佳的网络性能。

如果您正在进行网络调优，最佳实践是做到 一一对应（即将特定网卡中断、RSS接收队列、XPS发送队列以及处理对应网络任务的应用线程全部绑定在同一个物理 CPU 核心以及相同的 NUMA 节点上），以大幅降低跨核通信损耗。

想要了解具体的 Linux 系统配置方法，可以参考以下技术文档进行实操：

- 深入理解多队列网卡调优原理可查看[博客园的 Linux RSS/RPS/RFS/XPS对比](https://www.cnblogs.com/scottieyuyang/p/5665731.html)

- 了解如何通过软件配置将发送队列与 CPU 绑定的详细步骤，请阅读 [ChinaUnix RPS/RFS/RSS/XPS指南](http://m.blog.chinaunix.net/uid-1728743-id-5204900.html)

