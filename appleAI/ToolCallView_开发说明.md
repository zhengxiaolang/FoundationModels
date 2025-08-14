# ToolCallView 开发说明文档

最后更新：2025-08-14

## 1. 概述
`ToolCallView` 是演示如何基于 Apple Foundation Models (LanguageModelSession) 实现“自然语言 + 多工具调用”编排的核心交互视图。它将用户输入的自然语言解析并智能匹配到对应的工具（天气、计算、翻译、搜索、二维码、调色板、登录、泛用 General），同时提供：
- 输入区域 + 智能建议 + 快速示例
- 动态工具推荐（基于启发式打分与模式检测）
- 登录凭据多语言解析（中英文混合）
- 一般知识型/定义型问题的 General 轻量回答
- 执行结果展示与清空机制

## 2. 支持的工具一览
| 工具 | 枚举 | 主要能力 | 触发线索 | 备注 |
| ---- | ---- | -------- | -------- | ---- |
| 天气 | `.weather` | 城市天气查询 | weather/天气/temperature/城市名 | 使用 `WeatherTool()` Session |
| 计算器 | `.calculator` | 基本四则 + 百分比表达式 | 计算关键词/算术符号/百分比 | 百分比与算式有高优先级模式加权 |
| 翻译 | `.translator` | 多语言文本翻译 | translate/翻译/中文/英文 等 | 使用 `TranslatorTool()` |
| 搜索 | `.search` | Wikipedia + GitHub + HTTPBin | search/搜索/find/about | 具有多语言及超时保护 |
| 二维码 | `.qrGenerator` | 生成二维码 (文本/URL) | qr/二维码/含 URL | 多模式提取目标 payload |
| 调色板 | `.colorPalette` | 基于描述生成调色板 | color/颜色/palette/theme | 调色板 API 示例 |
| 登录 | `.login` | 真实接口登录 & y-token 头生成 | login/登录/账号/密码/凭据模式 | 统一多语言凭据解析管线 |
| 通用 | `.general` | 定义/解释/科普类直接回答 | explain/define/是什么/... | 不加载其它工具，轻量 Session |

## 3. 视图结构概览
```
ToolCallView
 ├─ inputSection
 │   ├─ TextField (多行输入)
 │   ├─ 当前工具指示卡片
 │   ├─ Quick Select 横向示例列表
 │   └─ 键盘工具栏（数学符号/粘贴/清空/完成）
 │
 ├─ actionButton (执行)
 │
 ├─ resultsSection (结果列表 + 清空按钮)
 │
 └─ smartSuggestionView (AI建议卡片，可根据 showSuggestion 条件显示)
```

## 4. 执行流程 (高层时序)
```
用户输入/选择示例 → analyzeInputAndSuggestTool()
  → 关键词计数 + 正则模式加权 + 定义型覆盖判断
  → 生成 suggestedTool / 回退到 general
点击执行 executeToolCall()
  → 根据 (suggestedTool ?? selectedTool) 分支：
     - login: 解析凭据 → LoginTool 调用
     - qr: 直接执行 QR 工具确保渲染
     - general: 轻量 Session 直接回答
     - 其它: 构造含该工具的 LanguageModelSession 并自然语言调用
  → 插入结果到 results 数组 → UI 更新
```

## 5. 工具选择（启发式分类）
### 5.1 核心策略
1. 基础关键词计数：为每个工具建立关键词集合，出现即 +1。  
2. 模式加权：
   - 算术/百分比表达式匹配 → 计算器 +8~+10
   - 登录意图正则（username/password、斜杠形式、中文“账号跟密码分别为”）→ 登录 +7~+8
   - 百分比 `15% of 200` / `15%的200` → 计算器高权重
   - URL 存在 → 二维码 +3（但仍需 QR 关键词或后续判定）
   - 城市名称 → 天气 +3
