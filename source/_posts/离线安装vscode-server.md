---
title: 离线安装vscode-server
date: 2025-10-18 18:07:19
categories:
  - 教程
tags:
  - vscode-server
  - linux
  - ssh
  - 远程连接
  - 离线部署
cover: /img/cover/130654953_p0.jpg
---

# Remote SSH插件在Linux服务器上离线安装vscode-server



## 前言	

​	Visual Studio Code作为由微软开发且跨平台的免费源代码编辑器，默认支持非常多的编程语言，并且本体十分轻量化，在程序员群体中广受欢迎。其中vscode最值得称道的便是它的丰富的插件系统。其中Remote SSH插件允许在任何运行SSH服务器的远程计算机、虚拟机和容器上打开远程文件夹，对于程序员远程开发很有帮助。

​	但是，Remote SSH在连接至远程服务器时需要在对应服务器上下载一定的资源文件以支撑其功能，这就导致有时在网络不佳（访问外网）、企业内网、无外网服务器等情况下无法成功下载，这时就需要事先下载好相关文件。

​	本教程于2025年10月18日编写，可能后续又些许变动，仅供参考。

## 核心思路

VS Code 远程连接时会根据 **VS Code 本地版本的 commit id** 自动在远程下载 `vscode-server`。
 我们要做的就是：

> **提前下载匹配 commit id 和目标架构的 VS Code Server 压缩包 → 手动上传到远程 → 解压到正确目录。**

Remote SSH 自动下载的.vscode-server文件结构如下：

```
.vscoder-server
|--cli/
|  |--servers/
|  	  |--Stable-7d842fb85a0275a4a8e4d7e040d2625abbf7f084/
|        |--server/
|           |--bin/
|           |--extensions/
|           |--node_modules/
|           |--out/
|           |--LICENSE
|           |--node
|           |--package.json
|           |--product.json
|--data/
|--extensions/
|--code-7d842fb85a0275a4a8e4d7e040d2625abbf7f084
```

其中主要要下载两个文件:

- server目录下的文件的压缩包vscode-server-linux-x64.tar.gz

- code-7d842fb85a0275a4a8e4d7e040d2625abbf7f084文件对于的压缩包



## 获取本地 VS Code 的 commit id

在本地（你的电脑）打开 VS Code：

1. 按下 `Ctrl + Shift + P`

2. 输入并执行：

   ```
   Help: About
   ```
3. 便捷操作

<img src="/img/image-20251018182502203.png" alt="image-20251018182502203" style="zoom: 33%;" /><img src="/img/image-20251018182534398.png" alt="image-20251018182534398" style="zoom: 33%;" />


4. 记下其中的 `Commit:` 一行
    例如：

   ```
   Commit: 7d842fb85a0275a4a8e4d7e040d2625abbf7f084
   ```

假设我们记下的 commit id 是：

```
7d842fb85a0275a4a8e4d7e040d2625abbf7f084
```

 



## 在浏览器中下载对应架构的 Server

VS Code 所有组件都可以通过统一的 Update API 下载，格式如下：

```ruby
https://update.code.visualstudio.com/commit:<commit-id>/<package-type>/stable
```

其中 `<package-type>` 可以是：

| 包类型               | 说明                                 |
| -------------------- | ------------------------------------ |
| `server-linux-x64`   | 普通 Linux 服务器版 VS Code Server   |
| `server-linux-arm64` | ARM64 服务器版 VS Code Server        |
| `cli-alpine-x64`     | Alpine Linux x64 CLI 工具            |
| `cli-alpine-arm64`   | Alpine Linux ARM64 CLI 工具          |
| `cli-linux-x64`      | 通用 Linux x64 CLI 工具（非 Alpine） |
| `cli-linux-arm64`    | 通用 Linux ARM64 CLI 工具            |

下载前可以通过`lscpu`命令来查看自己Linux机器的架构，下载对应架构下的vs code server和cli工具即可





## 构造路径并解压下载文件

以x64架构为例，下载了以下两个文件

- vscode_cli_alpine_x64_cli.tar.gz
- vscode-server-linux-x64.tar.gz

在你登录的linux机器的当前用户目录`/home/<usr>`下手动创建出路径 `.vscode-server/cli/servers/Stable-<commit-id>/server`

其中`commit-id`用之前获取的id进行替换。将`vscode-server-linux-x64.tar.gz`传输至该目录下,运行以下命令进行解压

```bash
tar -zxvf vscode-server-linux-x64.tar.gz --strip-components 1
```

将vscode_cli_alpine_x64_cli.tar.gz 在.vscode-server目录下进行解压

```bash
tar -zxvf vscode_cli_alpine_x64_cli.tar.gz --strip-components 1
```

解压后可以得到一个code文件，将code文件重命名为code-\<commit-id\>,其中id依旧用之前的id进行替换

```bash
mv code code-7d842fb85a0275a4a8e4d7e040d2625abbf7f084
```

然后，回到.vscoder-server的父目录，对文件权限进行设置

```bash
chmod -R 775 .vscode-server
```



最后，就可以依照正常步骤使用Remote SSH连接远程Linux服务器了。
