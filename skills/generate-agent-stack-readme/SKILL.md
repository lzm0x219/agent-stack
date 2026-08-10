---
name: generate-agent-stack-readme
description: 仅在用户显式调用时，盘点 agent-stack 当前本机的 Codex、Grok 等 Agent 运行时及其活动 Skills，读取配置中的非敏感事实，更新 snapshot/ 并生成完整 README.md。适用于刷新 Agent CLI、Skills、Codex 插件、MCP 服务、本地工具链、全局工作规范和快照日期，或在环境变化后同步仓库快照与 README。
---

# 刷新 Agent Stack 快照与 README

先以只读方式盘点当前本机环境，再更新仓库内的公开结构化快照，最后依据新快照生成 README。默认更新仓库根目录的 `README.md`；用户指定其他 Markdown 文件时，仍先更新 `snapshot/`，然后只把生成文档写入指定文件。

不要安装、升级、删除或启用 Skill、插件、MCP 服务、依赖或本地工具。只读取完成公开盘点所需的字段，不输出或保存秘密。

## 1. 确认范围与基线

1. 读取仓库级 `AGENTS.md`，遵循其中的统计口径、敏感信息边界和验证要求。
2. 检查工作树，区分用户已有变更与本次变更；不得覆盖、丢弃、重排或纳入无关改动。
3. 读取现有 `README.md`、`snapshot/*.json`、`snapshot/catalog.json` 和 `scripts/check-snapshot.sh`，保留仍然有效的说明、分组、链接和顺序。
4. 先运行 `./scripts/check-snapshot.sh` 识别漂移。初次失败可以是待修复的快照漂移，但不能据此猜测新值。
5. 只有完成全部盘点后才更新快照日期；日期使用 `Asia/Shanghai` 时区。

如果必要路径、解析工具或事实来源缺失，停止更新受影响的事实和日期，报告缺口，不用缓存、当前会话能力或记忆补全。

## 2. 盘点实时环境

所有盘点命令保持只读。大输出先在工具侧过滤，只把允许公开的字段带入会话。

### Codex 个人 Skills

- 统计 `~/.agents/skills` 与 `~/.codex/skills` 下的个人 `SKILL.md`。
- 排除 `~/.codex/skills/.system` 和插件包内的 Skills；按 Skill 名称去重，重复安装只计一次。
- 从 `~/.agents/.skill-lock.json` 只读取版本号及每个 Skill 的 `source`、`skillPath`、`skillFolderHash`。
- 对未由 lock 管理的本地 Skill，记录脱敏后的 `~/...` 路径，并计算按相对路径排序的文件 SHA-256 树摘要。
- 不读取第三方 Skill 的自由文本来推导用途、质量或上游归属；展示名称和用途优先沿用 `snapshot/catalog.json`。

### 其他 Agent 运行时与活动 Skills

- 从 `snapshot/catalog.json` 的 `agentRuntimes` 读取各运行时的命令、活动 Skills 根目录和快照文件，不把旧快照中的运行时当作仍然活动。
- 使用当前 shell 的 `command -v` 与对应的 `--version` 记录当前生效的公开版本、修订、安装方式和脱敏后的安装目录；字段以该运行时实际能够确认的公开元数据为准。
- 只统计 catalog 所列活动 Skills 根目录下的 `SKILL.md`，按 Skill 名称去重，并按相对路径首段分组；根级 Skill 归入 `root`。
- 不把运行时自带的 bundled Skills、插件缓存、源码树、`optional-skills`、`node_modules` 或 `venv` 计为活动 Skills，避免与活动目录重复。
- 为每个活动 Skill 记录名称、分类、脱敏路径和按相对路径排序的文件 SHA-256 树摘要，不读取自由文本推导用途。
- 将各运行时的活动 Skills 与 Codex 个人 Skills 分开统计和展示，不合并数量。
- 如果用户确认某个已登记运行时已被移除，删除其 catalog 条目、工具清单项和过期 Skills 快照，再以仍然活动的运行时重建结构化快照；不得沿用已移除运行时的旧版本或数量。

### Codex 插件

- 从 `~/.codex/plugins/cache` 中实际存在的 `.codex-plugin/plugin.json` 统计缓存包。
- 只提取公开的插件标识、版本和来源类别，不复制清单中的命令、参数、环境或服务地址。
- 只把 `~/.codex/config.toml` 中对应插件顶层配置明确设置 `enabled = true` 的条目标记为已启用。
- 始终区分本机已缓存、配置中已登记、明确启用和当前会话已暴露；当前会话暴露不能反推配置状态。

### MCP 服务

- 只统计 `~/.codex/config.toml` 顶层 `[mcp_servers.<name>]` 配置，并读取显式启用或禁用状态。
- 不把 `.env` 等子表重复计数，不读取或输出 `command`、`args`、环境变量值、令牌或带参数的 URL。
- 服务用途优先沿用 `snapshot/catalog.json`；新服务缺少公开用途时标记为待补充，不从命令参数猜测。

### 本地工具链

