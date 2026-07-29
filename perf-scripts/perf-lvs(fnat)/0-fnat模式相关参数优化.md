# FNat模式相关参数优化


1) **Conntrack 参数优化**

```bash
# 增大 hash 表减少碰撞
echo 524288 > /sys/module/nf_conntrack/parameters/hashsize

# 缩短 TCP 超时加速回收
ipvsadm --set 300 60 300
```

2) **调整 dev_weight / NAPI 参数**



3) 
