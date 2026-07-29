# FNat模式相关参数优化


#### 一、**Conntrack 参数优化**

```bash
# 增大 hash 表减少碰撞
echo 524288 > /sys/module/nf_conntrack/parameters/hashsize

# 缩短 TCP 超时加速回收
ipvsadm --set 300 60 300
```

#### 二、 **调整 dev_weight / NAPI 参数**
```bash
# 当前 dev_weight=64（默认），增大 NAPI 每轮处理上限
sysctl -w net.core.dev_weight=256
```

