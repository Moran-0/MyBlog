# 个人博客项目总体架构

```
浏览器
  ↓ 80 / 443
Nginx（反向代理 / 静态服务器）
  ↓
Hexo 生成的静态文件（public/）
```

**核心思想：**

- ❌ 不直接暴露 `hexo server`
- ✅ Hexo 只负责 **生成静态文件**
- ✅ Nginx 负责 **对外服务**
- ✅ 使用 80 / 443（不容易被封）
- ✅ 可轻松上 HTTPS

# 服务器环境

- Linux（Ubuntu 20.04）
- 具备公网 IP
- 域名（目前暂无，后续可扩展）

## 基础依赖

```bash
# git nginx nodejs npm
# 一键安装
apt update
apt install -y git nginx nodejs npm
# 安装hexo
npm install -g hexo-cli
```



# Hexo项目静态文件生成

### 1️⃣ 拉取或创建项目

```
git clone https://xxx/your-hexo-blog.git
cd your-hexo-blog
npm install
```

### 2️⃣ 生成静态文件

```
hexo clean
hexo generate
# 或 hexo g
```

生成目录：

```
your-hexo-blog/
└── public/
```

------



# Nginx 部署



### 1.  放置网站文件

```bash
mkdir -p /var/www/hexo
cp -r public/* /var/www/hexo/
```

或软链接（方便更新）：

```bash
ln -s /path/to/hexo/public /var/www/hexo
```

------

### 2. Nginx 配置示例

```yaml
server {
    listen 80;
    server_name example.com www.example.com;
    # 无域名时配置为
    # server_name _;
    
	# root目录需要对应public文件夹，该路径需要具备index.html文件
    root /var/www/hexo;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 30d;
        access_log off;
    }
}
```

启用配置：

```bash
nginx -t
systemctl reload nginx
# 可能出现报错duplicate default server for 0.0.0.0:80
# 推荐禁用默认站点 rm /etc/nginx/sites-enabled/default
# 禁用后重新检测并加载
```

现在访问：

```
http://你的公网IP
```

------

### 3. 部署脚本

将上述动作统一编写成脚本操作，避免重复操作。

```bash
#!/bin/bash
set -e

# ===== 可配置区 =====
HEX0_DIR="/opt/MyBlog" # hexo项目目录
NGINX_ROOT="/var/www/hexo_myblog/public" # nginx部署目录
TEMP_URL="http://服务器公网IP"
CONFIG_FILE="_config.yml"
# ====================

echo "==> Enter hexo directory"
cd "$HEX0_DIR"

echo "==> Backup config"
cp $CONFIG_FILE ${CONFIG_FILE}.bak

echo "==> Rewrite url for nginx deployment"
sed -i "s|^url:.*|url: ${TEMP_URL}|" $CONFIG_FILE

echo "==> Clean & generate hexo"
hexo clean
hexo generate

echo "==> Sync static files to nginx root"
rsync -av --delete public/ "$NGINX_ROOT/" # 若已建立软链接则不需要

echo "==> Restore original config"
mv ${CONFIG_FILE}.bak $CONFIG_FILE

echo "==> Reload nginx"
nginx -t
systemctl reload nginx

echo "==> Deploy finished successfully 🎉"
```



# GitHub pages

本项目另一同时存在的部署方案为使用GitHub Actions自动进行构建部署。每当有push动作时便会触发工作流进行构建hexo静态文件并部署到GitHub Pages。

