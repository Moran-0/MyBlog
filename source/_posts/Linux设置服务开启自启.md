---
title: Linux设置服务开启自启
date: 2026-06-03 17:26:52
tags:
- Linux
- Service
---



> 在 Linux 系统中，确保关键服务能够在系统启动时自动运行是一项非常重要的任务。尤其是在服务器环境中，我们希望一些服务（如数据库、应用服务或自定义脚本）能够在系统每次启动后自动启动，从而确保业务的持续运行。在 Linux 中，常用的服务管理系统有两种：systemd 和 sysvinit。本指南将详细介绍如何在不同的 init 系统中设置服务的开机自启，并讲解如何创建和配置自定义的 systemd 服务。

# 一、Linux 服务管理概述

在 Linux 中，服务是后台运行的进程，它们在系统启动时开始运行，并且在系统关闭时停止。管理这些服务的工具因操作系统版本的不同而不同：

- systemd：大多数现代 Linux 发行版（如 CentOS 7+、Ubuntu 16.04+、Debian 8+）都使用 systemd 来管理系统服务。
- sysvinit：一些较老的 Linux 发行版（如 CentOS 6 或 Ubuntu 14.04）使用 sysvinit 来管理服务。

每种服务管理工具都有自己的配置方式和管理命令。在现代 Linux 系统中，`systemd` 是最常见的服务管理工具，因此它也是我们讨论的重点。

# 二、systemd 中设置服务开机自启

## 2.1 systemd 介绍

systemd 是 Linux 的一种系统和服务管理器，负责系统的引导过程，管理系统运行时的服务，并提供许多系统功能，如日志、时间同步等。它通过服务单元文件（通常为 .service 文件）来定义和管理服务，并提供强大的依赖管理和并行启动功能。

## 2.2 如何检查服务的状态

首先，你需要确保服务已经由 systemd 管理，并且能够手动启动。你可以使用以下命令检查服务的状态：

```shell
sudo systemctl status <service_name>
```

例如，如果你的服务名称是 pip-nginx，你可以使用以下命令检查它的状态：

```shell
sudo systemctl status pip-nginx
```

输出信息会显示服务是否正在运行，以及服务的日志和状态信息。如果服务已被 systemd 管理，它会显示当前服务的详细信息。

## 2.3 启用服务开机自启

要设置某个服务在系统启动时自动运行，你可以使用 `systemctl enable` 命令。它将服务添加到系统的启动项中，确保在每次启动时都会启动该服务。

```bash
sudo systemctl enable <service_name>
```

例如，要设置 pip-nginx 服务开机自启，运行以下命令：

```bash
sudo systemctl enable pip-nginx
```

这会在 `/etc/systemd/system/multi-user.target.wants/` 目录中为指定服务创建一个符号链接，确保服务在系统启动时自动运行。



如上示例可以查询pip-*相关服务开机自启链接。

## 2.4 手动启动和停止服务

如果你想立即启动或停止某个服务，可以使用以下命令：

启动服务：

```xml
sudo systemctl start <service_name>
```

停止服务：

```xml
sudo systemctl stop <service_name>
```

这些命令将立即启动或停止指定的服务。你可以使用它们来验证服务是否正常运行。

## 2.5 检查服务是否成功启用

你可以使用以下命令检查服务是否已成功启用开机自启：

```csharp
sudo systemctl is-enabled <service_name>
```

如果服务已成功启用，输出将显示 enabled。如果服务未启用或未正确配置，输出将显示 disabled。

## 2.6 禁用开机自启服务

如果你不再希望某个服务在系统启动时自动启动，可以使用`systemctl disable` 命令：

```bash
sudo systemctl disable <service_name>
```

例如，禁用 nginx 服务开机自启的命令是：

```bash
sudo systemctl disable nginx
```

禁用服务后，它将在系统启动时不再自动启动，但你仍然可以手动启动该服务。

# 三、在 sysvinit 中设置服务开机自启

虽然 systemd 是当前 Linux 发行版的标准，但较老的发行版（如 CentOS 6、Debian 7 等）仍然使用 sysvinit 来管理服务。在 sysvinit 中，服务的开机自启配置与 systemd 不同，以下是相关步骤。

## 3.1 使用 chkconfig 设置开机自启

chkconfig 是管理 sysvinit 服务开机自启的工具。你可以使用它来启用或禁用服务的开机自启。

启用开机自启：

```csharp
sudo chkconfig <service_name> on
```

禁用开机自启：

