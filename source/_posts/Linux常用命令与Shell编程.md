---
title: Linux常用命令与Shell编程
date: 2026-01-25 14:29:23
tags:
- shell
- linux
cover: /img/cover/spread_legs-swimsuit.jpg
---

#  远程（和本地）文件同步工具rsync

`rsync` 是一个功能强大的 **远程（和本地）文件同步工具**，以其高效、灵活和可靠性而闻名。它的核心设计目标是快速同步文件，并最小化数据传输量。

## 主要特点

### 1. **增量传输**
- **智能比较**：仅传输源和目标之间有差异的部分
- **节省带宽**：对于大文件，只传输修改过的块，而不是整个文件

### 2. **多种工作模式**
```bash
# 本地同步
rsync [选项] 源目录 目标目录

# 通过SSH远程同步（推送到远程）
rsync [选项] 源目录 用户@远程主机:目标目录

# 通过SSH远程同步（从远程拉取）
rsync [选项] 用户@远程主机:源目录 目标目录

# 使用rsync守护进程
rsync [选项] 源目录 用户@远程主机::模块名/目标目录
```

### 3. **保持文件属性**
- 可以保留权限、时间戳、所有者、组等信息
- 支持符号链接、设备文件等特殊文件

## 常用选项

```bash
# 基本组合（最常用）
rsync -avz 源目录/ 目标目录/

# 常用选项解释
-a, --archive       # 归档模式（保持所有属性，等价于 -rlptgoD）
-v, --verbose       # 显示详细过程
-z, --compress      # 传输时压缩
-r, --recursive     # 递归同步子目录
-l, --links         # 保持符号链接
-p, --perms         # 保持权限
-t, --times         # 保持修改时间
-g, --group         # 保持所属组
-o, --owner         # 保持所有者
-D                  # 保持设备文件和特殊文件

# 其他重要选项
--delete           # 删除目标中存在但源中不存在的文件
--exclude=PATTERN  # 排除匹配的文件/目录
--include=PATTERN  # 包含匹配的文件/目录
--progress         # 显示传输进度
--dry-run          # 试运行，不实际执行
--bwlimit=RATE     # 限制带宽（KB/s）
```

## 实用示例

### 1. **本地备份**
```bash
# 同步本地目录（保留所有属性）
rsync -av /home/user/documents/ /backup/documents/
```

### 2. **远程备份到服务器**
```bash
# 通过SSH同步到远程服务器
rsync -avz -e ssh /local/data/ user@server:/backup/data/
```

### 3. **从服务器同步到本地**
```bash
# 从远程服务器拉取数据
rsync -avz user@server:/remote/data/ /local/backup/
```

### 4. **带排除规则的同步**
```bash
# 排除临时文件和缓存
rsync -av --exclude='*.tmp' --exclude='cache/' \
      source/ destination/
```

### 5. **删除目标多余文件**
```bash
# 使目标与源完全一致
rsync -av --delete source/ destination/
```

## 注意事项

1. **目录斜杠差异**：
   ```bash
   rsync source/ destination/   # 同步source目录内的内容
   rsync source destination/    # 同步source目录本身
   ```

2. **试运行**：首次使用建议先加 `--dry-run` 选项测试

3. **权限问题**：需要相应权限才能读取源文件或写入目标位置

4. **网络中断**：支持部分传输恢复，但不是完全的事务性操作

## 适用场景
- 日常文件备份
- 网站部署和同步
- 大规模数据迁移
- 跨服务器文件同步
- 增量备份系统

`rsync` 是系统管理员和开发者的必备工具，特别适合需要频繁同步大量数据的场景。
