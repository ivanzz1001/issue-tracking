# perf工具的使用

#### Step0: install perf tool
```
apt-get install linux-tools-common linux-tools-$(uname -r) -y
```

#### Step1: 抓取内核热点(5秒采样)
```
# # -e cycles:k      只采样内核态 CPU 周期
# -g               记录调用栈
# -a               所有 CPU
# -o               输出文件
perf record -g -a -e cycles:k -o /tmp/perf.data -- sleep 5
```

#### Step2: 看报告
```
# --stdio          纯文本输出（不用 TUI）
# --no-children    不展开子函数调用（只看函数自身的开销）
perf report -i /tmp/perf.data --stdio --no-children | head -120
```

#### Step3: 展开相关函数调用栈
```
# 例如展开 _raw_spin_lock 的调用栈，不截断
perf report -i /tmp/perf.data --stdio --no-children 2>/dev/null | grep -A 50 "_raw_spin_lock"
```