```xml
sudo chkconfig <service_name> off
```

例如，要启用 httpd（Apache）服务的开机自启，运行以下命令：

```csharp
sudo chkconfig httpd on
```

## 3.2 手动管理开机脚本

在 sysvinit 系统中，服务启动脚本存放在 /etc/init.d/ 目录下。你可以通过手动添加服务的启动脚本来管理服务的开机自启。

列出所有服务：

你可以使用以下命令查看系统中所有可用的服务脚本：

```bash
ls /etc/init.d/
```

手动添加服务到开机自启：

你可以使用 update-rc.d 命令将服务添加到开机启动项：

```xml
sudo update-rc.d <service_name> defaults
```

这会在适当的运行级别中添加服务，确保它在系统启动时自动运行。

# 四、创建自定义 systemd 服务

如果你有一个自定义的脚本或程序，希望在系统启动时运行，可以通过创建 systemd 服务来实现。

## 4.1 创建服务单元文件

systemd 服务通过服务单元文件（.service 文件）来管理。首先，你需要在 `/etc/systemd/system/` 目录中创建一个新的服务文件。例如，创建一个名为 myservice.service 的文件：

```bash
sudo nano /etc/systemd/system/myservice.service
```

`nano` 是一个简单的文本编辑器，通常预装在大多数 Linux 发行版中。 `nano [文件名]`如果文件已经存在，nano 将打开该文件。如果文件不存在，nano 将创建一个新文件。

## 4.2 服务单元文件配置

在文件中添加服务的相关配置。以下是一个自定义服务的示例：

```ini
[Unit]
Description=My Custom Service
After=network.target

[Service]
ExecStart=/path/to/your/program --argument
Restart=always
User=youruser
Group=yourgroup

[Install]
WantedBy=multi-user.target
```

**解释：**

> [Unit]：定义服务的描述和依赖。
>
> After=network.target 表示该服务会在网络启动后启动。
>
> [Service]：定义服务的启动命令、重启策略、运行用户等。
>
> ExecStart 是服务启动时执行的命令。
>
> [Install]：定义服务在哪个运行级别下启动。
>
> multi-user.target 表示该服务将在多用户模式下启动。

## 4.3 重新加载 systemd 配置

保存服务单元文件后，使用以下命令重新加载 systemd 配置：

```undefined
sudo systemctl daemon-reload
```

这会告诉 systemd 读取新的服务单元文件并更新服务列表。

## 4.4 启用和启动服务

接下来，你可以启用并启动该服务：

```bash
sudo systemctl enable myservice
sudo systemctl start myservice
```

## 4.5 检查服务状态

使用以下命令检查自定义服务是否正在运行：

```shell
sudo systemctl status myservice
```

输出信息会显示服务的当前状态、日志以及是否成功启动。

# 五、常见问题与故障排查

在设置服务开机自启时，可能会遇到一些常见问题。以下是一些常见问题的排查方法。

## 5.1 服务无法启动或启动失败

如果你发现服务无法启动，首先检查服务的状态：

```shell
sudo systemctl status <service_name>
```

如果服务启动失败，输出信息通常会显示失败的原因。可以进一步查看详细日志，帮助诊断问题：

```undefined
sudo journalctl -xe
```

## 5.2 服务没有启用开机自启

检查服务是否已启用开机自启：

```csharp
sudo systemctl is-enabled <service_name>
```

如果显示 disabled，可以重新启用开机自启：

```bash
sudo systemctl enable <service_name>
```

## 5.3 systemd 服务单元文件配置错误

如果你创建的自定义服务无法正常运行，检查以下几点：

- **路径和命令是否正确**：确保 ExecStart 中指定的路径和命令正确。
- **权限问题**：确保服务的运行用户有权限执行服务所需的命令和访问文件。
- **日志检查**：使用 journalctl 命令查看服务的日志，查找详细的错误信息。

# 六、总结

在 Linux 系统中设置服务开机自启是确保服务器稳定运行的重要任务之一。无论是使用 systemd 还是 sysvinit，你都可以轻松地管理系统服务的启动行为。现代 Linux 系统大多数都使用 systemd 来管理服务，它提供了灵活的服务管理功能和丰富的日志记录功能。而在较旧的 Linux 发行版中，sysvinit 系统也有一套简单的服务管理方式。

此外，创建自定义服务并将其配置为开机自启是 Linux 管理中的常见需求。通过编写自定义的 .service 文件，并使用 systemd 进行管理，你可以轻松控制自定义服务的启动和运行。
