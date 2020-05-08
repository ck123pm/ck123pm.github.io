title: 利用docker快速搭建hexo博客环境并实现多机同步
author: ck123pm
tags:
  - c++
categories:
  - Tech
date: 2020-05-07 15:48:00
---
## 前言
> 之前用hexo+next在自己的笔记本上搭过一次，那时候对`npm,nodejs`都不太了解，更别提`docker`了。各种环境依赖，折腾半天总算搞好了(搭完之后真的不想再弄第二遍了)。但是写文章，发布都必须用自己的那台笔记本，此外还有一堆命令,`hexo new post, hexo g, hexo d`等，一段时间后总是忘记了，还是不够方便，当时就一直希望能实现快速搭建博客环境，并且能备份主题配置、文章源文件等。最近一年新公司接触了`docker`和大前端的一些技术，网上也搜到了一些利用docker搭建博客环境的教程，因此决定把自己的Blog重新弄起来。

<!-- more -->
## 实现方案
环境依赖：
1. docker
2. git

### 快速搭建博客环境
这个利用docker就可以很容易实现了，不想重新造轮子于是在github上搜了一些，最终使用了[spurin/docker-hexo](https://github.com/spurin/docker-hexo).

主要看中了他这个镜像的几个优点：
1. 自带hexo-admin插件
2. 自动生成ssh秘钥（方便后面提交github用）
3. 所有配置文件及博客源文件都映射到宿主机，可以方便利用git分支，实现备份同步

为了偷懒，直接用他在dockerhub上的打包好的镜像。
本地运行
```
docker run -d --name=myblog \
-e HEXO_SERVER_PORT=4000 \
-e GIT_USER="Your Name" \
-e GIT_EMAIL="your.email@domain.tld" \
-v <your host path>:/app \
-p 4000:4000 \
spurin/hexo
```
首次启动会去拉镜像，容器起来后还会去做一些配置，生成默认博客项目等，所以会有一点慢。可以通过`docker logs -f <container id>`来查看日志。

等服务完全初始化完成，浏览器打开`localhost:4000`就可以看到hexo的博客主页了。浏览器打开`localhost:4000/admin`即可进入hexo-admin的页面。

在hexo-admin上可以新增、修改、删除文章，详细用法可以查询其他文章。

### 部署到github上
在上文中我们创建容器时，填入了我们的username和邮箱地址，容器启动时会根据这个信息生成对应的ssh公钥和私钥。在github个人setting里面，可以将公钥添加到ssh key列表中。以后我们`git push`的时候就可以不用输入用户名密码了。这部分配置，可以查询其他文章，有空我再补充到该文当中。

配置完git相关之后，执行`docker exec -it myblog hexo d `即可部署到github上。

### 多机备份和同步





