---
title: ubuntu 16.04开机提示：检测到系统程序出现问题
date: 2019-01-05 21:33:21
tags: 
- linux
categories: Linux
---


## Ubuntu 16.04开机后提示：检测到系统程序出现问题

### 解决方法

1. 打开终端，输入
```
sudo gedit /etc/default/apport 
```
2. 把里面的`enabled=1`改为`enabled=0`,保存