3. 干扰抑制：出现 password/pwd/密码 而无算术操作符 ⇒ 计算器分数减弱。
4. 定义型/科普型覆盖：`explain/define/what is/是什么/概述/总结/简述/list/列出...` 且无强工具信号 ⇒ 强制 General。
5. 全零回退：所有特定工具得分 = 0 ⇒ General。
6. 冲突解决：取最高分；得分相同按 `scores.first` 顺序（可进一步改进）。

### 5.2 Definitional 覆盖策略的改进点
- 防止“photosynthesis”这类纯知识查询因包含城市名称（比如“Paris Accord definition”情况）误触发天气。
- 覆盖英文+中文多种表达（是什么/解释/说明/概述/总结/简述/列出/谁写/什么时候 等）。

## 6. 凭据解析 (extractCredentialsAndContext)
解析顺序：
1. 组合正则（中英混合 & 斜杠形式）
2. key=value / key:val / 中英文冒号 `：`
3. 宽松英文/中文 (`username is X`, `密码是 Y`)
4. 紧凑表达：`user and pwd is u,p`
5. 最后尝试基于 `login` 关键字后跟两个 token。

返回元组：(username, password, site, domain, authType)。Site 为空则给默认站点。解析时尽量不误把 `0000` 视为算式。

## 7. QR 内容提取 (extractQRPayload)
优先级：URL → 引号内容 → 英文模式 (generate/create/make ...) → 中文模式 (生成二维码 / 内容是 ...) → 去除前后导语/连接词 → 清理标点。确保最终 payload 简洁，避免“Generate QR code for ”此类前缀残留。

## 8. General 工具设计
- 不加载任何工具数组，减少上下文 & token 压力。
- 指令：强调“简洁、直接”回答，避免赘述。
- 输入长度防御：超过 2000 字符截断并追加 `...`。
- 用例：定义、解释、概念总结、简短列举、作者/基本事实问答。

## 9. 搜索工具增强要点 (SearchTool)
- 多语言（中文/英文）自动检测。
- Wikipedia summary + search fallback。
- GitHub 代码/仓库搜索补充技术信息。
- 超时保护：避免长时间阻塞（未在此文详细展开，可在对应实现中查看）。

## 10. 颜色 / 调色板工具
接收主题描述，调用色彩生成 API（示例逻辑），返回调色板 JSON/文本（具体接口实现可扩展为真正色彩服务）。

## 11. UI / 交互特性
- 快速示例列表：混合多工具示例 + General 示例（刺猬是什么动物、Explain ...）。
- 智能建议卡片：显示推荐工具图标、说明、按钮“使用”。
- 工具切换：点击工具卡片会重置输入为占位提示（placeholder）。
- 结果卡片：支持多次执行结果堆叠，最新置顶；可一键 Clear。
- 键盘工具栏：按上下文显示算术符号；常用 `@`、`://` 快插。

## 12. 扩展新工具指引
添加一个新工具（例如“股票报价”）步骤：
1. 定义 `struct StockTool: Tool { ... }`，实现 `call(arguments:)`。
2. 在 `ToolType` 枚举中添加 case（选择图标、颜色、描述、placeholder）。
3. 在 `analyzeInputAndSuggestTool` 中添加关键词数组与分数赋值逻辑；必要时添加正则模式加权。
4. 在 `performToolCall` / `determineToolType` 中添加分支。
5. 若需快速示例，添加到 `quickSelectionData`。
6. 若 Session 需要同时加载多个工具，自行构造包含该 Tool 的 `LanguageModelSession`。

## 13. 典型边界 & 处理策略
| 场景 | 风险 | 缓解 |
| ---- | ---- | ---- |
| 百分比表达式 (15% of 200) | 被当普通文本 | 百分比高权重 + 正则 | 
| 登录 账号/密码 混合中文 | 无法解析 | 多语言组合正则 + fallback token | 
| 普通知识问答含城市名 | 误判天气 | 定义型覆盖清零天气 | 
| 短凭据 `u/p` | 未识别 | 斜杠模式正则 | 
| 长文本 general | 上下文超限 | 2000 字符截断 | 
| URL 但非二维码需求 | 误判 QR | 需 QR 关键词或显式提取模式 | 
| 含 password 但无算术 | 误判计算器 | 降低 calculator 分数 | 

