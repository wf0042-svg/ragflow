# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 项目概述

RAGFlow 是一个基于深度文档理解的开源 RAG（检索增强生成）引擎。这是一个全栈应用，包含：
- Python 后端（基于 Flask 的 API 服务器）
- React/TypeScript 前端（使用 Vite 构建）
- 微服务架构，支持 Docker 部署
- 多种数据存储（MySQL、Elasticsearch/Infinity/OceanBase、Redis、MinIO）

## 核心架构

### 后端架构 (`/api/`)

**主服务器启动流程：**
- **入口点**: `api/ragflow_server.py` - Flask 应用主入口
  - 初始化数据库表和数据
  - 启动后台进度更新线程
  - 注册所有 Flask blueprints
  - 支持 debugpy 远程调试（通过 `RAGFLOW_DEBUGPY_LISTEN` 环境变量）

- **任务执行器**: `rag/svr/task_executor.py` - 异步任务处理
  - 处理文档解析、分块、嵌入等后台任务
  - 支持多个 worker 进程（通过 `WS` 环境变量控制）
  - 使用 Redis 分布式锁协调任务

**Flask Blueprints 组织** (`api/apps/`):
- `kb_app.py` - 知识库管理
- `dialog_app.py` - 对话/聊天处理
- `document_app.py` - 文档处理
- `canvas_app.py` - Agent 工作流画布
- `file_app.py` - 文件上传/管理
- `conversation_app.py` - 会话管理
- `llm_app.py` - LLM 模型配置
- `user_app.py` / `tenant_app.py` - 用户和租户管理

所有 blueprints 自动注册，URL 前缀为 `/v1/{page_name}` 或 `/api/v1` (SDK)。

**认证机制：**
- 使用 JWT token 或 API token 进行认证
- `@login_required` 装饰器保护需要认证的路由
- Session 存储在 Redis 中

**服务层** (`api/db/services/`):
- 业务逻辑与数据库操作分离
- 每个服务对应一个数据模型或业务领域
- 使用 Peewee ORM 进行数据库操作

**数据模型** (`api/db/db_models.py`):
- 使用 Peewee ORM 定义
- 支持多种数据库后端（MySQL、PostgreSQL、OceanBase）
- `TextFieldType` 枚举处理不同数据库的文本字段类型差异

### RAG 核心处理 (`/rag/`)

**文档解析工厂模式** (`rag/app/`):
```python
FACTORY = {
    "general": naive,
    ParserType.PAPER.value: paper,
    ParserType.BOOK.value: book,
    ParserType.PRESENTATION.value: presentation,
    ParserType.MANUAL.value: manual,
    ParserType.LAWS.value: laws,
    ParserType.QA.value: qa,
    ParserType.TABLE.value: table,
    ParserType.RESUME.value: resume,
    ParserType.PICTURE.value: picture,
    ParserType.AUDIO.value: audio,
    ParserType.EMAIL.value: email,
    # ...
}
```
每种文档类型有专门的解析器，处理特定格式的文档结构。

**文档处理流程：**
- `deepdoc/` - PDF 解析、OCR、布局分析
- `rag/flow/` - 分块、解析、分词
- `rag/nlp/` - NLP 处理（分词、搜索、位置标注）
- `rar/` - 递归摘要和树状组织检索

**LLM 集成** (`rag/llm/`):
- 统一的模型抽象层，支持多种 LLM 提供商
- 支持聊天、嵌入、重排序等功能
- 配置在 `docker/service_conf.yaml.template` 中

**Graph RAG** (`rag/graphrag/`):
- 知识图谱构建和查询
- 使用 LLM 进行实体和关系提取
- 支持 PageRank 和标签传播算法

### Agent 系统 (`/agent/`)

**组件化架构** (`agent/component/`):
- `base.py` - 所有组件的基类
- `llm.py` - LLM 调用组件
- `begin.py` - 工作流起始节点
- `categorize.py` - 分类组件
- `invoke.py` - 子工作流调用
- `loop.py` / `iteration.py` - 循环控制
- `message.py` - 消息处理
- `agent_with_tools.py` - 带工具的 Agent

**预构建模板** (`agent/templates/`):
- 24+ 个预构建的 Agent 工作流模板
- JSON 格式定义工作流结户服务、深度研究、SEO 博客生成、SQL 助手等

**工具集成** (`agent/tools/`):
- 外部 API 集成（Tavily、Wikipedia、DuckDuckGo）
- SQL 执行、Excel 处理、数据操作
- 支持自定义工具插件

**插件系统** (`agent/plugin/`):
- 全局插件管理器
- 支持动态加载和卸载插件

### 前端架构 (`/web/`)

**技术栈：**
- React 18 + TypeScript
- Vite 构建工具（从 UmiJS 迁移）
- Ant Design + shadcn/ui 组件库
- Tailwind CSS 样式
- Zustand 状态管理
- React Query (TanStack Query) 数据获取
- React Router v7 路由
- @xyflow/react 用于工作流画布

