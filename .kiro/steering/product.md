# RAGFlow 产品概述

RAGFlow 是一个开源的 RAG（检索增强生成）引擎，结合深度文档理解和智能体能力，为大语言模型创建优质的上下文层。

## 核心价值主张

- 深度文档理解，从复杂非结构化数据格式中提取知识
- 基于模板的智能分块，支持人工参与的可视化调整
- 可追溯的引用来源，减少幻觉问题
- 适用于任何规模企业的自动化 RAG 工作流
- 融合的上下文引擎，提供预构建的智能体模板

## 核心能力

- 支持多种格式的文档解析和 OCR（PDF、Word、Excel、PPT、图片、扫描件、网页）
- 多模态模型支持，理解文档中的图像内容
- 智能体工作流，集成 MCP（模型上下文协议）
- AI 智能体的记忆支持
- 跨语言查询支持
- 可编排的数据摄取管道
- 多源数据同步（Confluence、S3、Notion、Discord、Google Drive）

## 架构

全栈应用，采用微服务架构：
- Python 后端（Flask/Quart）处理 API 和 RAG 逻辑
- React/TypeScript 前端用户界面
- 基于 Docker 的部署，依赖服务包括 MySQL、Elasticsearch/Infinity、Redis、MinIO
- 支持 Elasticsearch 和 Infinity 两种文档引擎

## 目标用户

需要高保真文档理解和检索能力的开发者和企业，用于构建生产级 AI 系统。
