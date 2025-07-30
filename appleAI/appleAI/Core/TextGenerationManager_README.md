# TextGenerationManager 使用指南

## 概述

`TextGenerationManager` 是一个封装了文本生成功能的管理类，提供了简洁的 API 来使用 Apple Foundation Models 进行各种文本生成任务。

## 主要特性

- ✅ 支持自定义指令和提示词
- ✅ 提供多种预定义的文本生成模板
- ✅ 内置错误处理和状态管理
- ✅ 支持异步操作
- ✅ 提供便利方法用于常见任务

## 基本使用

### 1. 创建管理器实例

```swift
@StateObject private var textManager = TextGenerationManager()
```

### 2. 基本文本生成

```swift
// 使用自定义指令和提示词
let result = try await textManager.generateText(
    instructions: "你的指令文本",
    prompt: "用户输入的提示词"
)
```

### 3. 原始函数的封装示例

原始函数：
```swift
func generateText() async throws {
    let instructions = """
        Suggest five related topics. Keep them concise (three to seven words) and make sure they \
        build naturally from the person's topic.
        """
    
    let session = LanguageModelSession(instructions: instructions)
    let prompt = "Making homemade bread"
    let response = try await session.respond(to: prompt)
    await MainActor.run {
        testResult = response.content
    }
    print(response)
}
```

使用 TextGenerationManager 重构后：
```swift
func generateText() async throws -> String {
    let instructions = """
        Suggest five related topics. Keep them concise (three to seven words) and make sure they \
        build naturally from the person's topic.
        """
    
    let prompt = "Making homemade bread"
    return try await textManager.generateText(instructions: instructions, prompt: prompt)
}
```

## 便利方法

### 生成相关主题
```swift
let topics = try await textManager.generateRelatedTopics(for: "Making homemade bread")
```

### 生成创意内容
```swift
let content = try await textManager.generateCreativeContent(
    prompt: "写一个关于机器人的故事",
    style: "幽默"
)
```

### 生成技术解释
```swift
let explanation = try await textManager.generateTechnicalExplanation(for: "区块链技术")
```

### 生成对话回复
```swift
let reply = try await textManager.generateConversationReply(
    to: "你好，今天天气怎么样？",
    context: "这是一个友好的对话"
)
```

### 生成文本摘要
```swift
let summary = try await textManager.generateSummary(
    for: "长文本内容...",
    maxLength: 100
)
```

### 生成翻译
```swift
let translation = try await textManager.generateTranslation(
    text: "Hello, how are you?",
    to: "中文"
)
```

### 生成文本改写
```swift
let rewrite = try await textManager.generateRewrite(
    text: "原始文本",
    style: "正式"
)
```

## 使用预定义模板

```swift
// 相关主题模板
let result = try await textManager.generateText(
    using: .relatedTopics,
    prompt: "人工智能"
)

// 创意写作模板
let result = try await textManager.generateText(
    using: .creative(style: "幽默"),
    prompt: "机器人学做饭"
)

// 技术解释模板
let result = try await textManager.generateText(
    using: .technical,
    prompt: "机器学习"
)

// 对话模板
let result = try await textManager.generateText(
    using: .conversation(context: "友好对话"),
    prompt: "你好"
)

// 摘要模板
let result = try await textManager.generateText(
    using: .summary(maxLength: 100),
    prompt: "长文本内容..."
)

// 翻译模板
let result = try await textManager.generateText(
    using: .translation(targetLanguage: "英语"),
    prompt: "你好世界"
)

// 改写模板
let result = try await textManager.generateText(
    using: .rewrite(style: "正式"),
    prompt: "嗨，怎么样？"
)

// 自定义模板
let result = try await textManager.generateText(
    using: .custom(instructions: "你的自定义指令"),
    prompt: "用户输入"
)
```

## 状态监控

```swift
// 检查是否正在处理
if textManager.isProcessing {
    // 显示加载状态
}

// 检查错误
if let error = textManager.lastError {
    // 处理错误
    print("错误: \(error)")
}

// 获取最后的结果
if let result = textManager.lastResult {
    // 使用结果
}
```

## 错误处理

```swift
do {
    let result = try await textManager.generateText(
        instructions: instructions,
        prompt: prompt
    )
    // 使用结果
} catch {
    // 处理错误
    print("生成失败: \(error)")
}
```

## 状态管理方法

```swift
// 清除错误信息
textManager.clearError()

// 清除结果
textManager.clearResult()

// 清除所有状态
textManager.clearAll()
```

## 在 SwiftUI 中的使用

```swift
struct MyView: View {
    @StateObject private var textManager = TextGenerationManager()
    @State private var result = ""
    
    var body: some View {
        VStack {
            Button("生成文本") {
                generateText()
            }
            .disabled(textManager.isProcessing)
            
            if textManager.isProcessing {
                ProgressView("生成中...")
            }
            
            if !result.isEmpty {
                Text(result)
                    .padding()
            }
            
            if let error = textManager.lastError {
                Text("错误: \(error)")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func generateText() {
        Task {
            do {
                let generated = try await textManager.generateRelatedTopics(for: "编程")
                await MainActor.run {
                    result = generated
                }
            } catch {
                print("生成失败: \(error)")
            }
        }
    }
}
```

## 优势

1. **简化 API**: 不需要直接处理 `LanguageModelSession`
2. **统一接口**: 所有文本生成任务使用一致的 API
3. **状态管理**: 内置处理状态和错误管理
4. **预定义模板**: 提供常用的指令模板
5. **类型安全**: 使用 Swift 的类型系统确保安全
6. **异步支持**: 完全支持 Swift 的 async/await

## 示例项目

查看 `TextGenerationExample.swift` 和 `TextGenerationDemoView.swift` 获取完整的使用示例。
