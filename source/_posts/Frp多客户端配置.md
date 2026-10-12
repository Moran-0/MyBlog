---
title: Frp多客户端配置
date: 2026-07-16 20:35:09
tags:
- Frp
- Sunshine
- Moonlight
- 串流
---

在主流的远程串流方案中，最常用的也是最好用的方案是：Sunshine作为服务端，Moonlight作为客户端。在网络通畅的时候，该方案的网络延迟几乎和局域网内串流无异。但是，由于国内网络条件比较复杂，并且多数网络不具备公网IP，所以经常需要通过内网穿透，将两个内网中的机器网络打通，然后才可以进行串流。

Frp则通常是内网穿透的首选方案，其基本使用不再赘述，本文主要介绍如何再Frp + Sunshine + Moonlight这一组合方案的情况下，配置frp多客户端 ，从而可以在只有一台Frp服务器的情况下，为多台内网机器提供内网穿透服务。

## frpc配置

首先假设当前已经完成frp单客户端的配置，此时使用的Moonlight的默认通信端口。如果要同时接入多台Sunshine主机作为frp客户端，`frpc.toml`则需要满足以下条件：

1. 每台客户端使用不同的 `user`；
2. 每台客户端的代理 `name` 唯一；
3. 每台客户端占用不同的 `remotePort`；
4. 如果某台主机修改了 Sunshine 基础端口，则该主机的 `localPort` 也必须对应新的端口族。

由于`frpc.toml`的配置中不能映射重复的端口，所以后续接入的Sunshine主机首先需要将Sunshine的服务端口进行修改，保证不会与之前的端口冲突。

假设第二台Sunshine主机将基础端口号修改为了`57989`，则本地端口簇会变成：

```
- TCP
  - 48984
  - 48989
  - 48990
  - 49010

- UDP
  - 48998
  - 48999
  - 49000
  - 49002
  - 49010
```

> **对应的fprc.toml修改**

```toml
serverAddr = "服务器公网IP"
serverPort = 7000

auth.method = "token"
auth.token = "YOUR_TOKEN"
# 不重复的用户名
user = "pc-b"

[[proxies]]
name = "sunshine-b-https"
type = "tcp"
localIP = "127.0.0.1"
localPort = 57984
remotePort = 57984

[[proxies]]
name = "sunshine-b-http"
type = "tcp"
localIP = "127.0.0.1"
localPort = 57989
remotePort = 57989

[[proxies]]
name = "sunshine-b-rtsp-tcp"
type = "tcp"
localIP = "127.0.0.1"
localPort = 58010
remotePort = 58010

[[proxies]]
name = "sunshine-b-video"
type = "udp"
localIP = "127.0.0.1"
localPort = 57998
remotePort = 57998

[[proxies]]
name = "sunshine-b-control"
type = "udp"
localIP = "127.0.0.1"
localPort = 57999
remotePort = 57999

[[proxies]]
name = "sunshine-b-audio"
type = "udp"
localIP = "127.0.0.1"
localPort = 57000
remotePort = 57000

[[proxies]]
name = "sunshine-b-mic"
type = "udp"
localIP = "127.0.0.1"
localPort = 57002
remotePort = 57002

[[proxies]]
name = "sunshine-b-rtsp-udp"
type = "udp"
localIP = "127.0.0.1"
localPort = 57010
remotePort = 57010

```



## frps配置

将frpc中使用到的端口添加到frps配置中的**allowPorts**中

同时在服务器的防火墙中对对应端口进行放行
