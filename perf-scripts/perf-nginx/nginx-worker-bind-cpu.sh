#!/bin/bash
# 绑定Nginx worker进程到指定的CPU核心

# 获取所有worker进程PID
worker_pids=$(ps -ef | grep "nginx: worker process" | grep -v grep| awk '{print $2}' | sort -n)
# 或者使用 pgrep
# worker_pids=$(pgrep -f "nginx: worker" | sort -n)

# 检查是否获取到
if [ -z "$worker_pids" ]; then
    echo "No nginx worker processes found."
    exit 1
fi

# 将PID列表转为数组
pids=($worker_pids)
num_workers=${#pids[@]}
echo "Found $num_workers worker processes."

# 生成CPU列表：0-27 和 56-83
cpus=($(seq 0 27) $(seq 56 83))
num_cpus=${#cpus[@]}
echo "CPU list: ${cpus[@]}"

if [ $num_workers -ne $num_cpus ]; then
    echo "Warning: Number of workers ($num_workers) does not match number of CPUs ($num_cpus)."
fi

# 绑定每个worker到对应的CPU
for i in "${!pids[@]}"; do
    pid=${pids[$i]}
    cpu_index=$((i % num_cpus))
    cpu=${cpus[$cpu_index]}
    echo "Binding PID $pid to CPU $cpu"
    taskset -cp $cpu $pid
done

echo "Done."