**关键依赖：**
- `@monaco-editor/react` - 代码编辑器
- `react-markdown` - Markdown 渲染
- `@antv/g6` - 图可视化
- `lexical` - 富文本编辑器

## 常用开发命令

### 后端开发

```bash
# 安装 Python 依赖
uv sync --python 3.12 --all-extras
uv run download_deps.py
pre-commit install

# 启动依赖服务（MySQL、Redis、MinIO、Elasticsearch）
docker compose -f docker/docker-compose-base.yml up -d

# 配置 hosts（开发环境需要）
# 添加到 /etc/hosts:
# 127.0.0.1  es01 infinity mysql minio redis sandbox-executor-manager

# 启动后端服务
source .venv/bin/activate
export PYTHONPATH=$(pwd)
bash docker/launch_backend_service.sh

# 运行测试
uv run pytest                    # 运行所有测试
uv run pytest -m p1              # 只运行高优先级测试
uv run pytest test/test_xxx.py   # 运行单个测试文件
uv run pytest -k test_function   # 运行特定测试函数

# 代码检查和格式化
ruff check                       # 检查代码问题
ruff format                      # 格式化代码
ruff check --fix                 # 自动修复问题

# 停止后端服务
pkill -f "ragflow_server.py|task_executor.py"
```

**环境变量配置：**
- `WS` - task_executor worker 数量（默认 1）
- `RAGFLOW_DEBUGPY_LISTEN` - debugpy 调试端口（默认 0，禁用）
- `HF_ENDPOINT` - HuggingFace 镜像站点（如 https://hf-mirror.com）

### 前端开发

```bash
cd web
npm install                      # 安装依赖
npm run dev                      # 开发服务器（默认端口 8001）
npm run build                    # 生产构建
npm run preview                  # 预览生产构建
npm run lint                     # ESLint 检查
npm r test                     # Jest 测试
```

### Docker 开发

```bash
# 完整栈 Docker 部署
cd docker
docker compose -f docker-compose.yml up -d

# 查看服务状态
docker logs -f ragflow-server

# 停止并清理（警告：会删除数据）
docker compose down -v

# 重建镜像
docker build --platform linux/amd64 -f Dockerfile -t infiniflow/ragflow:nightly .

# 使用代理构建
docker build --platform linux/amd64 \
  --build-arg http_proxy=http://YOUR_PROXY:PORT \
  --build-arg https_proxy=http://YOUR_PROXY:PORT \
  -f Dockerfile -t infiniflow/ragflow:nightly .
```

## 关键配置文件

### Docker 配置
- `docker/.env` - 环境变量配置
  - `DOC_ENGINE` - 文档引擎选择（elasticsearch/infinity/oceanbase/opensearch/seekdb）
  - `DEVICE` - 推理设备（cpu/gpu）
  - `MYSQL_PASSWORD`, `REDIS_PASSWORD`, `MINIO_PASSWORD` - 数据库密码
  - `SVR_HTTP_PORT` - RAGFlow HTTP 端口（默认 9380）
  - `RAGFLOW_IMAGE` - Docker 镜像版本
  - `REGISTER_ENABLED` - 用户注册开关（1/0）
  - `SANDBOX_ENABLED` - 代码沙箱开关

- `docker/service_conf.yaml.template` - 后端服务配置
  - LLM 模型配置（API keys、endpoints）
  - 数据库连接配置
  - 支持环境变量替换 `${ENV_VAR}`

- `docker/docker-compose.yml` - 服务编排
- `docker/docker-compose-base.yml` - 基础服务（开发用）

### Python 配置
- `pyproject.toml` - Python 项目配置
  - 依赖管理
  - pytest 配置（markers: p1/p2/p3）
  - ruff 配置（line-length: 200）
  - coverage 配置

### 前端配置
- `web/package.json` - 前端依赖和脚本
- `web/vite.config.ts` - Vite 构建配置
- `web/tailwind.config.js` - Tailwind CSS 配置

## 测试

### Python 测试
```bash
# pytest 配置在 pyproject.toml 中
# 测试优先级标记：
# @pytest.mark.p1 - 高优先级（核心功能）
# @pytest.mark.p2 - 中优先级
# @pytest.mark.p3 - 低优先级

# 运行特定优先级
uv run pytest -m p1

# 并行测试
uv run pytest -n auto

# 生成覆盖率报告
uv run pytest --cov --cov-report=html
```

**测试位置：**
- `test/` - HTTP API 测试
- `sdk/python/test/` - Python SDK 测试
- `agent/sandbox/tests试

### 前端测试
```bash
cd web
npm run test                     # Jest 测试
npm run test -- --coverage       # 带覆盖率
```

## 数据库引擎切换

RAGFlow 支持多种文档存储引擎：

### 切换到 Infinity
```bash
# 1. 停止所有容器
docker compose -f docker/docker-compose.yml down -v

# 2. 修改 docker/.env
DOC_ENGINE=infinity

