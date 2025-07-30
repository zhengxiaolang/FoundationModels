import Foundation
import SwiftUI
import Combine
import FoundationModels

// MARK: - 文本生成管理类

class TextGenerationManager: ObservableObject {
    @Published var isProcessing = false
    @Published var lastError: String?
    @Published var lastResult: String?
    
    // 检查设备是否支持 FoundationModels
    var isFoundationModelsSupported: Bool {
        if #available(iOS 18.0, macOS 15.0, *) {
            return true
        }
        return false
    }
    
    // MARK: - 公共方法
    
    /// 使用自定义指令和提示词生成文本 (使用苹果官方 FoundationModels)
    /// - Parameters:
    ///   - instructions: 指令文本，用于指导AI如何响应
    ///   - prompt: 用户输入的提示词
    /// - Returns: 生成的文本内容
    func generateText(instructions: String, prompt: String) async throws -> String {
        // 检查设备支持
        guard isFoundationModelsSupported else {
            throw FoundationModelError.unsupportedOperation
        }
        
        await MainActor.run {
            self.isProcessing = true
            self.lastError = nil
        }
        
        do {
            // 使用苹果官方 FoundationModels API
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            
            await MainActor.run {
                self.isProcessing = false
                self.lastResult = response.content
            }
            
            return response.content
        } catch {
            await MainActor.run {
                self.isProcessing = false
                self.lastError = "文本生成失败: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// 生成相关主题建议 (使用苹果官方 FoundationModels)
    /// - Parameter topic: 主题
    /// - Returns: 相关主题建议
    func generateRelatedTopics(for topic: String) async throws -> String {
        let instructions = """
            Suggest five related topics. Keep them concise (three to seven words) and make sure they \
            build naturally from the person's topic.
            """
        
        return try await generateText(instructions: instructions, prompt: topic)
    }
    
    /// 生成创意内容 (使用苹果官方 FoundationModels)
    /// - Parameters:
    ///   - prompt: 创意提示
    ///   - style: 创意风格
    /// - Returns: 创意内容
    func generateCreativeContent(prompt: String, style: String = "创意") async throws -> String {
        let instructions = """
            你是一个富有创意的写作助手。请根据用户的提示生成有趣、原创且富有想象力的内容。
            风格要求：\(style)
            请确保内容积极向上，富有创意。
            """
        
        return try await generateText(instructions: instructions, prompt: prompt)
    }
    
    /// 生成技术解释 (使用苹果官方 FoundationModels)
    /// - Parameter concept: 技术概念
    /// - Returns: 技术解释
    func generateTechnicalExplanation(for concept: String) async throws -> String {
        let instructions = """
            你是一个技术专家。请用简洁明了的语言解释技术概念，确保内容准确且易于理解。
            请包含：
            1. 基本定义
            2. 主要特点
            3. 实际应用
            4. 简单示例（如果适用）
            """
        
        return try await generateText(instructions: instructions, prompt: concept)
    }
    
    /// 生成对话回复 (使用苹果官方 FoundationModels)
    /// - Parameters:
    ///   - message: 用户消息
    ///   - context: 对话上下文
    /// - Returns: 对话回复
    func generateConversationReply(to message: String, context: String = "") async throws -> String {
        let instructions = """
            你是一个友好、有帮助的AI助手。请根据用户的消息生成自然、有用的回复。
            \(context.isEmpty ? "" : "对话上下文：\(context)")
            请保持回复简洁、相关且有帮助。
            """
        
        return try await generateText(instructions: instructions, prompt: message)
    }
    
    /// 生成文本摘要 (使用苹果官方 FoundationModels)
    /// - Parameters:
    ///   - text: 要摘要的文本
    ///   - maxLength: 最大长度
    /// - Returns: 文本摘要
    func generateSummary(for text: String, maxLength: Int = 100) async throws -> String {
        let instructions = """
            请将以下文本总结为不超过\(maxLength)字的简洁摘要。
            摘要应该：
            1. 保留主要信息
            2. 语言简洁明了
            3. 逻辑清晰
            """
        
        return try await generateText(instructions: instructions, prompt: text)
    }
    
    /// 生成翻译 (使用苹果官方 FoundationModels)
    /// - Parameters:
    ///   - text: 要翻译的文本
    ///   - targetLanguage: 目标语言
    /// - Returns: 翻译结果
    func generateTranslation(text: String, to targetLanguage: String) async throws -> String {
        let instructions = """
            请将以下文本翻译为\(targetLanguage)。
            翻译要求：
            1. 准确传达原意
            2. 语言自然流畅
            3. 符合目标语言的表达习惯
            """
        
        return try await generateText(instructions: instructions, prompt: text)
    }
    
    /// 生成文本改写 (使用苹果官方 FoundationModels)
    /// - Parameters:
    ///   - text: 原文本
    ///   - style: 改写风格
    /// - Returns: 改写后的文本
    func generateRewrite(text: String, style: String) async throws -> String {
        let instructions = """
            请将以下文本改写为\(style)风格。
            改写要求：
            1. 保持原意不变
            2. 调整语言风格和表达方式
            3. 确保语言自然流畅
            """
        
        return try await generateText(instructions: instructions, prompt: text)
    }
    
    /// 测试苹果官方 FoundationModels API 的示例方法
    /// 按照您提供的示例实现真正的AI调用
    func testAppleFoundationModels() async throws -> String {
        await MainActor.run {
            self.isProcessing = true
            self.lastError = nil
        }
        
        do {
            // 完全按照苹果官方示例的调用方式
            let instructions = """
                Suggest five related topics. Keep them concise (three to seven words) and make sure they \
                build naturally from the person's topic.
                """

            let session = LanguageModelSession(instructions: instructions)

            let prompt = "Making homemade bread"
            let response = try await session.respond(to: prompt)
            
            await MainActor.run {
                self.isProcessing = false
                self.lastResult = response.content
            }
            
            return response.content
        } catch {
            await MainActor.run {
                self.isProcessing = false
                self.lastError = "Apple FoundationModels 调用失败: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - 便利方法
    
    /// 清除错误信息
    func clearError() {
        lastError = nil
    }
    
    /// 清除结果
    func clearResult() {
        lastResult = nil
    }
    
    /// 清除所有状态
    func clearAll() {
        lastError = nil
        lastResult = nil
    }
}

// MARK: - 预定义指令模板

extension TextGenerationManager {
    
    /// 预定义的指令模板
    enum InstructionTemplate {
        case relatedTopics
        case creative(style: String)
        case technical
        case conversation(context: String)
        case summary(maxLength: Int)
        case translation(targetLanguage: String)
        case rewrite(style: String)
        case custom(instructions: String)
        
        var instructions: String {
            switch self {
            case .relatedTopics:
                return """
                    Suggest five related topics. Keep them concise (three to seven words) and make sure they \
                    build naturally from the person's topic.
                    """
            case .creative(let style):
                return """
                    你是一个富有创意的写作助手。请根据用户的提示生成有趣、原创且富有想象力的内容。
                    风格要求：\(style)
                    请确保内容积极向上，富有创意。
                    """
            case .technical:
                return """
                    你是一个技术专家。请用简洁明了的语言解释技术概念，确保内容准确且易于理解。
                    请包含：
                    1. 基本定义
                    2. 主要特点
                    3. 实际应用
                    4. 简单示例（如果适用）
                    """
            case .conversation(let context):
                return """
                    你是一个友好、有帮助的AI助手。请根据用户的消息生成自然、有用的回复。
                    \(context.isEmpty ? "" : "对话上下文：\(context)")
                    请保持回复简洁、相关且有帮助。
                    """
            case .summary(let maxLength):
                return """
                    请将以下文本总结为不超过\(maxLength)字的简洁摘要。
                    摘要应该：
                    1. 保留主要信息
                    2. 语言简洁明了
                    3. 逻辑清晰
                    """
            case .translation(let targetLanguage):
                return """
                    请将以下文本翻译为\(targetLanguage)。
                    翻译要求：
                    1. 准确传达原意
                    2. 语言自然流畅
                    3. 符合目标语言的表达习惯
                    """
            case .rewrite(let style):
                return """
                    请将以下文本改写为\(style)风格。
                    改写要求：
                    1. 保持原意不变
                    2. 调整语言风格和表达方式
                    3. 确保语言自然流畅
                    """
            case .custom(let instructions):
                return instructions
            }
        }
    }
    
    /// 使用预定义模板生成文本
    /// - Parameters:
    ///   - template: 指令模板
    ///   - prompt: 用户提示
    /// - Returns: 生成的文本
    func generateText(using template: InstructionTemplate, prompt: String) async throws -> String {
        return try await generateText(instructions: template.instructions, prompt: prompt)
    }
}
