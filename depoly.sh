#!/bin/bash
set -e

# ===== 可配置区 =====
HEX0_DIR="/opt/MyBlog" # hexo项目目录
NGINX_ROOT="/var/www/hexo_myblog/public" # nginx部署目录
TEMP_URL="http://39.105.146.58"
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
