# Agent Stack

个人 Agent 工程环境的能力索引与配置快照，覆盖 Codex、OpenCode、Grok、Hermes 等 Agent 运行时、活动 Skills、Codex 插件、模型上下文协议（Model Context Protocol，MCP）服务、命令行工具和全局工作规范。

这是脱敏的只读快照，不是一键安装配置；公开内容可用于理解环境结构和工具选型，但不能直接重建本机环境。

| 快照日期 | Codex 个人 Skills | Grok Skills | 插件包 | 已启用插件 | MCP 服务 | Hermes Skills |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 2026-09-07 | 56 | 3 | 29 | 17 | 7 | 84 |

> [!NOTE]
> 盘点时区为 Asia/Shanghai。本文只记录配置结构、工具名称和版本，不记录令牌、密钥、服务地址参数或其他敏感值。

## 导航

- [状态边界与环境结构](#状态边界与环境结构)
- [Codex 个人 Skills](#codex-个人-skills)
- [其他 Agent 运行时](#其他-agent-运行时)
- [Codex 插件](#codex-插件)
- [MCP 服务](#mcp-服务)
- [本地工具链](#本地工具链)
- [全局 AGENTS.md](#全局-agentsmd)
- [更新环境快照](#更新环境快照)

## 状态边界与环境结构

当前环境分为五层，每层对应一种配置职责：

| 层级 | 位置 | 内容 |
| --- | --- | --- |
| 全局规范 | `~/.codex/AGENTS.md` | 指令优先级、工具路由、安全审查和验证方式 |
| Codex 个人 Skills | `~/.agents/skills`、`~/.codex/skills` | 56 个个人 Skills |
| 其他 Agent 运行时 | `opencode`、`grok`、`hermes` | Grok 有 3 个、Hermes 有 84 个活动 Skills |
| 插件与 MCP | `~/.codex/plugins`、`~/.codex/config.toml` | 29 个插件包与 7 个 MCP 服务入口 |
| 本地工具链 | 当前 shell 的 `PATH` | 搜索、代码分析、安全扫描、运行时和协作工具 |

本文严格区分以下四种状态：

| 状态 | 判定依据 |
| --- | --- |
| 本机已缓存 | 插件包存在于 `~/.codex/plugins/cache`。 |
| 配置中已登记 | 插件或 MCP 服务存在于 `~/.codex/config.toml` 的对应顶层配置。 |
| 明确启用 | 插件配置明确设置 `enabled = true`；显式禁用的 MCP 服务单独标注。 |
| 当前会话已暴露 | 对应工具在当前 Codex 会话中可用；该状态不由缓存或配置单独决定。 |

“已缓存”不等于“已启用”，“配置中已登记”也不等于工具已暴露给当前会话。

动态数量、Agent 版本、插件版本与状态、MCP 状态、工具版本和全局规范哈希记录在 [`snapshot/environment.json`](snapshot/environment.json)；Codex 个人 Skills 来源与内容摘要记录在 [`snapshot/skills.json`](snapshot/skills.json)，Grok 与 Hermes 活动 Skills 清单分别记录在 [`snapshot/grok-skills.json`](snapshot/grok-skills.json) 和 [`snapshot/hermes-skills.json`](snapshot/hermes-skills.json)，稳定分组与用途记录在 [`snapshot/catalog.json`](snapshot/catalog.json)。

## Codex 个人 Skills

本机共有 56 个 Codex 个人 skill。以下清单按使用场景分组，不包含 Codex 系统 skills、插件内部 skills 或 Grok、Hermes 活动 skills，也不重复计算跨目录安装。

### 工程工作流 Skills

| Skill | 来源 | 用途 |
| --- | --- | --- |
| `ask-matt` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 根据当前问题选择合适的 skill 或工作流。 |
| `code-review` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 从固定基点审查代码变更，同时检查仓库规范与需求符合度。 |
| `codebase-design` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 用深模块、接口、接缝和适配器等统一词汇设计代码结构。 |
| `diagnosing-bugs` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 用可复现反馈循环诊断复杂缺陷与性能回退。 |
| `domain-modeling` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 建立领域术语、统一语言与架构决策。 |
| `implement` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 根据规格或 tickets 实现工作，并要求持续验证和最终审查。 |
| `improve-codebase-architecture` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 扫描架构摩擦点，产出可视化报告并讨论改进机会。 |
| `playwright` | 本地目录 `~/.codex/skills/playwright` | 通过 Playwright CLI 自动化真实浏览器，用于导航、表单、截图、数据提取和 UI 流程调试。 |
| `prototype` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 构建一次性逻辑或 UI 原型，用运行结果回答设计问题。 |
| `resolving-merge-conflicts` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 理解双方意图、解决 merge/rebase 冲突并完成验证。 |
| `setup-matt-pocock-skills` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 为工程 skills 初始化 issue tracker、标签和领域文档布局。 |
| `tdd` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 按 red → green → refactor 循环进行测试驱动开发。 |

### 规划、研究与协作 Skills

| Skill | 来源 | 用途 |
| --- | --- | --- |
| `grill-me` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 通过持续访谈把计划或设计中的决策问清楚。 |
| `grill-with-docs` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 在访谈过程中同步沉淀 ADR 与领域词汇。 |
| `grilling` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 提供逐项压力测试计划和设计的底层访谈流程。 |
| `handoff` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 将当前上下文压缩成可供下一位 Agent 接手的交接文档。 |
| `research` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 基于高可信一手资料研究问题，并把结论写入仓库。 |
| `to-spec` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 将已有对话整理为规格，并发布到项目 issue tracker。 |
| `to-tickets` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 把规格拆成带阻塞关系的纵向切片 tickets。 |
| `triage` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 按状态机对 issues 和外部 PR 进行分类、核实和任务化。 |
| `wayfinder` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 把跨多个 Agent 会话的大型工作拆成调查地图并逐项消除不确定性。 |

### 设计、写作与学习 Skills

| Skill | 来源 | 用途 |
| --- | --- | --- |
| `find-skills` | [`vercel-labs/skills`](https://github.com/vercel-labs/skills) | 发现可能满足需求的可安装 skills。 |
| `frontend-design` | [`anthropics/skills`](https://github.com/anthropics/skills) | 指导具有明确视觉方向的前端设计，避免模板化默认风格。 |
| `generate-agent-stack-readme` | 本地目录 `~/.codex/skills/generate-agent-stack-readme` | 盘点 Codex、Grok 等实时环境，更新结构化快照并生成和验证 README。 |
| `teach` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 在工作区内建立持续性的课程、参考资料与学习记录。 |
| `web-design-guidelines` | [`vercel-labs/agent-skills`](https://github.com/vercel-labs/agent-skills) | 按 Web Interface Guidelines 审查 UI、UX 与可访问性。 |
| `writing-great-skills` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 提供编写稳定、可预测 Agent Skill 的方法与词汇。 |
| `writing-guidelines` | [`vercel-labs/agent-skills`](https://github.com/vercel-labs/agent-skills) | 按 Writing Guidelines 审查文档的表达、语气与结构。 |

### 专项 Skill

| Skill | 来源 | 用途 |
| --- | --- | --- |
| `hatch-pet` | 本地目录 `~/.codex/skills/hatch-pet` | 创建、修复、验证和打包 Codex v2 动画宠物及其 spritesheet。 |

### 其他已安装 Skills

| Skill | 来源 | 用途 |
| --- | --- | --- |
| `archify` | [`tt-a1i/archify`](https://github.com/tt-a1i/archify) | 已安装，公开用途待补充。 |
| `dsa-design` | 本地目录 `~/.agents/skills/dsa-design` | 已安装，公开用途待补充。 |
| `git-guardrails-claude-code` | 本地目录 `~/.codex/skills/git-guardrails-claude-code` | 已安装，公开用途待补充。 |
| `humanizer` | [`blader/humanizer`](https://github.com/blader/humanizer) | 已安装，公开用途待补充。 |
| `humanizer-zh` | [`op7418/Humanizer-zh`](https://github.com/op7418/Humanizer-zh) | 已安装，公开用途待补充。 |
| `migrate-to-shoehorn` | 本地目录 `~/.codex/skills/migrate-to-shoehorn` | 已安装，公开用途待补充。 |
| `napi-rs` | [`lzm0x219/skills`](https://github.com/lzm0x219/skills) | 已安装，公开用途待补充。 |
| `pnpm` | [`antfu/skills`](https://github.com/antfu/skills) | 已安装，公开用途待补充。 |
| `rust-skills` | 本地目录 `~/.agents/skills/rust-skills` | 已安装，公开用途待补充。 |
| `scaffold-exercises` | 本地目录 `~/.codex/skills/scaffold-exercises` | 已安装，公开用途待补充。 |
| `setup-pre-commit` | 本地目录 `~/.codex/skills/setup-pre-commit` | 已安装，公开用途待补充。 |
| `skillopt-sleep` | 本地目录 `~/.codex/skills/skillopt-sleep` | 已安装，公开用途待补充。 |
| `to-questionnaire` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 已安装，公开用途待补充。 |
| `tsdown` | [`antfu/skills`](https://github.com/antfu/skills) | 已安装，公开用途待补充。 |
| `turborepo` | [`antfu/skills`](https://github.com/antfu/skills) | 已安装，公开用途待补充。 |
| `typescript-advanced-types` | 本地目录 `~/.agents/skills/typescript-advanced-types` | 已安装，公开用途待补充。 |
| `typescript-pro` | 本地目录 `~/.agents/skills/typescript-pro` | 已安装，公开用途待补充。 |
| `vite` | [`antfu/skills`](https://github.com/antfu/skills) | 已安装，公开用途待补充。 |
| `vitest` | [`antfu/skills`](https://github.com/antfu/skills) | 已安装，公开用途待补充。 |
| `wait-what` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 已安装，公开用途待补充。 |
| `wizard` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 已安装，公开用途待补充。 |
| `writing-for-agents` | [`mattpocock/skills`](https://github.com/mattpocock/skills) | 已安装，公开用途待补充。 |
| `bootstrap-project` | [`lzm0x219/skills`](https://github.com/lzm0x219/skills) | 已安装，公开用途待补充。 |
| `durable-execution-state` | 本地目录 `~/.codex/skills/durable-execution-state` | 已安装，公开用途待补充。 |
| `ecommerce-helper` | 本地目录 `~/.codex/skills/ecommerce-helper` | 已安装，公开用途待补充。 |
| `ip-as-logo` | [`s1dashu/ip-as-logo-skill`](https://github.com/s1dashu/ip-as-logo-skill) | 已安装，公开用途待补充。 |
| `zig` | [`lzm0x219/skills`](https://github.com/lzm0x219/skills) | 已安装，公开用途待补充。 |

### Skills 内容摘要

安装内容证据记录在 [`snapshot/skills.json`](snapshot/skills.json)：42 个 lock 管理的 Skills 保存 lock 中的 `skillFolderHash`、来源标识和上游路径；14 个本地 Skills 保存按相对路径排序后的文件 SHA-256 树摘要。`skillFolderHash` 不代表上游 Git commit，也不能单独证明本地目录未被修改。

## 其他 Agent 运行时

Codex 之外，当前 shell 还解析到 OpenCode、Grok CLI 与 Hermes Agent。运行时版本与活动 Skills 分开记录：

| 运行时 | 命令 | 版本 | 活动 Skills | 快照 |
| --- | --- | --- | ---: | --- |
| OpenCode | `opencode` | 1.18.29 | 未登记根目录 | — |
| Grok CLI | `grok` | 1.0.13 | 3 | [`snapshot/grok-skills.json`](snapshot/grok-skills.json) |
| Hermes Agent | `hermes` | 0.20.5 | 84 | [`snapshot/hermes-skills.json`](snapshot/hermes-skills.json) |

### Grok CLI 与活动 Skills

| 字段 | 值 |
| --- | --- |
| 命令 | `grok` |
| 版本 | 1.0.13 |
| 修订 | `5e9a58528b76` |
| 安装方式 | user-local symlink |
| 安装目录 | `~/.grok` |
| 活动 Skills 根目录 | `~/.grok/skills` |
| 活动 Skills | 3 |

只统计 `~/.grok/skills` 中的活动 `SKILL.md`；Grok 自带的 bundled Skills、插件缓存和其他非活动目录不计入。当前 3 个活动 Skill 都位于根级分类：`archify`、`find-skills`、`napi-rs`。名称、脱敏路径和文件树 SHA-256 记录在 [`snapshot/grok-skills.json`](snapshot/grok-skills.json)。

### Hermes Agent 与活动 Skills

| 字段 | 值 |
| --- | --- |
| 命令 | `hermes` |
| 版本 | 0.20.5 |
| 修订 | `791e2ae3` |
| 安装方式 | git |
| 安装目录 | `~/.hermes/hermes-agent` |
| 活动 Skills 根目录 | `~/.hermes/skills` |
| 活动 Skills | 84 |

只统计 `~/.hermes/skills` 中的活动 `SKILL.md`，按名称去重；源码树、optional-skills、依赖目录和插件 bundled Skills 不计入。完整名称、脱敏路径和文件树 SHA-256 见 [`snapshot/hermes-skills.json`](snapshot/hermes-skills.json)。

| 分类 | Skills |
| --- | ---: |
| `apple` | 4 |
| `autonomous-ai-agents` | 5 |
| `creative` | 16 |
| `devops` | 1 |
| `email` | 2 |
| `github` | 7 |
| `media` | 3 |
| `mlops` | 5 |
| `note-taking` | 1 |
| `productivity` | 17 |
| `research` | 7 |
| `root` | 3 |
| `smart-home` | 1 |
| `social-media` | 1 |
| `software-development` | 11 |

命令别名 `agent` 指向同一个 Grok 可执行文件，`hermes-acp` 属于 Hermes 协议入口，均不重复计为独立运行时。`coder` 指向的 Hermes profile 不存在，未计入活动运行时。

## Codex 插件

插件缓存中共有 29 个包。Codex 配置显式启用了其中 17 个，其余 12 个仅在本机缓存中存在。

### 配置中显式启用

| 插件 | 版本 | 能力 |
| --- | --- | --- |
| `browser` | 26.901.51231 | 控制 Codex 应用内浏览器，适合本地页面导航、交互与截图。 |
| `chrome` | 26.901.51231 | 用途待补充。 |
| `codex-app-tools` | 0.1.3 | 用途待补充。 |
| `computer-use` | 1.0.1000926 | 通过 Computer Use 操作 macOS 桌面应用。 |
| `context-mode` | 1.0.169 | 压缩高输出命令、文件和页面内容，仅把检索或分析结果带入会话。 |
| `context7` | 1.0.1 | 查询版本相关的库文档与代码示例。 |
| `diagram-design` | 2.6.12 | 用途待补充。 |
| `documents` | 26.904.11930 | 创建、编辑和验证 Word/Google Docs 文档。 |
| `nowledge-mem` | 0.1.32 | 提供跨工具的工作记忆、检索、任务保存与知识沉淀。 |
| `pdf` | 26.904.11930 | 读取、创建、渲染并验证 PDF。 |
| `presentations` | 26.904.11930 | 创建、编辑、渲染和导出演示文稿。 |
| `record-and-replay` | 1.0.1000926 | 录制并重放 macOS 操作流程，用于生成可复用自动化。 |
| `sites` | 0.1.57 | 构建与托管网站。 |
| `spreadsheets` | 26.904.11930 | 创建、分析、可视化并导出电子表格。 |
| `template-creator` | 26.904.11930 | 从文档、演示或表格创建个人制品模板 skill。 |
| `unified-computer-use` | 26.901.51231 | 用途待补充。 |
| `visualize` | 1.0.29 | 创建交互式图表、地图、图示、模拟器和数据探索器。 |

### 本机缓存的其他插件

这些插件包存在于缓存中，但当前 `config.toml` 没有将其列入显式启用清单：

| 插件 | 版本 | 能力 |
| --- | --- | --- |
| `app-69ef18c674308191a2f952431f91ea61`（Context7） | 1.0.0 | Upstash 发布的 Context7 应用连接器缓存包。 |
| `codex-security` | 0.1.23 | 安全扫描、攻击路径分析、验证与漏洞报告工作流。 |
| `data-analytics` | 0.2.10-13ceeea1f599 | 产品和业务数据分析、KPI、报告与仪表盘。 |
| `deep-research-work` | 0.1.14 | 用途待补充。 |
| `dev-6a7185f70da88191ac274b67d3a6bd57` | 1.0.0 | 用途待补充。 |
| `expo` | 1.0.2 | 用途待补充。 |
| `figma` | 2.0.21 | Figma 设计实现、Code Connect 与设计系统工作流。 |
| `github` | 0.1.12-5f7cd798dc99 | 仓库、PR、issue、CI 与发布协作。 |
| `hugging-face` | 1.0.0 | 模型、数据集、Spaces、训练任务和研究工作流。 |
| `openai-developers` | 1.2.3 | OpenAI API、Agents SDK 与 ChatGPT Apps 开发。 |
| `openai-templates` | 0.1.1 | OpenAI 默认文档、演示和表格模板。 |
| `plugin-management` | 0.1.0 | 用途待补充。 |

插件来源以快照中的 `source` 字段为准。当前配置显式启用的插件与仅缓存的插件分开列出；插件包存在不代表已启用，也不代表当前会话一定暴露对应工具。

## MCP 服务

`~/.codex/config.toml` 配置了 7 个 MCP 服务入口：

| 服务 | 状态/用途 |
| --- | --- |
| `astro-docs` | 已配置，未显式设置启用状态；用途待补充。 |
| `codegraph` | 已配置，未显式设置启用状态；为已有 `.codegraph/` 索引的仓库提供符号关系与调用路径查询。 |
| `computer-use` | 已配置但显式禁用；同名插件仍处于启用状态，两者是不同配置层。 |
| `node_repl` | 已配置，未显式设置启用状态；提供受控 Node.js REPL 与相关运行时能力。 |
| `openaiDeveloperDocs` | 已配置，未显式设置启用状态；用途待补充。 |
| `pencil` | 已配置，未显式设置启用状态；用途待补充。 |
| `serena` | 已配置，未显式设置启用状态；用途待补充。 |

此外，当前 Codex 会话还可以按需暴露应用连接器和插件工具。应区分本机已缓存、配置文件已登记、明确启用和当前会话已暴露，四者并不必然相同。

## 本地工具链

以下版本来自当前登录 shell 中实际解析到的可执行文件及其版本输出，并同步记录在 [`snapshot/environment.json`](snapshot/environment.json)。只记录当前生效的 CLI；桌面应用、字体、没有独立命令的 shell 插件，以及 mise 中未激活的旧版本不计入本表。

| 类别 | 工具 | 版本/说明 |
| --- | --- | --- |
| 工具链管理 | `Homebrew` (`brew`) | 6.0.22-69-g6a16270 |
| 工具链管理 | `mise` | 2026.9.1 |
| Agent 编程 CLI | `codex` | 0.153.4 |
| Agent 编程 CLI | `opencode` | 1.18.29 |
| Agent 编程 CLI | `grok` | 1.0.13 |
| Agent 编程 CLI | `hermes` | 0.20.5 |
| Agent 命令代理 | `rtk` | 0.48.0 |
| 文本搜索 | `ripgrep` (`rg`) | 15.2.0 |
| 语义搜索 | `zg` | 0.2.1 |
| AST 搜索/改写 | `ast-grep` / `sg` | 0.45.3 |
| 代码关系理解 | `codegraph` | 1.6.0 |
| 安全扫描 | `opengrep` | 1.25.0 |
| 供应链签名验证 | `cosign` | 无法读取（退出码 1） |
| 链接检查 | `lychee` | 0.24.2 |
| JSON 处理 | `jq` | 1.7.1-apple |
| 文件树查看 | `tree` | 2.3.2 |
| 文件监视 | `watchman` | 2026.07.27.00 |
| 数据库 CLI | `sqlite3` | 3.51.0 |
| JavaScript 运行时 | `node` | 26.7.0 |
| JS 运行时与包管理 | `npm` / `pnpm` / `bun` / `corepack` | 11.19.0 / 12.3.4 / 1.4.2 / 0.35.0 |
| Java | `java` | 17.0.20.1 |
| Rust | `rustc` / `cargo` | 1.98.1 / 1.98.1 |
| Python | `python3` | 3.14.7 |
| Python 项目工具 | `uv` | 0.12.10 |
| Ruby | `ruby` | 2.6.10p210 |
| Apple 平台依赖管理 | `CocoaPods` (`pod`) | 1.17.0 |
| Apple 开发工具链 | `Xcode` / `swift` / `clang` | 无法读取（退出码 64） / 6.3.3 / 21.0.0 |
| 媒体处理 | `ffmpeg` | 无法读取（退出码 8） |
| 字体处理 | `fonttools` / `LCDF TypeTools` (`otftotfm`) | 无法读取（退出码 1） / 2.110 |
| 压缩工具 | `gzip` | 1.14 |
| macOS 维护 | `mole` | 1.53.0 |
| Shell | `zsh` / `starship` | 5.9.2 / 1.26.0 |
| 版本控制 | `git` | 2.55.0 |
| GitHub CLI | `gh` | 2.100.0 |
| 协作者清单 | `all-contributors` | 6.26.1 |
| 凭据输入 | `pinentry-mac` | 1.3.1.1 |

关系理解仅在仓库已有 `.codegraph/` 时优先使用 CodeGraph；已知文本和标识符用 ripgrep，不确定措辞的语义发现用已有且就绪的 `zg` 索引。结构化搜索和 codemod 可用 ast-grep，安全扫描、签名验证和链接检查分别对应 Opengrep、Cosign 与 Lychee。

上表统一记录 `--version` 的读取结果；Cosign、Xcode、FFmpeg 与 fonttools 在该参数下返回非零退出码，不能据此判断工具不可用。

## 全局 AGENTS.md

### 规则摘要

- 默认中文，保留代码、命令、标识符和原始报错；先说结果。
- 在授权范围内完成工作，遵守只读与等待执行等明确边界；专用能力以改善正确性和证据为准。
- shell 命令通过 RTK 路由；已有代码索引用 CodeGraph，语义搜索先检查 `zg` 就绪状态。
- 验证覆盖改动行为与项目必需检查，通过后只因新修改、失败或未解决疑点扩大检查。

### 完整副本与来源哈希

全局规范位于 `~/.codex/AGENTS.md`。下面是截至快照日期与本机源文件逐字同步的副本；源文件变化后应同时更新本节和哈希。

源文件 SHA-256：`374579d0f0a5d7e354601f6250a678b1f93504a1ef8b4b4096f1b106ec085ac2`

<details>
<summary><strong>展开全局工作规范</strong></summary>

````md
# Global Agent Rules

- 默认中文，代码、命令、标识符和原始报错保留原文。先说结果，简洁说明必要依据。
- 用户当前明确要求优先于本文件和 Skill 的默认流程；遵守系统、开发者指令和宿主权限限制。
- 在已授权范围内完成工作，复用已有授权；仅当缺失信息会实质改变结果且无法合理推断时提问。准备工作可独立推进时继续。
- 只读、规划、等待“执行”等明确边界持续有效。发送消息、发布、部署、合并、破坏性操作或扩大访问范围，须有覆盖该动作的授权。
- Skill 导致暂停或偏离请求时，指出文件、原句和适用原因；区分真实授权要求与默认工作流程。

## Capability routing

- 仅在专用工具或 Skill 能改善正确性、证据或交付时使用；按任务分支读取 references。
- 版本敏感的 API 使用匹配版本的权威文档；安全扫描发现经源码验证后才能称为已确认漏洞。
- 委派须符合当前请求和适用指令，且子任务可独立验收；明确文件责任、共享约束和完成条件。
- 验证覆盖改动行为和项目必需检查；通过后，仅因新修改、失败或未解决疑点扩大或重复检查。

<!-- rtk-instructions -->
## RTK

- Shell 命令使用 `rtk` 前缀，命令链每段分别加前缀。
- 需要原始、完整或可机器解析的输出时使用 `rtk proxy <cmd>`；仅为诊断 RTK 本身的问题直接运行原始命令。
- 命令发现或 RTK 异常处理时读取 [RTK reference](references/rtk.md)。
<!-- /rtk-instructions -->

<!-- CODEGRAPH_START -->
## CodeGraph

- 仓库根目录存在 `.codegraph/` 时，代码定位或调用路径问题先用 `codegraph_explore` 或 `rtk proxy codegraph explore "<question>"`，再做宽范围文本搜索或读取。
- 需要当前行号时读取具体文件或符号；没有 `.codegraph/` 则跳过，不隐式创建索引。
<!-- CODEGRAPH_END -->

<!-- ZVEC_GREP_START -->
## Workspace search

- 已知文本、标识符、路径、正则和穷尽核验使用 `rg`；机器解析或要求完整输出时用 `rtk proxy rg`。
- 不确定措辞或位置的语义发现使用已有 `zg` 索引；代码定位与调用路径仍先遵循 CodeGraph 规则。
- 索引搜索前运行 `rtk zg status --check-ready`；未就绪则回退 `rg`。只在用户要求或任务包含搜索配置时创建或重建索引。
- 排名结果只作线索，关键结论用当前源码或 `rg` 核验。需要版本特定语法时查 `rtk zg help query`、`index` 或 `models`。
<!-- ZVEC_GREP_END -->
````

</details>

## 更新环境快照

环境变化后，必须先运行 `./scripts/check-snapshot.sh` 识别数量、动态环境清单、Skills 内容摘要或全局规范摘要的漂移。脚本只读，使用本快照已列出的 `jq`、`python3` 与系统命令，不安装或引入项目依赖。

以下只读命令用于人工复核完整环境；检查输出后再更新本文与 `snapshot/`：

- 盘点 `~/.agents/skills`、`~/.codex/skills`、catalog 所列其他 Agent Skills 根目录、插件缓存和配置顶层节。
- 核对各 Agent CLI 的 `--version` 输出、活动 Skills 清单与内容摘要；已确认移除的运行时不得沿用旧数据。
- 运行 `./scripts/check-snapshot.sh`、`git diff --check`，确认数量、版本、状态、哈希和文档链接一致。
- 只提交脱敏的 `README.md`、`snapshot/` 和必要的校验逻辑；不要把快照当作配置备份或安装器。
