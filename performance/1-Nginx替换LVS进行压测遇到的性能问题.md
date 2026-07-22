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


