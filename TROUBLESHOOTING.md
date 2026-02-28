# RAGFlow 开发环境问题排查记录

## 问题描述

PDF 文档解析失败，一直卡在处理中，没有进展。

## 根本原因

### 1. 缺少 task_executor 进程
- **现象**: 只启动了 `ragflow_server.py`，没有启动 `task_executor.py`
- **影响**: 文档无法被处理，Elasticsearch 索引无法创建
- **解决**: 启动 `task_executor.py` 进程

### 2. 缺少 DeepDOC 模型文件
- **现象**: 缺少 `updown_concat_xgb.model` 文件
- **错误信息**:
  ```
  XGBoostError: LocalFileSystem::Open "/Users/.../rag/res/deepdoc/updown_concat_xgb.model":
  No such file or directory
  ```
- **影响**: PDF 文档无法使用 DeepDOC 解析器进行布局分析
- **解决**: 从 HuggingFace 下载模型文件

## 解决步骤

### 步骤 1: 下载缺失的模型文件

```bash
cd rag/res/deepdoc

# 使用 HuggingFace 镜像站下载（国内访问更快）
curl -L -o updown_concat_xgb.model \
  "https://hf-mirror.com/InfiniFlow/text_concat_xgb_v1.0/resolve/main/updown_concat_xgb.model"

# 验证文件
ls -lh updown_concat_xgb.model
# 应该显示约 5.6 MB
```

### 步骤 2: 启动 task_executor

```bash
# 停止旧进程（如果有）
pkill -f task_executor

# 启动新的 task_executor
source .venv/bin/activate
export PYTHONPATH=$(pwd)
nohup python rag/svr/task_executor.py 0 > /tmp/task_executor.log 2>&1 &

# 验证进程已启动
ps aux | grep task_executor | grep -v grep
```

### 步骤 3: 重新解析文档

在 Web 界面中：
1. 进入知识库
2. 找到失败的文档
3. 点击"重新解析"按钮

## 正确的启动流程

### 完整初始化（首次部署）

```bash
# 1. 安装 Python 依赖
uv sync --python 3.12 --all-extras

# 2. 下载模型文件（重要！）
uv run download_deps.py

# 3. 安装 pre-commit hooks
pre-commit install

# 4. 启动依赖服务
docker compose -f docker/docker-compose-base.yml up -d

# 5. 配置 hosts（开发环境）
# 添加到 /etc/hosts:
# 127.0.0.1  es01 infinity mysql minio redis sandbox-executor-manager

# 6. 启动后端服务
bash docker/launch_backend_service.sh
```

### 日常启动（已初始化）

```bash
# 方式 1: 使用快捷脚本（推荐）
./start_dev.sh

# 方式 2: 使用官方脚本
bash docker/launch_backend_service.sh
```

### ❌ 错误的启动方式

```bash
# 不要单独运行 ragflow_server.py
python api/ragflow_server.py  # ❌ 缺少 task_executor
```

## RAGFlow 架构说明

### 双进程模型

RAGFlow 后端由两个独立进程组成：

1. **ragflow_server.py** - API 服务器
   - 处理 HTTP 请求
   - 提供 Web 界面接口
   - 接收文件上传
   - 端口: 9380

2. **task_executor.py** - 任务执行器
   - 处理后台任务
   - 文档解析、分块
   - 生成嵌入向量
   - 索引到 Elasticsearch

### 通信机制

- 两个进程通过 **Redis 队列** 通信
- ragflow_server 将任务放入队列
- task_executor 从队列取出任务并处理
- 使用 Redis 分布式锁协调

### 文档处理流程

```
用户上传文档
    ↓
ragflow_server 接收
    ↓
创建任务 → Redis 队列
    ↓
task_executor 取出任务
    ↓
选择解析器（根据文档类型）
    ↓
文档解析 + 分块
    ↓
生成嵌入向量
    ↓
存储到 Elasticsearch
    ↓
更新文档状态
```

## 模型文件说明

### DeepDOC 模型文件位置

