# RAGFlow 技术栈

## 后端技术栈

- **语言**: Python 3.12+（要求 >=3.12, <3.15）
- **Web 框架**: Flask/Quart（支持异步）
- **包管理器**: uv（现代 Python 依赖管理工具）
- **核心库**:
  - 文档处理: pdfplumber, pypdf, python-docx, python-pptx, mammoth
  - OCR 与视觉: opencv-python, onnxruntime（x86_64 支持 GPU）
  - LLM 集成: openai, anthropic, google-generativeai, ollama, mistralai, cohere, groq
  - 向量/搜索: elasticsearch-dsl, infinity-sdk, opensearch-py
  - 存储: minio, opendal
  - 智能体框架: agentrun-sdk, mcp（模型上下文协议）
  - 网页抓取: Crawl4AI, selenium-wire

## 前端技术栈

- **语言**: TypeScript
- **框架**: React 18
- **构建工具**: Vite
- **UI 库**: 
  - Ant Design (@ant-design/pro-components)
  - Radix UI（无头组件）
  - Tailwind CSS
- **状态管理**: Zustand, React Query (@tanstack/react-query)
- **路由**: React Router v7
- **可视化**: @antv/g2, @antv/g6, recharts
- **代码编辑器**: Monaco Editor
- **Markdown**: react-markdown, @uiw/react-markdown-preview

## 基础设施与服务

- **数据库**: MySQL
- **搜索引擎**: Elasticsearch 或 Infinity（通过 DOC_ENGINE 配置）
- **缓存**: Redis/Valkey
- **对象存储**: MinIO
- **容器化**: Docker & Docker Compose

## 开发工具

- **代码检查/格式化**: 
  - Python: ruff（代码检查和格式化）
  - TypeScript: ESLint, Prettier
- **Pre-commit 钩子**: pre-commit 框架
- **测试**: 
  - Python: pytest（包含 pytest-asyncio, pytest-xdist, pytest-cov）
  - 前端: Jest, React Testing Library

## 常用命令

### 后端开发

```bash
# 设置环境
uv sync --python 3.12 --all-extras
uv run download_deps.py
pre-commit install

# 启动依赖服务
docker compose -f docker/docker-compose-base.yml up -d

# 运行后端服务器
source .venv/bin/activate
export PYTHONPATH=$(pwd)
bash docker/launch_backend_service.sh

# 运行测试
uv run pytest
uv run pytest test/test_api.py  # 运行特定测试

# 代码检查
ruff check
ruff format
```

### 前端开发

```bash
# 安装依赖
cd web
npm install

# 开发服务器（运行在 8000 端口）
npm run dev

# 生产构建
npm run build

# 运行测试
npm run test

# 代码检查
npm run lint
```

### Docker 部署

```bash
# 完整技术栈
cd docker
docker compose -f docker-compose.yml up -d

# 仅基础服务
docker compose -f docker-compose-base.yml up -d

# 构建自定义镜像
docker build --platform linux/amd64 -f Dockerfile -t infiniflow/ragflow:nightly .
```

### Pre-commit

```bash
pre-commit install
pre-commit run --all-files
```

## 环境配置

- **后端**: `docker/.env` 和 `docker/service_conf.yaml.template`
- **前端**: Vite 配置中的环境变量
- **Docker**: `docker/docker-compose.yml`

## 平台说明

- Docker 镜像为 x86_64 平台构建
- ARM64 平台需要自定义构建 Docker 镜像
- DeepDoc 任务支持 GPU（在 .env 中设置 DEVICE=gpu）
- x86_64 Linux 使用 onnxruntime-gpu，macOS/ARM64 使用 onnxruntime