## 14. 可能的改进方向
1. Token 级别长度控制（按估算 tokens 而非字符数）。
2. 更智能的打分：引入加权 Map + 阈值与置信度，而非单纯最高分。
3. Tie-break 策略：在分数并列时依据优先级 / 语义相似度二次判定。
4. 可插拔分类器：把启发式替换为小型本地分类模型。
5. 登录安全：对凭据显示做部分掩码；记录失败次数；区分 domain 推断。
6. 日志与遥测：统计命中率、误判率、工具使用频次。
7. 国际化扩展：日语 / 韩语 凭据与定义短语支持。
8. 缓存层：对同一 General 问答或搜索结果短期缓存，减少重复请求。

## 15. 性能与鲁棒性
- 分析函数纯本地字符串处理，复杂度 O(n * k)（k 为关键词集合规模），可接受。
- 正则编译：当前使用多次 `NSRegularExpression` 构建，若性能敏感可静态缓存。
- 登录/搜索等网络操作异步执行，UI 主线程仅做状态更新。
- 失败路径通过 Alert 显示错误信息；后续可细化错误码。 

## 16. 常见问答 (FAQ)
Q: 为什么某些“定义”问题仍然走 Search？  
A: 如果出现明确搜索意图词（如 search/查找），分类逻辑尊重搜索需求。可调整 definitional override 策略。  

Q: 添加新工具后 General 误判增多怎么办？  
A: 增加该工具更明确的高权重模式正则，并在 definitional override 前检测。  

Q: 登录默认站点在哪里设定？  
A: `performLogin` 内部在 site 为空时赋默认 `https://cipweb-test-dev.sogoodsofast.com/Offline_API`。  

## 17. 代码阅读重点索引
| 功能 | 关键函数 / 位置 |
| ---- | --------------- |
| 工具打分与建议 | `analyzeInputAndSuggestTool` |
| 最终工具判定（会话执行后标记） | `determineToolType` |
| 登录凭据解析 | `extractCredentialsAndContext` |
| 二维码 payload 提取 | `extractQRPayload` / `sanitizePayload` |
| General 回答 | `performGeneralAnswer` |
| 具体工具执行分派 | `performToolCall` |
| UI 快速示例 | `quickSelectionData` 计算属性 |

## 18. 示例输入与分类结果
| 输入 | 期望工具 | 原因 |
| ---- | -------- | ---- |
| "What's the weather in Beijing today?" | Weather | 含 weather + 城市名 |
| "15% of 200" | Calculator | 百分比模式匹配 |
| "Login with username superadmin and password 0115" | Login | 登录正则匹配 |
| "账号跟密码分别为superadmin/0115, 登录下" | Login | 中文复合 + 斜杠模式 |
| "Generate QR code for https://apple.com" | QR | URL + QR 关键词 |
| "Explain what a hedgehog is" | General | 定义型覆盖 |
| "Who wrote The Little Prince?" | General | 作者问答属科普 |
| "Search for Swift Concurrency structured examples" | Search | 明确搜索意图词 |

## 19. 如何调试误判
1. 打印 `scores`（可临时在函数末尾添加日志）。
2. 查看是否被 definitional 覆盖提前返回。
3. 检查是否某关键词列表过宽（如历史上移除的单词 "of"）。
4. 添加针对误判案例的特定正则加权或抑制逻辑。 

## 20. 总结
`ToolCallView` 展示了一个轻量级、可扩展、易于调试的多工具自然语言调用编排框架。通过启发式 + 模式优先级 + 覆盖策略解决常见误判，同时保持实现透明度。后续可逐步引入统计学习或小模型分类器，在维持可解释性的基础上提升准确率与泛化性。

---
如需进一步扩展或对特定分类行为进行微调，可在本文件基础上记录变更与量化指标，形成迭代闭环。
