---
title: Linux系统下激活Typora-以Ubuntu系统为例
date: 2026-07-16 20:08:45
tags:
- Typora
- Ubuntu
- Linux
- 激活
---

## 下载Typora安装包（推荐 1.9.3 版本）

> [Typora中文官网下载](Typora - macOS release channel)



在终端下输入以下命令直接下载

```bash
#查看电脑架构
uname -m
#下载TYPORA安装包
#X86(amd)
wget https://download2.typoraio.cn/linux/typora_1.8.10_amd64.deb --output-document
typora.deb
#ARM
wget https://download2.typoraio.cn/linux/typora_1.8.10_arm64.deb --output-document
typora.deb
#安装TYPORA
sudo dpkg -i typora.deb
```



## **克隆Yporaject项目**

`git clone https://github.com/liheji/Yporaject`



## 配置 rust 编译环境

由于编译项目需要 rust 的支持，所以我们需要配置相关环境(若已有，则可跳过该步骤)

```bash
#运行官方脚本安装即可
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
#检查cargo，若看到如下版本信息，则说明配置成功
cargo -V
# cargo 1.70.0 (ec8a8a0ca 2023-04-25)
```




注：若安装过程中出现其他问题，请自行网上搜索相关安装教程，关键字 ubuntu cargo rust install

## 编译Yporaject项目

```bash
#进入Yporaject项目
cd Yporaject
#运行编译命令
cargo build
#查看二进制是否生成,程序名称为 node_inject
ls target/debug
#尝试运行该二进制程序
cargo run
# output:
# no node_modules.asar found
# move me to the root of your typora installation(the same directory as executable of
# electron)
```


请务必确认当前项目目录 **target/debug** 下是否生成了 **node_inject** 二进程序



## 复制二进制程序到安装目录下

```bash
#记录当前目录路径，待会返回需要用到
cur=`pwd`
#复制二进制程序到相关目录下
sudo cp target/debug/node_inject /usr/share/typora
#进入相关目录
cd /usr/share/typora
#给予二进制程序执行权限
sudo chmod +x node_inject
#检查二进制程序是否可以运行,并执行(请注意程序运行输出信息，观察是否运行成功！！)
#若无读写权限,建议使用 sudo ./node_inject
sudo ./node_inject
```





## 获取许可证激发码

```bash
#返回项目
cd $cur
#进入 license-gen 文件夹
cd license-gen
#编译代码
cargo build
#运行二进制程序
cargo run
#你将会得到以下输出
output:
	Finished dev [unoptimized + debuginfo] target(s) in 0.00s
	Running `target/debug/license-gen`
License for you: xxxxxx-xxxxxx-xxxxxx-xxxxxx

```

复制 **License for you: xxxxxx-xxxxxx-xxxxxx-xxxxxx** 的那一串激发码，待会需要用到



## 激活软件

```bash
#运行TYPORA(你也可以在桌面上点击相关图标)
typora &
```

依次点击界面上方菜单栏选项 help > my license(帮助 > 我的许可证...)
邮箱可以随便填
然后在第二输入框中，粘贴刚才得到的激发码
点击 激活 按钮后，你将会看到激发成功界面



---

> 需要注意的是这种方法不支持最新的1.10版本（推荐使用版本1.9.3）。激活失败后，记得删
> 除/typora文件夹下的node文件夹再重试激活

---