- 先盘点 `snapshot/catalog.json` 的 `agentRuntimes`，再以 `toolGroups` 为通用工具清单；不得因为命令未在旧版 `toolGroups` 中就忽略已确认的 Agent 运行时。
- 使用当前 shell 中 `command -v` 解析到的可信可执行文件及其 `--version` 输出；记录当前生效版本或明确的读取失败状态。
- 不把桌面应用、无独立命令的 shell 插件、未激活的旧运行时或缓存包计为当前工具。
- 不执行安装、升级、登录、签名、发布、清理或会改变环境状态的命令。
- 对 `~/.local/bin` 等已解析到 Agent CLI 的可信用户级目录做只读名称检查；发现未登记的 Agent 候选时先核实其公开版本与 Skills 根目录，再更新 `agentRuntimes`，不得静默漏过。

### 全局工作规范与日期

- 读取 `~/.codex/AGENTS.md`，将其完整公开副本写入 README 的折叠区块，并计算源文件 SHA-256。
- 使用 `Asia/Shanghai` 的当前日期更新快照日期；不要使用模型记忆中的日期。

### 配置读取安全

- 不直接输出完整 `~/.codex/config.toml`。使用只返回顶层节名和非敏感状态字段的解析或搜索方式。
- 对所有配置输出采用字段白名单；遇到意外的密钥、令牌、凭据、环境变量值或带参数地址时立即停止传播并脱敏。
- 只把公开事实写入仓库：名称、来源类别、版本、启用或禁用状态、用途、数量和哈希语义。

## 3. 更新结构化快照

先完成完整盘点，再修改 `snapshot/`：

1. 重新生成 `snapshot/skills.json`，保持现有 schema、稳定排序和哈希语义。
2. 为 catalog 中声明了 `skillsSnapshot` 的其他 Agent 运行时重新生成对应快照，记录公开版本元数据和全部活动 Skills 的稳定清单与树摘要。
3. 仅在 Agent 运行时、名称、分组、展示名称或公开用途确实变化时更新 `snapshot/catalog.json`；未变化条目保持原有措辞和顺序。
4. 将各 Agent 运行时、插件版本与状态、MCP 状态、工具版本、快照日期和全局规范哈希写入 `snapshot/environment.json`，至少包含：
   - `schemaVersion`、`snapshotDate` 和 `timezone`；
   - Codex 个人 Skills、其他运行时活动 Skills、插件包、已启用插件和 MCP 服务数量；
   - 各 Agent 运行时的命令、公开版本元数据、安装方式、脱敏路径和 Skills 根目录；
   - 插件的名称、版本、来源类别、缓存和启用状态；
   - MCP 服务的名称、启用状态和公开用途；
   - 工具命令、版本或读取失败状态；
   - 全局 `AGENTS.md` 的脱敏来源路径和 SHA-256。
5. README 中的动态事实必须来自刚更新的结构化快照；不要只改 README 而遗漏 `snapshot/`。
6. 若新增或扩展快照 schema，同步更新 `scripts/check-snapshot.sh` 的一致性校验，但不要顺带改变无关维护逻辑。

所有 JSON 使用稳定字段顺序和确定性条目排序。路径写成 `~/...`，不得写绝对用户目录。

## 4. 生成 README

围绕“仓库是什么、公开了什么、如何理解、如何维护”组织完整文档：

1. 标题、仓库定位和快照摘要。
2. 状态边界与环境结构。
3. 按场景分组的 Codex 个人 Skills。
4. 其他 Agent 运行时版本、活动 Skills 数量、分类摘要与完整快照链接。
5. 显式启用与仅缓存的 Codex 插件。
6. MCP 服务及其非敏感用途。
7. 本地工具链概览与高价值使用说明。
8. 全局工作规范摘要、完整副本和来源哈希。
9. 仓库级快照维护说明。

使用自然、准确、紧凑的中文。保持标题层级连续且唯一，重复字段使用表格，长副本放入 `<details>`。保留未变化条目的措辞和顺序，不为了视觉变化重排内容。

不要写令牌、凭据、私钥、环境变量值、命令参数或带参数的服务地址。不要混淆本机缓存、配置登记、明确启用和当前会话暴露，也不要把快照描述为配置备份或安装器。

## 5. 验证结果

更新后至少完成以下检查：

- 再次运行 `./scripts/check-snapshot.sh`，确认通过。
- 确认各 Agent CLI 版本、活动 Skills 数量、名称、路径和哈希与 catalog 所列活动目录一致，并确认 bundled、插件缓存或其他非活动 Skills 未混入。
- 确认 README 的数量、版本、状态、来源、日期和哈希与结构化快照一致。
- 确认标题层级、表格列数、代码围栏、HTML 折叠区块和本地链接正确。
- 确认差异不含绝对主目录、敏感配置值、无关改动或意外格式化。
- 运行 `git diff --check`，并确认本次只修改预期的 README、`snapshot/`、必要的校验脚本和 Skill 文件。

最后报告输出路径、盘点时间、更新的事实、采用的来源、验证结果、工作树基线和仍无法确认的内容。缺少必要验证时不得声称完成。