```
rag/res/deepdoc/
├── det.onnx                      # 文本检测模型 (4.5 MB)
├── rec.onnx                      # 文本识别模型 (10.3 MB)
├── layout.onnx                   # 布局分析模型 (72.2 MB)
├── layout.laws.onnx              # 法律文档布局 (72.2 MB)
├── layout.manual.onnx            # 手册布局 (72.2 MB)
├── layout.paper.onnx             # 论文布局 (72.2 MB)
├── tsr.onnx                      # 表格结构识别 (11.7 MB)
├── updown_concat_xgb.model       # XGBoost 模型 (5.6 MB) ⭐ 必需
└── left_right_concat_xgb.model   # XGBoost 模型（可选）
```

### 下载来源

- **ONNX 模型**: HuggingFace `InfiniFlow/deepdoc`
- **XGBoost 模型**: HuggingFace `InfiniFlow/text_concat_xgb_v1.0`

### 手动下载（如果 download_deps.py 失败）

```bash
cd rag/res/deepdoc

# 使用国内镜像
curl -L -o updown_concat_xgb.model \
  "https://hf-mirror.com/InfiniFlow/text_concat_xgb_v1.0/resolve/main/updown_concat_xgb.model"

# 或使用官方地址（可能较慢）
curl -L -o updown_concat_xgb.model \
  "https://huggingface.co/InfiniFlow/text_concat_xgb_v1.0/resolve/main/updown_concat_xgb.model"
```

## 常见问题排查

### 1. 文档解析失败

**检查清单**:
```bash
# 1. 检查 task_executor 是否运行
ps aux | grep task_executor | grep -v grep

# 2. 检查模型文件是否存在
ls -lh rag/res/deepdoc/updown_concat_xgb.model

# 3. 查看错误日志
tail -100 /tmp/task_executor.log | grep ERROR

# 4. 检查 Elasticsearch 连接
curl -u elastic:infini_rag_flow http://localhost:1200/_cluster/health
```

### 2. Elasticsearch 索引不存在

**原因**: task_executor 未运行或任务未被处理

**解决**:
```bash
# 启动 task_executor
bash docker/launch_backend_service.sh

# 在 Web 界面重新解析文档
```

### 3. Redis 连接失败

**检查**:
```bash
# 检查 Redis 容器
docker ps | grep redis

# 测试连接
docker exec docker-redis-1 redis-cli -a infini_rag_flow ping
```

## 监控和调试

### 查看实时日志

```bash
# task_executor 日志
tail -f /tmp/task_executor.log | grep -E "ERROR|progress|Finished"

# ragflow_server 日志（如果在前台运行）
# 直接在终端查看输出
```

### 检查任务队列

```bash
# 查看 Redis 队列长度
docker exec docker-redis-1 redis-cli -a infinw \
  LLEN rag_flow_svr_queue
```

### 检查 Elasticsearch 索引

```bash
# 列出所有索引
curl -u elastic:infini_rag_flow \
  "http://localhost:1200/_cat/indices?v"

# 查看特定索引的文档数量
curl -u elastic:infini_rag_flow \
  "http://localhost:1200/ragflow_YOUR_KB_ID/_count"
```

## 性能优化

### 多 Worker 配置

如果服务器性能较好，可以启动多个 task_executor：

```bash
# 设置 worker 数量
export WS=4  # 启动 4 个 worker

# 启动服务
bash docker/launch_backend_service.sh
```

### 批处理参数

在 `docker/.env` 中调整：

```bash
# 批量处理文档数（默认 4）
DOC_BULK_SIZE=8

# 嵌入批次大小（默认 16）
EMBEDDING_BATCH_SIZE=32

# 线程池大小（默认 128）
THREAD_POOL_MAX_WORKERS=256
```

## 相关文件

- **启动脚本**: `docker/launch_backend_service.sh`
- **快捷脚本**: `start_dev.sh`
- **配置文件**: `docker/.env`, `docker/service_conf.yaml.template`
- **依赖下载**: `download_deps.py`
- **开发文档**: `CLAUDE_cn.md`

## 总结

RAGFlow 的文档处理需要：
1. ✅ ragflow_server.py（API 服务器）
2. ✅ task_executor.py（任务执行器）
3. ✅ DeepDOC 模型文件（用于 PDF 解析）
4. ✅ 依赖服务（MySQL、Redis、Elasticsearch、MinIO）

**记住**: 永远使用 `launch_backend_service.sh` 或 `start_dev.sh` 启动服务！

---
创建时间: 2026-02-01
最后更新: 2026-02-01
