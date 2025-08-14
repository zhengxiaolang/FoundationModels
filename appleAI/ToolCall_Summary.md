# ToolCall概要（聚焦可调用工具）
最后更新：2025-08-14

目的：清晰说明当前视图中已经集成并可被自然语言触发的全部 Tool Call 类型及示例。

## 1. 工具总览
当前已接入 8 类工具，统一由自然语言一句话触发：

| 序号 | 工具 | 枚举 | 能力简介 | 典型触发示例（自然语言） | 关键触发词/特征 |
| ---- | ---- | ---- | -------- | ------------------------ | --------------- |
| 1 | 天气 Weather | `.weather` | 查询城市当前天气/温度 | "What's the weather in Beijing?" / "上海明天天气" | weather, 天气, temperature, 城市名 |
| 2 | 计算 Calculator | `.calculator` | 四则运算 & 百分比 | "Calculate 25 * 4 + 10" / "15% of 200" / "15%的200" | + - * / × ÷ % percent 百分比 |
| 3 | 翻译 Translator | `.translator` | 文本翻译(中英多语言) | "Translate 'Hello' to Chinese" / "翻译 你好 为英文" | translate, 翻译, 中文, 英文 |
| 4 | 搜索 Search | `.search` | 多源检索 (Wikipedia+GitHub+HTTP) | "Search for Llama 3 updates" / "搜索 Apple Intelligence 功能" | search, 搜索, find, lookup |
| 5 | 二维码 QR | `.qrGenerator` | 生成文本/URL 对应二维码 | "Generate QR code for https://apple.com" / "生成二维码 内容是 hello" | qr, qrcode, 二维码 (+ URL) |
| 6 | 调色板 Color | `.colorPalette` | 依据描述生成配色方案 | "Color palette for a calm ocean theme" / "生成一个科技蓝主题配色" | color, 颜色, palette, theme |
| 7 | 登录 Login | `.login` | 解析凭据并调用真实登录接口 | "Login with username superadmin and password 0115" / "账号跟密码分别为superadmin/0115, 登录" | login, 登录, 账号, 密码, username/password, u/p 斜杠 |
| 8 | 通用 General | `.general` | 定义/解释/科普 Q&A 兜底 | "Explain what a hedgehog is" / "光合作用一句话总结" | explain, define, 是什么, 概述, 总结 |

## 2. 触发逻辑简述
1. 关键词计数：每种工具有关键词集合，出现即加分。
2. 模式识别：算式/百分比、登录凭据、二维码 URL、城市名等给予额外加权。
3. 覆盖策略：定义/解释类问题在无强工具信号时直接归入 General。
4. 回退策略：所有特定工具得分为 0 → General。

## 3. Demo 建议（8 个工具功用展示）
1. 天气（Weather）- 功用：实时查询指定城市天气 / 温度。
	示例："What's the weather in Beijing today?" → 返回北京当前天气概述。
2. 计算（Calculator）- 功用：四则运算与百分比计算解析执行。
	示例："What's 15% of 200?" → 结果 30。
3. 翻译（Translator）- 功用：中英（可扩展多语言）互译短文本。
	示例："Translate 'Hello world' to Chinese" → "你好，世界"。
4. 搜索（Search）- 功用：聚合 Wikipedia / GitHub / HTTP 回显多源检索。
	示例："Search for 'Apple Intelligence' features" → 聚合功能与来源摘要。
5. 二维码（QR Generator）- 功用：将 URL / 文本转为二维码（生成可渲染结果）。
	示例："Generate QR code for https://apple.com" → 返回二维码内容链接。
6. 调色板（Color Palette）- 功用：根据语义描述生成主题配色建议。
	示例："Color palette for a calm ocean theme" → 返回多色 HEX 列表。
7. 登录（Login）- 功用：解析多语言/多格式凭据并调用真实登录接口（含 y-token 计算）。
	示例："Login with username superadmin and password 0115" → 返回服务器响应摘要。
8. 通用（General）- 功用：定义 / 解释 / 科普类问答兜底，避免“未匹配”落空。
	示例："Give a one sentence summary of photosynthesis" → 一句话概述光合作用。

## 4. 可扩展性（一句话）
新增工具：枚举 + 关键词/正则 + 执行分派（约 6 处修改），保持低耦合，高速迭代。

## 5. 下一步（与工具相关的最小增强）
- 统计各工具触发次数 & 误判样例，用于优化关键词权重。
- 登录结果脱敏（用户名/密码部分遮盖）。
- 增补日/韩定义类触发词，提升 General 覆盖。

## 6. 汇报要点（提炼）
- 已落地 8 个可调用工具，覆盖“查询 / 计算 / 转换 / 检索 / 生成 / 登录 / 科普”主干场景。
- 一句话自然语言输入即可自动选择工具或回退 General，减少操作路径。
- 结构清晰、易于增量扩展，具备快速复制到其它业务域的潜力。

---
附：如需更详细的技术实现，可参阅 `ToolCallView_开发说明.md` 完整版文档。
