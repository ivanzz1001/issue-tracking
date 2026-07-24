#!/bin/sh

# 获取CPU核心数
cpu_count=$(nproc)
# 遍历每个核心，打印正在其上运行的进程
for ((i=0; i<cpu_count; i++)); do
    echo "CPU核心 $i 上的进程:"
    ps -e -o pid,psr,comm,args | awk -v core=$i '$2==core {print "  PID: "$1", CMD: "$3}'
done
