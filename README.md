# Agent Stack

个人 Agent 工程环境的能力索引与配置快照，覆盖 Codex、Hermes 等 Agent 运行时、活动 Skills、Codex 插件、模型上下文协议（Model Context Protocol，MCP）服务、命令行工具和全局工作规范。

这是脱敏的只读快照，不是一键安装配置；公开内容可用于理解环境结构和工具选型，但不能直接重建本机环境。

| 快照日期 | Codex 个人 Skills | Hermes Skills | 插件包 | 已启用插件 | MCP 服务 |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 2026-08-02 | 43 | 104 | 21 | 12 | 7 |

> [!NOTE]
> 盘点时区为 Asia/Shanghai。本文只记录配置结构、工具名称和版本，不记录令牌、密钥、服务地址参数或其他敏感值。

## 导航

- [状态边界与环境结构](#状态边界与环境结构)
- [Codex 个人 Skills](#codex-个人-skills)
- [Hermes Agent](#hermes-agent)
- [Codex 插件](#codex-插件)
- [MCP 服务](#mcp-服务)
- [本地工具链](#本地工具链)
- [全局 AGENTS.md](#全局-agentsmd)
- [更新环境快照](#更新环境快照)

## 状态边界与环境结构

当前环境分为五层，每层对应一种配置职责：

| 层级 | 位置 | 内容 |
| --- | --- | --- |
| 全局规范 | `~/.codex/AGENTS.md` | 指令优先级、变更安全、工具路由、安全审查和验证方式 |
| Codex 个人 Skills | `~/.agents/skills`、`~/.codex/skills` | 43 个个人 Skills |
| Hermes Agent | `~/.local/bin/hermes`、`~/.hermes/skills` | Hermes Agent v0.19.1 与 104 个活动 Skills |
| 插件与 MCP | `~/.codex/plugins`、`~/.codex/config.toml` | 21 个插件包与 7 个 MCP 服务入口 |
| 本地工具链 | 当前 shell 的 `PATH` | 搜索、代码分析、安全扫描、运行时和协作工具 |

本文严格区分以下四种状态：

| 状态 | 判定依据 |
| --- | --- |
| 本机已缓存 | 插件包存在于 `~/.codex/plugins/cache`。 |
| 配置中已登记 | 插件或 MCP 服务存在于 `~/.codex/config.toml` 的对应顶层配置。 |
| 明确启用 | 插件配置明确设置 `enabled = true`；显式禁用的 MCP 服务单独标注。 |
| 当前会话已暴露 | 对应工具在当前 Codex 会话中可用；该状态不由缓存或配置单独决定。 |

“已缓存”不等于“已启用”，“配置中已登记”也不等于工具已暴露给当前会话。

动态数量、Agent 版本、插件版本与状态、MCP 状态、工具版本和全局规范哈希记录在 [`snapshot/environment.json`](snapshot/environment.json)；Codex 个人 Skills 来源与内容摘要记录在 [`snapshot/skills.json`](snapshot/skills.json)，Hermes 活动 Skills 清单记录在 [`snapshot/hermes-skills.json`](snapshot/hermes-skills.json)，稳定分组与用途记录在 [`snapshot/catalog.json`](snapshot/catalog.json)。

## Codex 个人 Skills

本机共有 43 个 Codex 个人 skill。以下清单按使用场景分组，不包含 Codex 系统 skills、插件内部 skills 或 Hermes 活动 skills，也不重复计算跨目录安装。

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
| `generate-agent-stack-readme` | 本地目录 `~/.codex/skills/generate-agent-stack-readme` | 盘点 Codex、Hermes 等实时环境，更新结构化快照并生成和验证 README。 |
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
| `humanizer` | [`blader/humanizer`](https://github.com/blader/humanizer) | 已安装，公开用途待补充。 |
| `humanizer-zh` | [`op7418/Humanizer-zh`](https://github.com/op7418/Humanizer-zh) | 已安装，公开用途待补充。 |
| `napi-rs` | [`lzm0x219/skills`](https://github.com/lzm0x219/skills) | 已安装，公开用途待补充。 |
| `pnpm` | [`antfu/skills`](https://github.com/antfu/skills) | 已安装，公开用途待补充。 |
| `rust-skills` | 本地目录 `~/.agents/skills/rust-skills` | 已安装，公开用途待补充。 |
| `skillopt-sleep` | 本地目录 `~/.codex/skills/skillopt-sleep` | 已安装，公开用途待补充。 |
| `tsdown` | [`antfu/skills`](https://github.com/antfu/skills) | 已安装，公开用途待补充。 |
| `turborepo` | [`antfu/skills`](https://github.com/antfu/skills) | 已安装，公开用途待补充。 |
| `typescript-advanced-types` | 本地目录 `~/.agents/skills/typescript-advanced-types` | 已安装，公开用途待补充。 |
| `typescript-pro` | 本地目录 `~/.agents/skills/typescript-pro` | 已安装，公开用途待补充。 |
| `vite` | [`antfu/skills`](https://github.com/antfu/skills) | 已安装，公开用途待补充。 |
| `vitest` | [`antfu/skills`](https://github.com/antfu/skills) | 已安装，公开用途待补充。 |

### Skills 内容摘要

安装内容证据记录在 [`snapshot/skills.json`](snapshot/skills.json)：35 个 lock 管理的 Skills 保存 lock 中的 `skillFolderHash`、来源标识和上游路径；8 个本地 Skills 保存按相对路径排序后的文件 SHA-256 树摘要。`skillFolderHash` 不代表上游 Git commit，也不能单独证明本地目录未被修改。

## Hermes Agent

当前 shell 解析到的 `hermes` 为 Hermes Agent v0.19.1。Hermes 的运行时和活动 Skills 与 Codex 个人 Skills 分开统计：

| 字段 | 值 |
| --- | --- |
| 命令 | `hermes` |
| 版本 | 0.19.1 |
| 构建 | 2026.7.30 |
| 上游修订 | `e9d52d2b` |
| 安装方式 | git |
| 安装目录 | `~/.hermes/hermes-agent` |
| 活动 Skills 根目录 | `~/.hermes/skills` |
| 活动 Skills | 104 |

只统计 `~/.hermes/skills` 中的活动 `SKILL.md`；同名 Skill 按名称去重，保留按路径排序后的首项。Hermes 安装源码树、`optional-skills`、`node_modules`、`venv` 和插件源码内的 bundled Skills 不计入，避免与活动目录重复。

### Hermes Skills 分类

| 分类 | 数量 |
| --- | ---: |
| `apple` | 4 |
| `autonomous-ai-agents` | 5 |
| `creative` | 17 |
| `data-science` | 1 |
| `email` | 1 |
| `github` | 6 |
| `media` | 4 |
| `mlops` | 7 |
| `note-taking` | 2 |
| `productivity` | 15 |
| `research` | 11 |
| `root`（根级） | 13 |
| `smart-home` | 1 |
| `social-media` | 1 |
| `software-development` | 16 |

所有 104 个 Skill 的名称、分类、脱敏路径和文件树 SHA-256 记录在 [`snapshot/hermes-skills.json`](snapshot/hermes-skills.json)。

## Codex 插件

插件缓存中共有 21 个包。Codex 配置显式启用了其中 12 个，其余 9 个仅在本机缓存中存在。

### 配置中显式启用

| 插件 | 版本 | 能力 |
| --- | --- | --- |
| `browser` | 26.727.51351 | 控制 Codex 应用内浏览器，适合本地页面导航、交互与截图。 |
| `chrome` | 26.727.51351 | 用途待补充。 |
| `computer-use` | 1.0.1000550 | 通过 Computer Use 操作 macOS 桌面应用。 |
| `context-mode` | 1.0.169 | 压缩高输出命令、文件和页面内容，仅把检索或分析结果带入会话。 |
| `context7` | 1.0.1 | 查询版本相关的库文档与代码示例。 |
| `documents` | 26.801.11242 | 创建、编辑和验证 Word/Google Docs 文档。 |
| `pdf` | 26.801.11242 | 读取、创建、渲染并验证 PDF。 |
| `presentations` | 26.801.11242 | 创建、编辑、渲染和导出演示文稿。 |
| `sites` | 0.1.33 | 构建与托管网站。 |
| `spreadsheets` | 26.801.11242 | 创建、分析、可视化并导出电子表格。 |
| `template-creator` | 26.801.11242 | 从文档、演示或表格创建个人制品模板 skill。 |
| `visualize` | 1.0.16 | 创建交互式图表、地图、图示、模拟器和数据探索器。 |

### 本机缓存的其他插件

这些插件包存在于缓存中，但当前 `config.toml` 没有将其列入显式启用清单：

| 插件 | 版本 | 能力 |
| --- | --- | --- |
| `app-69ef18c674308191a2f952431f91ea61`（Context7） | 1.0.0 | Upstash 发布的 Context7 应用连接器缓存包。 |
| `codex-security` | 0.1.15 | 安全扫描、攻击路径分析、验证与漏洞报告工作流。 |
| `data-analytics` | 0.2.8-13ceeea1f599 | 产品和业务数据分析、KPI、报告与仪表盘。 |
| `expo` | 1.0.2 | 用途待补充。 |
| `figma` | 2.0.16 | Figma 设计实现、Code Connect 与设计系统工作流。 |
| `github` | 0.1.8-2841cf9749ae | 仓库、PR、issue、CI 与发布协作。 |
| `hugging-face` | 1.0.0 | 模型、数据集、Spaces、训练任务和研究工作流。 |
| `openai-developers` | 1.2.3 | OpenAI API、Agents SDK 与 ChatGPT Apps 开发。 |
| `openai-templates` | 0.1.1 | OpenAI 默认文档、演示和表格模板。 |

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
| 工具链管理 | `Homebrew` (`brew`) | 6.0.14-20-g2b7c468 |
| 工具链管理 | `mise` | 2026.7.18 |
| Agent 编程 CLI | `codex` | 0.146.0 |
| Agent 编程 CLI | `opencode` | 1.18.10 |
| Agent 编程 CLI | `hermes` | 0.19.1 |
| Agent 命令代理 | `rtk` | 0.44.1 |
| 文本搜索 | `ripgrep` (`rg`) | 15.2.0 |
| AST 搜索/改写 | `ast-grep` / `sg` | 0.45.0 |
| 代码关系理解 | `codegraph` | 1.5.0 |
| 安全扫描 | `opengrep` | 1.25.0 |
| 供应链签名验证 | `cosign` | 无法读取（退出码 1） |
| 链接检查 | `lychee` | 0.24.2 |
| JSON 处理 | `jq` | 1.7.1-apple |
| 文件树查看 | `tree` | 2.3.2 |
| 文件监视 | `watchman` | 2026.07.27.00 |
| 数据库 CLI | `sqlite3` | 3.51.0 |
| JavaScript 运行时 | `node` | 24.18.1 |
| JS 运行时与包管理 | `npm` / `pnpm` / `bun` / `corepack` | 12.0.2 / 11.13.0 / 1.3.14 / 0.35.0 |
| Java | `java` | 17.0.19 |
| Rust | `rustc` / `cargo` | 1.97.1 / 1.97.1 |
| Python | `python3` | 3.14.6 |
| Python 项目工具 | `uv` | 0.12.0 |
| Ruby | `ruby` | 4.0.5 |
| Apple 平台依赖管理 | `CocoaPods` (`pod`) | 1.17.0 |
| Apple 开发工具链 | `Xcode` / `swift` / `clang` | 无法读取（退出码 64） / 6.3.3 / 21.0.0 |
| 媒体处理 | `ffmpeg` | 无法读取（退出码 8） |
| 字体处理 | `fonttools` / `LCDF TypeTools` (`otftotfm`) | 无法读取（退出码 1） / 2.110 |
| 压缩工具 | `gzip` | 1.14 |
| macOS 维护 | `mole` | 无法读取（退出码 0） |
| Shell | `zsh` / `starship` | 5.9.2 / 1.26.0 |
| 版本控制 | `git` | 2.55.0 |
| GitHub CLI | `gh` | 2.97.0 |
| 协作者清单 | `all-contributors` | 6.26.1 |
| 凭据输入 | `pinentry-mac` | 1.3.1.1 |

这些工具的默认路由是：关系理解优先 CodeGraph（仅当仓库已有 `.codegraph/`），结构化搜索和 codemod 使用 ast-grep，普通文本与配置搜索使用 ripgrep，安全相关审查使用 Opengrep，供应链签名验证使用 Cosign，链接检查使用 Lychee。第三方 skill、插件或 MCP 安装前应使用 SkillSpector；当前 shell 未解析到该 CLI，相关安装任务应停止并说明缺口。

## 全局 AGENTS.md

### 规则摘要

- 默认中文，代码、命令、标识符和原始报错保留原文。
- 输出简洁。
- 修改前保护无关变更，专用能力优先，并以源码、配置、版本和可复现测试验证结论。

### 完整副本与来源哈希

全局规范位于 `~/.codex/AGENTS.md`。下面是截至快照日期与本机源文件逐字同步的副本；源文件变化后应同时更新本节和哈希。

源文件 SHA-256：`0ef6f85900b784c6b127f46342a9de9e7cab7b23260962d1bbbe0c29a9ca7db8`

<details>
<summary><strong>展开全局工作规范</strong></summary>

````md
# Global Agent Rules
- 默认中文，代码、命令、标识符和原始报错保留原文。
- 输出简洁。

## Writing polish

- 面向用户交付自然语言文字前，先按段落或片段判断语言：中文使用 `humanizer-zh` Skill，英文使用 `humanizer` Skill；中英混合内容分别处理。其他语言没有匹配 Skill 时，不要假装完成了对应语言的润色。
- 把选定的 Skill 作为最后一道内部审阅步骤运行。默认只输出审阅后的最终文字，不展示草稿、审计清单或调用过程；用户明确要求查看这些内容时例外。
- 保留原意、事实、技术准确性、证据、限定条件、安全警告和用户要求的语气。不得编造、删除或改动事实、数字、日期、名称、引文或链接目标，也不要为了“像真人”给技术、法律、医疗、安全或操作性文本强行加入个性或情绪。
- 不改写代码块、命令、标识符、文件路径、URL、引文、原始报错、机器可读数据或用户要求逐字保留的内容；只润色其外层说明文字。
- 若用户要求摘要、压缩或改变格式，先遵守用户要求，再在允许改写的自然语言范围内使用对应 Skill。

## Capability routing

- Use specialized tools only when they materially improve correctness or evidence.
- For version-sensitive APIs, use authoritative versioned documentation.
- For security work, validate scanner findings against source before reporting them
  as confirmed vulnerabilities.

<!-- rtk-instructions -->
# RTK (Rust Token Killer) - Token-Optimized Commands

When running shell commands, **always prefix with `rtk`**. This reduces context
usage by 60-90% with zero behavior change. If rtk has no filter for a command,
it passes through unchanged — so it is always safe to use.

## Key Commands
```bash
# Git (59-80% savings)
rtk git status          rtk git diff            rtk git log

# Files & Search (60-75% savings)
rtk ls <path>           rtk read <file>         rtk grep <pattern>
rtk find <pattern>      rtk diff <file>

# Test (90-99% savings) — shows failures only
rtk pytest tests/       rtk cargo test          rtk test <cmd>

# Build & Lint (80-90% savings) — shows errors only
rtk tsc                 rtk lint                rtk cargo build
rtk prettier --check    rtk mypy                rtk ruff check

# Analysis (70-90% savings)
rtk err <cmd>           rtk log <file>          rtk json <file>
rtk summary <cmd>       rtk deps                rtk env

# GitHub (26-87% savings)
rtk gh pr view <n>      rtk gh run list         rtk gh issue list

# Infrastructure (85% savings)
rtk docker ps           rtk kubectl get         rtk docker logs <c>

# Package managers (70-90% savings)
rtk pip list            rtk pnpm install        rtk npm run <script>
```

## Rules
- In command chains, prefix each segment: `rtk git add . && rtk git commit -m "msg"`
- For debugging, use raw command without rtk prefix
- `rtk proxy <cmd>` runs command without filtering but tracks usage
<!-- /rtk-instructions -->

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->
````

</details>

## 更新环境快照

环境变化后，必须先运行 `./scripts/check-snapshot.sh` 识别数量、动态环境清单、Skills 内容摘要或全局规范摘要的漂移。脚本只读，使用本快照已列出的 `jq` 与系统命令，不安装或引入项目依赖。

以下只读命令用于人工复核完整环境；检查输出后再更新本文与 `snapshot/`：

- 盘点 `~/.agents/skills`、`~/.codex/skills`、`~/.hermes/skills`、插件缓存和配置顶层节。
- 核对 `hermes --version`、活动 Skills 清单与内容摘要。
- 运行 `./scripts/check-snapshot.sh`、`git diff --check`，确认数量、版本、状态、哈希和文档链接一致。
- 只提交脱敏的 `README.md`、`snapshot/` 和必要的校验逻辑；不要把快照当作配置备份或安装器。
