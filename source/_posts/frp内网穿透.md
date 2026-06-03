---
title: frp内网穿透
date: 2026-06-03 15:57:32
tags:
- frp
- 内网穿透
---

# FRP内网穿透

## 什么是 frp

**frp**（Fast Reverse Proxy）是一个专注于内网穿透的高性能反向代理应用，支持 TCP、UDP、HTTP、HTTPS 等多种协议。它可以将内网服务通过具有公网 IP 的节点暴露给外网，实现安全、便捷的远程访问。



## 环境准备

**服务端要求：** 一台具有公网 IP 的 Linux 服务器（推荐 Ubuntu/CentOS） - 开放必要的端口（如 7000、8080 等）

**客户端要求：** 内网中的任意设备（Linux、Windows、macOS 均可） - 能够访问公网服务器



## 第一步：下载 frp

访问 [frp GitHub Releases](https://link.zhihu.com/?target=https%3A//github.com/fatedier/frp/releases) 页面，根据系统架构下载对应版本：

```bash
# 查看系统架构
uname -m

# 下载 Linux x86_64 版本
wget https://github.com/fatedier/frp/releases/download/v0.62.1/frp_0.62.1_linux_amd64.tar.gz

# 解压
tar -zxvf frp_0.62.1_linux_amd64.tar.gz
cd frp_0.62.1_linux_amd64

# 赋予执行权限
chmod +x frps frpc
```

## 第二步：配置服务端（frps）

创建 `frps.toml` 配置文件：

```text
# frps.toml - 服务端配置

# 基础配置
bindPort = 7000                    # frps 监听端口

# 安全配置
[auth]
method = "token"
token = "your_secure_token_here"   # 请修改为复杂密码

# 端口限制（可选，提升安全性）
allowPorts = [
  { start = 8000, end = 8010 },    # 允许 8000-8010 端口
  { single = 3306 },               # 允许 3306 端口
  { single = 22 }                  # 允许 22 端口
]

# Web 管理界面（可选）
[webServer]
addr = "0.0.0.0"
port = 7500
user = "admin"
password = "your_admin_password"

# 日志配置
[log]
to = "./frps.log"
level = "info"
maxDays = 7
```

## 第三步：启动服务端

```bash
# 前台启动（测试用）
./frps -c frps.toml

# 后台启动（生产环境）
nohup ./frps -c frps.toml > frps.out 2>&1 &

# 检查运行状态
ps -ef | grep frps
netstat -tunlp | grep 7000
```

## 第四步：配置客户端（frpc）

创建 `frpc.toml` 配置文件：

```text
# frpc.toml - 客户端配置

[common]
serverAddr = "your_server_ip"      # 服务端公网 IP
serverPort = 7000                  # 服务端监听端口
auth.token = "your_secure_token_here"  # 与服务端保持一致

# SSH 服务穿透
[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 8022

# Web 服务穿透
[[proxies]]
name = "web"
type = "tcp"
localIP = "127.0.0.1"
localPort = 8080
remotePort = 8080

# MySQL 数据库穿透
[[proxies]]
name = "mysql"
type = "tcp"
localIP = "127.0.0.1"
localPort = 3306
remotePort = 8306
```

## 第五步：启动客户端

```bash
# 前台启动（测试用）
./frpc -c frpc.toml

# 后台启动（生产环境）
nohup ./frpc -c frpc.toml > frpc.out 2>&1 &

# 检查运行状态
ps -ef | grep frpc
```

## 第六步：验证连接

```bash
# SSH 连接测试
ssh user@your_server_ip -p 8022

# Web 服务访问
curl http://your_server_ip:8080

# MySQL 连接测试
mysql -h your_server_ip -P 8306 -u username -p
```

------

## 配置示例

### 服务端

```toml
bindPort = 7000
allowPorts = [{ single = 47984},{ single = 47989},{ single = 47990},{ single = 48010},{ start = 47998, end = 48001},{single = 6000}]
vhostHTTPPort = 7999
vhostHTTPSPort = 8000
auth.token = "#the_server_of_moran#"
# 默认为 127.0.0.1，如果需要公网访问，需要修改为 0.0.0.0。
webServer.addr = "0.0.0.0"
webServer.port = 7500
# dashboard 用户名密码，可选，默认为空
webServer.user = "Moran"
webServer.password = "677477k897"
# 开启https连接
# webServer.tls.certFile = "server.crt"
# webServer.tls.keyFile = "server.key"
#[common]
#bind_port = 7000          # frpc 连接 frps 的 TCP 端口
#bind_udp_port = 7001      # frpc 连接 frps 的 UDP 端口
#dashboard_port = 7500     # 可选：FRPS 管理面板
#dashboard_user = moran
#dashboard_pwd = @CYF1112aliyun

#authentication_method = token
#token = #the_server_of_moran#

#vhost_http_port = 80      # 可选：HTTP 穿透
#vhost_https_port = 443    # 可选：HTTPS 穿透
```



### 客户端

```toml
serverAddr = "127.0.0.1"
serverPort = 7000

[[proxies]]
name = "test-tcp"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6000

```



## 高级配置

### HTTP/HTTPS 穿透

```text
# HTTP 服务穿透
[[proxies]]
name = "web_http"
type = "http"
localIP = "127.0.0.1"
localPort = 8080
customDomains = ["your-domain.com"]

# HTTPS 服务穿透
[[proxies]]
name = "web_https"
type = "https"
localIP = "127.0.0.1"
localPort = 8443
customDomains = ["your-domain.com"]
```

### UDP 穿透

```text
# UDP 服务穿透
[[proxies]]
name = "dns"
type = "udp"
localIP = "127.0.0.1"
localPort = 53
remotePort = 8053
```

### 多客户端配置

```text
# 客户端 A 配置
[[proxies]]
name = "server_a_ssh"
type = "tcp"
localIP = "192.168.1.100"
localPort = 22
remotePort = 8022

# 客户端 B 配置
[[proxies]]
name = "server_b_ssh"
type = "tcp"
localIP = "192.168.1.101"
localPort = 22
remotePort = 8023
```

------

## 安全最佳实践

### 1. 强化认证

```text
[auth]
method = "token"
token = "complex_random_string_here"  # 使用复杂随机字符串
```

### 2. 端口限制

```text
allowPorts = [
  { single = 22 },     # 只允许特定端口
  { start = 8000, end = 8010 }
]
```

### 3. 访问控制

```text
# 限制客户端 IP
[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 8022
allowUsers = ["user1", "user2"]  # 仅允许特定用户
```

### 4. 日志监控

```text
[log]
to = "./frps.log"
level = "warn"        # 只记录警告和错误
maxDays = 30          # 保留 30 天日志
```

------

## 常见问题与解决方案

### 1. 连接被拒绝（Connection Refused）

**问题现象：**

```text
connect to server error: dial tcp x.x.x.x:7000: connect: connection refused
```

**解决方案：** - 检查服务端 frps 是否正常运行 - 确认端口配置是否正确 - 检查防火墙和安全组设置

### 2. 认证失败

**问题现象：**

```text
authorization failed
```

**解决方案：** - 确认客户端和服务端 token 是否一致 - 检查配置文件格式是否正确

### 3. 端口被占用

**问题现象：**

```text
bind port error: listen tcp :8080: bind: address already in use
```

**解决方案：** - 更换其他可用端口 - 检查端口是否在 allowPorts 范围内

### 4. 本地服务无法访问

**问题现象：**

```text
connect to local service error: dial tcp 127.0.0.1:8080: connect: connection refused
```

**解决方案：** - 确认本地服务是否正常运行 - 检查 localIP 和 localPort 配置 - 确认服务监听的 IP 地址

------

## 性能优化建议

### 1. 网络优化

```text
# 启用 TCP 多路复用
transport.tcpMux = true
transport.tcpMuxKeepaliveInterval = 30

# 连接池配置
transport.maxPoolCount = 10
```

### 2. 压缩优化

```text
# 启用数据压缩
[[proxies]]
name = "web"
type = "tcp"
localIP = "127.0.0.1"
localPort = 8080
remotePort = 8080
useCompression = true
```

### 3. 带宽限制

```text
# 限制带宽使用
[[proxies]]
name = "web"
type = "tcp"
localIP = "127.0.0.1"
localPort = 8080
remotePort = 8080
bandwidthLimit = "1MB"
```

------

## 总结

frp 作为一款优秀的内网穿透工具，具有配置简单、性能优异、功能丰富等特点。通过本文的详细介绍，相信你已经掌握了 frp 的基本使用方法和高级配置技巧。

在实际使用中，建议： 1. **安全第一**：务必设置强密码 token，限制端口范围 2. **监控运维**：定期检查日志，监控服务状态 3. **性能调优**：根据实际需求调整配置参数 4. **备份配置**：定期备份配置文件，避免意外丢失
