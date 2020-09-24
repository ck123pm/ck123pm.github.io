title: linux/mac os常用命令
tags:
  - linux
categories: Linux
date: 2019-01-06 12:59:12
---
## linux解压tar.gz文件到指定目录
```
tar zxvf test.tar.gz －C /home/work
```

## 终端用UI打开文件夹
mac os
```
open .
```
ubuntu
```
nautilus .
```

## linux查看系统版本
1. 查看内核版本

	- `cat /proc/version`
	- `uname -a`
    - `uname -r`
2. 查看操作系统版本
	- `cat /etc/redhat-release`
    - `cat /etc/issue`
    - `cat /etc/lsb-release`
    - `lsb_release -a`

## linux按文件修改时间查看文件
1. 降序
`ls -lt`

2. 升序
`ls -lrt`


