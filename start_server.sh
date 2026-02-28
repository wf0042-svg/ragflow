#!/bin/bash
# RAGFlow 开发环境快速启动脚本

set -e

echo "🚀 启动 RAGFlow 开发环境..."

# 激活虚拟环境
if [ -d ".venv" ]; then
    source .venv/bin/activate
    echo "✅ 虚拟环境已激活"
else
    echo "❌ 错误：找不到 .venv 虚拟环境"
    exit 1
fi

# 设置 PYTHONPATH
export PYTHONPATH=$(pwd)
echo "✅ PYTHONPATH 已设置: $PYTHONPATH"

# 检查依赖服务
echo "🔍 检查依赖服务..."
if ! docker ps | grep -q "docker-mysql-1"; then
    echo "⚠️  MySQL 容器未运行，正在启动依赖服务..."
    docker compose -f docker/docker-compose-base.yml up -d
    echo "⏳ 等待服务启动..."
    sleep 5
fi

# 启动后端服务（包括 ragflow_server 和 task_executor）
echo "🎬 启动后端服务（后台运行）..."
bash docker/launch_backend_service.sh &

# 等待后端启动并监听端口
echo "⏳ 等待后端服务启动..."
for i in {1..30}; do
    if lsof -i :9380 >/dev/null 2>&1; then
        echo "✅ 后端服务已就绪（端口 9380）"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ 后端服务启动超时"
        exit 1
    fi
    sleep 1
    echo "   等待中... ($i/30)"
done
