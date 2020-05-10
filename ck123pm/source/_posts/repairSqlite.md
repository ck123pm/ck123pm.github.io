---
title: 修复sqlite3数据库,database disk image is malformed
date: 2019-01-20 16:01:30
tags:
    - sqlite
    - python
    - 数据库
categories: 编程
---
> 利用Python将sqlite修复相关的命令封装了一下，并且针对sqlite导出的临时文件最后一行默认是`Rollback`进行了处理，最后打包成exe程序。

<!--more-->

## database disk image is malformed
sqlite是一个文本型数据库，其内部虽然做了异常处理，且官网上也说一般的[异常](https://www.sqlite.org/faq.html#q21)不会引起数据库文件损坏，但是官方还是给出了有可能导致数据库文件损坏的[情况](https://www.sqlite.org/howtocorrupt.html)。

网上随便一搜*database disk image is malformed*，发现这问题出现的频率还挺高的，看来sqlite的异常出错几率还是挺高的啊。不过一般来说，sqlite这种类型的数据库也是用在嵌入式设备上较多，用来记录一些读写频率不是很高的场景，例如记录软件的用户`配置`信息等。但是很不巧，我们之前的项目中采用Sqlite来作为`记录型数据`的数据库，读写频率还是比较高的，因此碰到了两次客户现场出现数据库损坏的情况。

### 不负责任的原因猜测
通过打印日志分析，当时正在执行`写事务`的时候，我们的服务进程异常停止了。服务被拉起之后，再次写同一个数据库文件的时候，就报`database disk image is malformed`这个错误了，显然此时数据库文件的结构已经出现了异常。因此，推测是写数据库文件时，进程异常停止导致的。

## 解决方案一（命令行手动修复）
网上搜索之后发现，解决方案还是比较简单的，虽然Sqlite本身没有提供修复工具，但是sqlite3.exe提供了`dump`数据库文件，以及从`sql`文件中`read`并写到数据库文件中的操作。

这里的`dump`命令就是从一个数据库文件`CorruptDB`中，将其所有执行过的`sql`语句全部`dump`下来，并放到一个临时文件`tmp.sql`中。

可以用sqlite3.exe进行修复，基本操作如下。

**以下操作都在命令行中运行**
### 1.命令行打开sqlite3.exe并读取损坏的文件
```
D:\Tools\RepairTool>sqlite3.exe CorruptDB
```
此时进入了sqlite命令行环境
### 2.导出sql语句到临时文件
```
sqlite>.output tmp.sql
sqlite>.dump
sqlite>.quit
```
### 3.修改tmp.sql文件
由于数据库文件损坏，所以sqlite自动将tmp.sql最后一行加上了一句`Rollback`，因此我们需要手动修改`tmp.sql`文件，将最后一行的`Rollback`改为`Commit;`。

### 4.读取tmp.sql并写入到新库中
```
D:\Tools\RepairTool>sqlite3.exe NewDB
sqlite>.read tmp.sql
sqlite>.quit
```
大功告成！

## 解决方案二（利用python编写一个脚本，自动执行以上步骤）
基本流程很简单，就是将以上步骤用python封装一下，命令行操作用python的`os.system(cmd)`,此外还需要对生成的临时文件`tmp.sql`进行最后一行的处理。

本来这些操作用`bat`批处理会更简单，也写好了一个`.bat`脚本，但是批处理用来读取数据库文件并修改最后一行的方法比较憨憨:P，尤其是这个文件比较大的时候，从几百万行的文件开头开始一行行遍历到最后一行去修改，有点蠢。所以改为用python的`fseek`从文件尾开始偏移读取。

话不多说，看下几个封装的几个函数。
### 1.`dump`SQL语句
```python
def __dumpSql(self):
        cmd = "cd "+self.__path+"&"+self.__path[0:2]+"&"+'''\
        sqlite3.exe {oldFile}<dump.sql'''.format(oldFile = self.__oldFile)
        os.system(cmd)
```
这里的`dump.sql`里面就是
```
.output tmp.sql
.dump
.quit
```
### 2.修改临时文件的最后一行
```python
def __modLastLine(self):
        with open(self.__tmpFilePath,"rb+") as f:
            # 获取文件大小
            fsize = os.path.getsize(self.__tmpFilePath)
            # 设置初始偏移量
            offset = -8
        
            while -1*offset <fsize:
                # 从后往前定位
                f.seek(offset ,os.SEEK_END)
                # 读取当前行记录
                lines = f.readlines()
                # 如果当前的行数已经大于等于2了，说明最后一行的所有字符已经包括读取完了
                if len(lines) >=2:
                    # 获取最后一行的字符长度
                    last_line_len = len(lines[-1])
                    # 重新seek之后，用truncate()函数进行截取
                    f.seek(-last_line_len,os.SEEK_END)
                    f.truncate()
                    # 在最后再加上Commit;
                    f.write(b"Commit;")
                    return
                else:
                    offset*=2
```

 ### 3.读取临时文件，并写新库
 ```python
 def __readSql(self):
        cmd = "cd "+self.__path+"&"+self.__path[0:2]+"&"+'''\
        sqlite3.exe {newFile}<read.sql'''.format(newFile = self.__newFile)
        os.system(cmd)
 ```
 此处`read.sql`内容：
 ```
 .read tmp.sql
 .quit
 ```

 ### 4.修复完成后删除临时文件
 ```python
 def __delTmp(self):
        cmd = "cd "+self.__path+"&"+self.__path[0:2]+"&"+'''\
        del {tmpFile}'''.format(tmpFile=self.__tmpFile)
        os.system(cmd)
 ```

 ## 完整源码
 放在了github上，有需要可以看一下[sqliteRepair](https://github.com/ck123pm/sqliteRepair)。