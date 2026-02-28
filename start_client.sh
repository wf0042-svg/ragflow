#!/bin/bash
# RAGFlow 前端启动脚本

# 检查后端是否就绪
echo "🔍 检查后端服务状态..."
if ! lsof -i :9380 >/dev/null 2>&1; then
    echo "⚠️  后端服务未运行，请先运行 ./start_server.sh"
    echo "   或者等待后端启动完成..."
    
    # 等待最多 30 秒
    for i in {1..30}; do
        if lsof -i :9380 >/dev/null 2>&1; then
            echo "✅ 后端服务已就绪"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "❌ 后端服务未启动，前端可能无法正常工作"
            echo "   继续启动前端..."
        fi
        sleep 1
    done
else
    echo "✅ 后端服务已运行"
fi

# 启动前端服务
echo "🎨 启动前端服务..."
cd web
npm run dev
