# RAGFlow 项目结构

## 根目录布局

```
ragflow/
├── api/              # 后端 API 服务器
├── rag/              # 核心 RAG 逻辑
├── deepdoc/          # 文档解析和 OCR
├── agent/            # 智能体推理组件
├── graphrag/         # 基于图的 RAG
├── web/              # 前端应用
├── docker/           # Docker 部署配置
├── sdk/              # Python SDK
├── test/             # 后端测试
├── admin/            # 管理服务器和 CLI 客户端
├── mcp/              # 模型上下文协议服务器
└── intergrations/    # 第三方集成
```

## 后端结构

### api/ - API 服务器
- `apps/`: 按功能组织的 API Blueprints
  - 知识库管理
  - 聊天/对话处理
  - 文档管理
  - 用户认证
- `db/`: 数据库模型和服务
  - ORM 模型（Peewee）
  - 业务逻辑服务层
  - 数据库迁移

### rag/ - RAG 核心逻辑
- `llm/`: LLM、Embedding 和 Rerank 模型抽象
  - 提供商集成（OpenAI、Anthropic、Google 等）
  - 模型工厂模式
  - 嵌入和重排序服务
- 检索和索引逻辑
- 查询处理和优化

### deepdoc/ - 文档处理
- 各种格式的文档解析模块
- OCR 和视觉处理
- 文本提取和分块
- 基于模板的文档理解

### agent/ - 智能体框架
- 智能体推理组件
- 工具定义和执行器
- 智能体工作流编排
- 记忆管理

### graphrag/ - 图 RAG
- 基于图的检索逻辑
- 知识图谱构建
- 图查询处理

## 前端结构

### web/ - React 应用
```
web/
├── src/
│   ├── assets/       # 静态资源（图片、字体）
│   ├── components/   # 可复用的 React 组件
│   ├── pages/        # 页面级组件
│   ├── hooks/        # 自定义 React hooks
│   ├── utils/        # 工具函数
│   ├── services/     # API 服务层
│   ├── stores/       # 状态管理（Zustand）
│   ├── locales/      # 国际化翻译
│   └── styles/       # 全局样式
├── public/           # 公共静态文件
└── package.json      # 前端依赖
```

## 基础设施

### docker/ - 部署配置
- `docker-compose.yml`: 完整技术栈部署
- `docker-compose-base.yml`: 仅基础服务（MySQL、ES、Redis、MinIO）
- `.env`: 环境变量
- `service_conf.yaml.template`: 后端服务配置
- `launch_backend_service.sh`: 后端启动脚本

### admin/ - 管理模块
- `server/`: 管理 API 服务器
  - 认证和授权
  - 用户管理
  - 系统配置
- `client/`: 管理操作的 CLI 客户端
  - API 交互的 HTTP 客户端
  - 命令行界面

### sdk/ - Python SDK
- `python/ragflow_sdk/`: RAGFlow API 的 Python SDK
  - 编程访问的客户端库
  - API 包装器和工具

### mcp/ - 模型上下文协议
- `server/`: MCP 服务器实现
  - 协议处理器
  - 上下文管理

## 配置文件

- `pyproject.toml`: Python 项目元数据和依赖（uv）
- `.python-version`: Python 版本规范
- `.pre-commit-config.yaml`: Pre-commit 钩子配置
- `.gitignore`: Git 忽略模式
- `Dockerfile*`: 各种 Docker 构建配置
- `LICENSE`: Apache 2.0 许可证
- `README*.md`: 多语言文档

## 测试结构

### test/ - 后端测试
- API 端点的单元测试
- 服务的集成测试
- 测试夹具和工具
- pyproject.toml 中的覆盖率配置

### web/ - 前端测试
- 使用 Jest 和 React Testing Library 的组件测试
- package.json 中的测试配置

## 关键约定

- **后端**: 
  - Python 模块按功能/领域组织
  - 业务逻辑使用服务层模式
  - API 路由使用 Blueprint 模式
- **前端**: 
  - 基于组件的架构
  - 按功能组织
  - 使用 Hooks 实现可复用逻辑
- **配置**: 
  - 基于环境的配置
  - 服务配置使用模板文件
  - 使用 Docker Compose 进行编排
