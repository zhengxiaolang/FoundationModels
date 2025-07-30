import Foundation
import SwiftUI
import Combine
import FoundationModels

// MARK: - 文本生成管理类

class TextGenerationManager: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    // MARK: - 设备支持检查
    
    /// 检查设备是否支持 FoundationModels
    private func checkDeviceSupport() async -> Bool {
        // 检查iOS版本和设备能力
        if #available(iOS 18.0, *) {
            return true // 假设iOS 18+支持FoundationModels
        }
        return false
    }
    
    // MARK: - 核心文本生成方法
    
    /// 使用自定义指令和提示词生成文本 (使用苹果官方 FoundationModels)
    /// - Parameters:
    ///   - instructions: 指令
    ///   - prompt: 用户提示词
    /// - Returns: 生成的文本
    func generateText(instructions: String, prompt: String) async throws -> String {
        await MainActor.run {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                self.isProcessing = false
            }
        }
        
        // 检查设备支持
        guard await checkDeviceSupport() else {
            throw FoundationModelError.unsupportedOperation
        }
        
        do {
            // 使用苹果官方 FoundationModels API
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            await MainActor.run {
                self.errorMessage = "生成失败: \(error.localizedDescription)"
            }
            print("Text generation failed: \(error)")
            throw FoundationModelError.processingError
        }
    }
    
    // MARK: - 专用功能方法
    
    /// 生成创意写作内容
    /// - Parameter topic: 写作主题
    /// - Returns: 生成的创意内容
    func generateCreativeWriting(topic: String) async throws -> String {
        let instructions = """
            你是一位富有创意的作家。请根据给定的主题创作一篇富有想象力和创意的短篇内容。
            要求：
            1. 内容生动有趣
            2. 语言优美流畅
            3. 具有一定的深度和意义
            4. 字数控制在200-300字
            """
        
        return try await generateText(instructions: instructions, prompt: topic)
    }
    
    /// 生成文本摘要
    /// - Parameter text: 要摘要的文本
    /// - Returns: 生成的摘要
    func generateSummary(text: String) async throws -> String {
        let instructions = """
            请为以下文本生成一个简洁准确的摘要。
            要求：
            1. 提取主要观点和关键信息
            2. 保持客观中性的语调
            3. 摘要长度不超过原文的1/3
            4. 确保摘要完整表达原文核心内容
            """
        
        return try await generateText(instructions: instructions, prompt: text)
    }
    
    /// 生成文本续写
    /// - Parameter text: 要续写的文本开头
    /// - Returns: 续写的内容
    func generateCompletion(text: String) async throws -> String {
        let instructions = """
            请为以下文本提供自然流畅的续写。
            要求：
            1. 保持与原文相同的风格和语调
            2. 逻辑连贯，内容合理
            3. 续写长度适中（100-200字）
            4. 确保内容积极正面
            """
        
        return try await generateText(instructions: instructions, prompt: text)
    }
    
    /// 翻译文本 (使用苹果官方 FoundationModels)
    /// - Parameters:
    ///   - text: 要翻译的文本
    ///   - targetLanguage: 目标语言
    /// - Returns: 翻译结果
    func generateTranslation(text: String, to targetLanguage: String) async throws -> String {
        await MainActor.run {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                self.isProcessing = false
            }
        }
        
        // 检查设备支持
        guard await checkDeviceSupport() else {
            throw FoundationModelError.unsupportedOperation
        }
        
        do {
            // 使用苹果官方 FoundationModels 进行翻译
            let translationInstructions = "You are a professional translator. Translate the following text to \(targetLanguage). Only provide the translation, no explanations or additional text."
            let session = LanguageModelSession(instructions: translationInstructions)
            let response = try await session.respond(to: text)
            return response.content
        } catch {
            await MainActor.run {
                self.errorMessage = "翻译失败: \(error.localizedDescription)"
            }
            print("Translation failed: \(error)")
            throw FoundationModelError.processingError
        }
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
            3. 确保改写后的文本自然流畅
            4. 适合目标风格的语境
            """
        
        return try await generateText(instructions: instructions, prompt: text)
    }
    
    /// 生成对话回复
    /// - Parameter message: 用户消息
    /// - Returns: AI回复
    func generateChatResponse(message: String) async throws -> String {
        let instructions = """
            你是一个友好、有帮助的AI助手。请根据用户的消息提供有用、准确的回复。
            要求：
            1. 回复要友好和有帮助
            2. 提供准确的信息
            3. 保持适当的对话长度
            4. 根据用户问题的性质调整回复风格
            """
        
        return try await generateText(instructions: instructions, prompt: message)
    }
    
    /// 分析文本情感
    /// - Parameter text: 要分析的文本
    /// - Returns: 情感分析结果
    func analyzeSentiment(text: String) async throws -> String {
        let instructions = """
            请分析以下文本的情感倾向。
            要求：
            1. 判断情感类型：积极、消极、中性
            2. 提供情感强度评分（1-10）
            3. 解释判断理由
            4. 提取关键情感词汇
            """
        
        return try await generateText(instructions: instructions, prompt: text)
    }
    
    /// 提取关键词
    /// - Parameter text: 要分析的文本
    /// - Returns: 关键词列表
    func extractKeywords(text: String) async throws -> String {
        let instructions = """
            请从以下文本中提取关键词。
            要求：
            1. 提取5-10个最重要的关键词
            2. 按重要性排序
            3. 提供每个关键词的重要性说明
            4. 关键词应该包括名词、动词和形容词
            """
        
        return try await generateText(instructions: instructions, prompt: text)
    }
    
    /// 分类文本
    /// - Parameter text: 要分类的文本
    /// - Returns: 分类结果
    func classifyText(text: String) async throws -> String {
        let instructions = """
            请对以下文本进行分类。
            要求：
            1. 确定文本的主要类别（如：技术、教育、娱乐、新闻等）
            2. 提供分类的置信度
            3. 解释分类的理由
            4. 如果适用，提供次要分类
            """
        
        return try await generateText(instructions: instructions, prompt: text)
    }
    
    // MARK: - 测试方法
    
    /// 测试苹果官方 FoundationModels API
    func testAppleFoundationModels() async throws -> String {
        let instructions = "You are a helpful assistant. Please respond to user queries in a helpful and informative manner."
        let prompt = "Hello, how are you today?"
        
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: prompt)
        return response.content
    }
}