# 3. 重启
docker compose -f docker/docker-compose.yml up -d
```

### 切换到 OceanBase
```bash
# 修改 docker/.env
DOC_ENGINE=oceanbase
OCEANBASE_PASSWORD=your_password

# 重启容器
docker compose down -v && docker compose up -d
```

**注意：** 切换引擎会清空现有数据（使用 `-v` 标志）。

## 开发环境要求

- **Python**: 3.10-3.12（推荐 3.12）
- **Node.js**: >=18.20.4
- **Docker**: >=24.0.0
- **Docker Compose**: >=v2.26.1
- **uv**: Python 包管理器
- **系统要求**:
  - CPU >= 4 核
  - RAM >= 16 GB
  - 磁盘 >= 50 GB
  - `vm.max_map_count` >= 262144（Elasticsearch 需要）

### macOS 特殊配置
```bash
# 安装 jemalloc
brew install jemalloc

# 在 docker/.env 中取消注释
# MACOS=1
```

### 系统配置
```bash
# 检查 vm.max_map_count
sysctl vm.max_map_count

# 临时设置
sudo sysctl -w vm.max_map_count=262144

# 永久设置（添加到 /etc/sysctl.conf）
vm.max_map_count=262144
```

## 架构要点

### 双进程架构
RAGFlow 后端运行两类进程：
1. **ragflow_server.py** - Flask API 服务器，处理 HTTP 请求
2. **task_executor.py** - 后台任务执行器，处理文档解析、嵌入等耗时任务

两者通过 Redis 队列通信，使用分布式锁协调。

### 文档处理管道
1. 文件上传 → MinIO 存储
2. 创建文档记录 → MySQL
3. 任务入队 → Redis
4. task_executor 处理：
   - 根据文档类型选择解析器（FACTORY）
   - 文档解析和分块
   - 生成嵌入向量
   - 存储到文档引擎（ES/Infinity/OceanBase）
5. 更新文档状态和进度

### Agent 工作流执行
1. 用户创建/加载 Agent 模板
2. Canvas 画布编辑工作流（前端）
3. 保存为 JSON 配置
4. 运行时：
   - 从 begin 组件开始
   - 按照连接关系执行组件
   - 支持条件分支、循环、子工作流调用
   - 组件间通过变量传递数据

### 前端状态管理
- Zustand stores 管理全局状态
- React Query 管理服务器状态和缓存
- 本地状态使用 React hooks

## 代码风格约定

### Python
- 使用f 进行 linting 和格式化
- 行长度限制：200 字符
- 使用 pre-commit hooks 自动检查
- 遵循 PEP 8，但有项目特定调整

### TypeScript/React
- 使用 ESLint + Prettier
- 组件使用函数式组件 + hooks
- 优先使用 TypeScript 类型而非 any
- CSS 使用 Tailwind utility classes

## 常见开发任务

### 添加新的文档解析器
1. 在 `rag/app/` 创建新的解析器模块
2. 在 `common/constants.py` 添加 `ParserType` 枚举
3. 在 `rag/svr/task_executor.py` 的 `FACTORY` 中注册
4. 实现 `chunk()` 方法返回文档块列表

### 添加新的 Agent 组件
1. 在 `agent/component/` 创建组件类
2. 继承 `ComponentBase`
3. 实现 `_run()` 方法
4. 在前端 `web/src/pages/flow/` 添加 UI 配置

### 添加新的 API 端点
1. 在 `api/apps/` 相应的 app 文件中添加路由
2. 使用 `@manager.route()` 装饰器
3. 需要认证的路由添加 `@login_required`
4. 返回使用 `get_json_result()` 统一格式

### 添加新的 LLM 提供商
1. 在 `rag/llm/` 创建新的模型类
2. 实现聊天、嵌入等接口
3. 在 `docker/service_conf.yaml.template` 添加配置
4. 在前端 LLM 配置页面添加 UI

## 调试技巧

### 后端调试
```bash
# 启用 debugpy 远程调试
export RAGFLOW_DEBUGPY_LISTEN=5678
bash docker/launch_backend_service.sh

# 在 IDE 中连接到 localhost:5678
```

### 查看日志
```bash
# Docker 日志
docker logs -f ragflow-server

# 本地开发日志
# 日志输出到 stdout，使用 LOG_LEVELS 环境变量控制级别
export LOG_LEVELS=ragflow.es_conn=DEBUG
```

### 数据库调试
```bash
# 连接到 MySQL
docker exec -it mysql mysql -uroot -pinfini_ragow

# 连接到 Redis
docker exec -it redis redis-cli -a infini_rag_flow

# 查看 Elasticsearch 索引
curl -u elastic:infini_rag_flow http://localhost:1200/_cat/indices
```

## 性能优化配置

- `DOC_BULK_SIZE` - 批量处理文档数（默认 4）
- `EMBEDDING_BATCH_SIZE` - 嵌入批次大小（默认 16）
- `THREAD_POOL_MAX_WORKERS` - 线程池大小（默认 128）
- `WS` - task_executor worker 数量

根据服务器资源调整这些参数以优化性能。
