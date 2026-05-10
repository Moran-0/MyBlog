@echo off
chcp 65001 >nul
title Hexo 博客本地预览
echo ====================================
echo 正在清理旧文件
echo ====================================
call npx hexo clean
if %errorlevel% neq 0 (
    echo 清理失败！
    pause
    exit /b 1
)

echo.
echo ====================================
echo 正在生成静态文件...
echo ====================================
call npx hexo generate
if %errorlevel% neq 0 (
    echo 生成失败！
    pause
    exit /b 1
)

echo.
echo ====================================
echo 正在启动服务器...
echo 按 Ctrl+C 可停止服务器
echo ====================================
call npx hexo server

pause