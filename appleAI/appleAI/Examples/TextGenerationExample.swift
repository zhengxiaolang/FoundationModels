import SwiftUI

// MARK: - 使用示例：如何使用 TextGenerationManager

struct TextGenerationExample: View {
    @StateObject private var textManager = TextGenerationManager()
    @State private var result = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("TextGenerationManager 使用示例")
                .font(.title2)
                .fontWeight(.bold)
            
            // 示例1：生成相关主题
            Button("生成相关主题") {
                generateRelatedTopics()
            }
            .buttonStyle(.borderedProminent)
            
            // 示例2：创意内容生成
            Button("生成创意内容") {
                generateCreativeContent()
            }
            .buttonStyle(.borderedProminent)
            
            // 示例3：技术解释
            Button("生成技术解释") {
                generateTechnicalExplanation()
            }
            .buttonStyle(.borderedProminent)
            
            // 示例4：自定义指令
            Button("自定义指令示例") {
                generateWithCustomInstructions()
            }
            .buttonStyle(.borderedProminent)
            
            if textManager.isProcessing {
                ProgressView("生成中...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            if !result.isEmpty {
                ScrollView {
                    Text(result)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if let error = textManager.lastError {
                Text("错误: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
    
    // MARK: - 示例方法
    
    /// 示例1：生成相关主题
    private func generateRelatedTopics() {
        Task {
            do {
                let topics = try await textManager.generateRelatedTopics(for: "人工智能")
                await MainActor.run {
                    result = "相关主题：\n\(topics)"
                }
            } catch {
                print("生成相关主题失败: \(error)")
            }
        }
    }
    
    /// 示例2：生成创意内容
    private func generateCreativeContent() {
        Task {
            do {
                let content = try await textManager.generateCreativeContent(
                    prompt: "写一个关于机器人学会做饭的短故事",
                    style: "幽默"
                )
                await MainActor.run {
                    result = "创意内容：\n\(content)"
                }
            } catch {
                print("生成创意内容失败: \(error)")
            }
        }
    }
    
    /// 示例3：生成技术解释
    private func generateTechnicalExplanation() {
        Task {
            do {
                let explanation = try await textManager.generateTechnicalExplanation(for: "区块链技术")
                await MainActor.run {
                    result = "技术解释：\n\(explanation)"
                }
            } catch {
                print("生成技术解释失败: \(error)")
            }
        }
    }
    
    /// 示例4：使用自定义指令
    private func generateWithCustomInstructions() {
        Task {
            do {
                let customInstructions = """
                    你是一个专业的产品经理。请根据用户的需求，提供详细的产品功能建议。
                    建议应该包括：
                    1. 核心功能描述
                    2. 用户价值
                    3. 实现难度评估
                    4. 优先级建议
                    """
                
                let result = try await textManager.generateText(
                    instructions: customInstructions,
                    prompt: "我想开发一个智能健身应用"
                )
                
                await MainActor.run {
                    self.result = "产品建议：\n\(result)"
                }
            } catch {
                print("生成产品建议失败: \(error)")
            }
        }
    }
}

// MARK: - 代码示例注释

/*
 
 ## TextGenerationManager 使用指南
 
 ### 1. 基本使用
 
 ```swift
 @StateObject private var textManager = TextGenerationManager()
 
 // 使用自定义指令和提示词
 let result = try await textManager.generateText(
     instructions: "你的指令",
     prompt: "用户输入"
 )
 ```
 
 ### 2. 便利方法
 
 ```swift
 // 生成相关主题
 let topics = try await textManager.generateRelatedTopics(for: "主题")
 
 // 生成创意内容
 let content = try await textManager.generateCreativeContent(
     prompt: "创意提示",
     style: "风格"
 )
 
 // 生成技术解释
 let explanation = try await textManager.generateTechnicalExplanation(for: "技术概念")
 
 // 生成对话回复
 let reply = try await textManager.generateConversationReply(
     to: "用户消息",
     context: "对话上下文"
 )
 
 // 生成摘要
 let summary = try await textManager.generateSummary(
     for: "长文本",
     maxLength: 100
 )
 
 // 生成翻译
 let translation = try await textManager.generateTranslation(
     text: "原文",
     to: "目标语言"
 )
 
 // 生成改写
 let rewrite = try await textManager.generateRewrite(
     text: "原文",
     style: "目标风格"
 )
 ```
 
 ### 3. 使用预定义模板
 
 ```swift
 // 使用模板
 let result = try await textManager.generateText(
     using: .relatedTopics,
     prompt: "用户输入"
 )
 
 // 其他模板
 .creative(style: "创意")
 .technical
 .conversation(context: "上下文")
 .summary(maxLength: 100)
 .translation(targetLanguage: "英语")
 .rewrite(style: "正式")
 .custom(instructions: "自定义指令")
 ```
 
 ### 4. 状态监控
 
 ```swift
 // 监控处理状态
 if textManager.isProcessing {
     // 显示加载状态
 }
 
 // 检查错误
 if let error = textManager.lastError {
     // 处理错误
 }
 
 // 获取最后结果
 if let result = textManager.lastResult {
     // 使用结果
 }
 ```
 
 ### 5. 错误处理
 
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
 
 */

#Preview {
    TextGenerationExample()
}
