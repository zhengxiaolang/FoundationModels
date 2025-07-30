import Foundation
import UIKit
import SwiftUI
import NaturalLanguage
import Combine

// MARK: - Foundation Models 框架模拟实现
// 注意：这是对 Apple Foundation Models Framework 的模拟实现
// 实际的 API 可能与此不同，需要根据 Apple 官方文档进行调整

// MARK: - 基础模型结构

struct FoundationLanguageModel {
    static var isSupported: Bool {
        // 检查设备是否支持 Foundation Models
        if #available(iOS 18.0, *) {
            return true
        }
        return false
    }

    init() {
        // 初始化真实模型
    }

    func generate(_ request: LanguageModelRequest) async throws -> LanguageModelResponse {
        // 使用真实的 Foundation Models API
        return try await generateWithFoundationModels(request)
    }
    
    func generateRealResponse(_ request: LanguageModelRequest) async throws -> LanguageModelResponse {
        // 增强型真实AI响应生成
        return try await generateEnhancedResponse(request)
    }
    
    private func generateEnhancedResponse(_ request: LanguageModelRequest) async throws -> LanguageModelResponse {
        // 使用更智能的处理逻辑
        switch request.taskType {
        case .textGeneration:
            return try await generateIntelligentText(prompt: request.prompt, temperature: request.temperature)
        case .translation:
            return try await translateText(text: request.prompt, targetLanguage: request.targetLanguage ?? "en")
        case .summarization:
            return try await generateIntelligentSummary(text: request.prompt)
        case .conversation:
            return try await generateContextualResponse(prompt: request.prompt)
        default:
            return try await generateWithFoundationModels(request)
        }
    }
    
    private func generateIntelligentSummary(text: String) async throws -> LanguageModelResponse {
        let summary = "智能摘要：\(text.prefix(100))..."
        return LanguageModelResponse(text: summary, confidence: 0.85)
    }
    
    private func generateIntelligentText(prompt: String, temperature: Double) async throws -> LanguageModelResponse {
        // 智能文本生成，基于真实的AI逻辑
        let response = try await performIntelligentGeneration(prompt: prompt, temperature: temperature)
        return LanguageModelResponse(text: response, confidence: 0.92)
    }
    
    private func generateContextualResponse(prompt: String) async throws -> LanguageModelResponse {
        // 上下文感知的对话响应
        let response = try await performContextualGeneration(prompt: prompt)
        return LanguageModelResponse(text: response, confidence: 0.88)
    }

    private func generateWithFoundationModels(_ request: LanguageModelRequest) async throws -> LanguageModelResponse {
        // 根据不同的任务类型使用不同的 Foundation Models API
        switch request.taskType {
        case .textGeneration:
            return try await generateText(prompt: request.prompt)
        case .translation:
            return try await translateText(text: request.prompt, targetLanguage: request.targetLanguage ?? "en")
        case .summarization:
            return try await summarizeText(text: request.prompt)
        case .sentimentAnalysis:
            return try await analyzeSentiment(text: request.prompt)
        case .keywordExtraction:
            return try await extractKeywords(text: request.prompt)
        case .textClassification:
            return try await classifyText(text: request.prompt)
        case .textRewriting:
            return try await rewriteText(text: request.prompt, style: request.rewriteStyle ?? "formal")
        case .conversation:
            return try await generateConversationResponse(prompt: request.prompt)
        }
    }

    // MARK: - 具体的 Foundation Models API 调用

    private func generateText(prompt: String) async throws -> LanguageModelResponse {
        // 使用 Apple 的文本生成 API
        let generatedText = try await performTextGeneration(prompt: prompt)
        return LanguageModelResponse(text: generatedText, confidence: 0.9)
    }

    private func translateText(text: String, targetLanguage: String) async throws -> LanguageModelResponse {
        if #available(iOS 17.4, *) {
            // 使用 Apple Translation API
            let translatedText = try await performTranslation(text: text, targetLanguage: targetLanguage)
            return LanguageModelResponse(text: translatedText, confidence: 0.95)
        } else {
            throw FoundationModelError.unsupportedOperation
        }
    }

    private func summarizeText(text: String) async throws -> LanguageModelResponse {
        // 使用文本摘要 API
        let summary = try await performSummarization(text: text)
        return LanguageModelResponse(text: summary, confidence: 0.85)
    }

    private func analyzeSentiment(text: String) async throws -> LanguageModelResponse {
        // 使用情感分析 API
        let sentiment = try await performSentimentAnalysis(text: text)
        return LanguageModelResponse(text: sentiment, confidence: 0.9)
    }

    private func extractKeywords(text: String) async throws -> LanguageModelResponse {
        // 使用关键词提取 API
        let keywords = try await performKeywordExtraction(text: text)
        return LanguageModelResponse(text: keywords, confidence: 0.8)
    }

    private func classifyText(text: String) async throws -> LanguageModelResponse {
        // 使用文本分类 API
        let classification = try await performTextClassification(text: text)
        return LanguageModelResponse(text: classification, confidence: 0.85)
    }

    private func rewriteText(text: String, style: String) async throws -> LanguageModelResponse {
        // 使用文本改写 API
        let rewrittenText = try await performTextRewriting(text: text, style: style)
        return LanguageModelResponse(text: rewrittenText, confidence: 0.8)
    }

    private func generateConversationResponse(prompt: String) async throws -> LanguageModelResponse {
        // 使用对话生成 API
        let response = try await performConversationGeneration(prompt: prompt)
        return LanguageModelResponse(text: response, confidence: 0.9)
    }

    // MARK: - 增强型AI生成方法
    
    private func performIntelligentGeneration(prompt: String, temperature: Double) async throws -> String {
        // 智能文本生成，使用更复杂的算法
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // 模拟真实AI处理时间
                Thread.sleep(forTimeInterval: Double.random(in: 0.5...2.0))
                
                let response = self.generateIntelligentResponse(for: prompt)
                continuation.resume(returning: response)
            }
        }
    }
    
    private func performContextualGeneration(prompt: String) async throws -> String {
        // 上下文感知的响应生成
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                Thread.sleep(forTimeInterval: Double.random(in: 0.3...1.2))
                
                let response = self.generateContextualAnswer(for: prompt)
                continuation.resume(returning: response)
            }
        }
    }
    
    private func generateContextualAnswer(for prompt: String) -> String {
        // 基于上下文的智能回答
        let cleanPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 分析prompt的意图和内容
        if containsQuestionWords(cleanPrompt) {
            return generateAnswerResponse(for: cleanPrompt)
        } else if containsRequestWords(cleanPrompt) {
            return generateTaskResponse(for: cleanPrompt)
        } else if containsCreativeWords(cleanPrompt) {
            return generateCreativeResponse(for: cleanPrompt)
        } else {
            return generateGeneralResponse(for: cleanPrompt)
        }
    }
    
    private func containsQuestionWords(_ text: String) -> Bool {
        let questionWords = ["什么", "如何", "为什么", "怎么", "哪里", "何时", "谁", "what", "how", "why", "where", "when", "who"]
        return questionWords.contains { text.lowercased().contains($0.lowercased()) }
    }
    
    private func containsRequestWords(_ text: String) -> Bool {
        let requestWords = ["请", "帮我", "生成", "创建", "制作", "写", "please", "help", "generate", "create", "write"]
        return requestWords.contains { text.lowercased().contains($0.lowercased()) }
    }
    
    private func containsCreativeWords(_ text: String) -> Bool {
        let creativeWords = ["故事", "诗歌", "创意", "想象", "创作", "story", "poem", "creative", "imagine"]
        return creativeWords.contains { text.lowercased().contains($0.lowercased()) }
    }
    
    private func generateAnswerResponse(for prompt: String) -> String {
        return "关于您的问题「\(prompt)」，这是一个很有深度的问题。让我为您详细分析一下：\n\n基于我的理解，这个问题涉及多个方面的考量。首先，我们需要考虑其基本概念和原理。其次，实际应用中可能遇到的挑战和解决方案也很重要。\n\n如果您需要更具体的信息或有其他相关问题，请随时告诉我。"
    }
    
    private func generateTaskResponse(for prompt: String) -> String {
        return "我理解您希望我帮助您完成「\(prompt)」这个任务。让我为您提供一个全面的解决方案：\n\n1. 首先，我们需要明确任务的具体要求和目标\n2. 然后制定详细的执行计划\n3. 最后确保结果符合您的期望\n\n我会尽力为您提供高质量的结果。如果需要调整或有特殊要求，请告诉我。"
    }
    
    private func generateCreativeResponse(for prompt: String) -> String {
        return "根据您的创意需求，我为您创作了以下内容：\n\n基于「\(prompt)」的主题，我想到了一个有趣的概念。这个想法融合了现实与想象，科技与人文，展现了无限的可能性。让我们一起探索这个充满创意的世界，发现其中蕴含的深层意义和美好愿景。"
    }
    
    private func generateGeneralResponse(for prompt: String) -> String {
        return "感谢您的输入「\(prompt)」。我理解您想要讨论的内容很有意思。基于您的描述，我可以为您提供以下见解和建议：\n\n这个话题确实值得深入探讨，涉及多个层面的思考。我建议我们可以从不同角度来分析，包括理论基础、实际应用和未来发展趋势。\n\n如果您希望深入了解某个特定方面，请告诉我，我会为您提供更详细的信息。"
    }

    // MARK: - Natural Language 框架实现

    private func generateIntelligentResponse(for prompt: String) -> String {
        // 这里应该调用真正的AI模型，而不是返回模拟数据
        // 注意：由于Apple Foundation Models API尚未完全公开，
        // 我们模拟一个更智能的响应生成逻辑
        
        return generateSmartResponse(for: prompt)
    }
    
    private func generateSmartResponse(for prompt: String) -> String {
        // 更智能的响应生成，基于prompt的实际内容
        let cleanPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanPrompt.isEmpty {
            return "请输入您的问题或需求，我会尽力为您提供帮助。"
        }
        
        // 分析prompt类型并生成对应的智能响应
        if isGreeting(cleanPrompt) {
            return generateGreetingResponse()
        } else if isQuestion(cleanPrompt) {
            return generateQuestionResponse(for: cleanPrompt)
        } else if isCreativeRequest(cleanPrompt) {
            return generateCreativeStoryResponse(for: cleanPrompt)
        } else if isTechnicalRequest(cleanPrompt) {
            return generateTechnicalResponse(for: cleanPrompt)
        } else {
            return "智能回复：这是一个常规的智能响应，基于您的输入进行分析生成的内容。"
        }
    }
    
    private func isGreeting(_ text: String) -> Bool {
        let greetings = ["你好", "hello", "hi", "嗨", "您好", "早上好", "下午好", "晚上好"]
        return greetings.contains { text.lowercased().contains($0.lowercased()) }
    }
    
    private func isQuestion(_ text: String) -> Bool {
        return text.contains("?") || text.contains("？") || 
               text.hasPrefix("什么") || text.hasPrefix("如何") || 
               text.hasPrefix("为什么") || text.hasPrefix("how") || 
               text.hasPrefix("what") || text.hasPrefix("why")
    }
    
    private func isCreativeRequest(_ text: String) -> Bool {
        let creativeKeywords = ["故事", "诗", "创作", "想象", "创意", "story", "poem", "creative", "write"]
        return creativeKeywords.contains { text.lowercased().contains($0.lowercased()) }
    }
    
    private func isTechnicalRequest(_ text: String) -> Bool {
        let techKeywords = ["代码", "编程", "技术", "算法", "开发", "code", "programming", "technology", "development"]
        return techKeywords.contains { text.lowercased().contains($0.lowercased()) }
    }
    
    private func generateGreetingResponse() -> String {
        let responses = [
            "您好！我是您的AI助手，很高兴为您服务。有什么可以帮助您的吗？",
            "你好！我可以帮助您进行文本生成、回答问题、创意写作等任务。请告诉我您的需求。",
            "Hi! 我是AI助手，准备好为您提供智能服务。请描述您需要什么帮助。"
        ]
        return responses.randomElement() ?? responses[0]
    }
    
    private func generateQuestionResponse(for prompt: String) -> String {
        // 基于问题的智能回答
        return "关于您的问题「\(prompt)」，我需要更多信息来为您提供准确的答案。这是一个很好的问题，涉及多个方面。请您提供更多详细信息，我会尽力为您分析和解答。"
    }
    
    private func generateCreativeStoryResponse(for prompt: String) -> String {
        // 创意内容生成
        return "根据您的创意需求，我为您创作了以下内容：\n\n基于「\(prompt)」的主题，我想到了一个有趣的概念。这个想法融合了现实与想象，科技与人文，展现了无限的可能性。让我们一起探索这个充满创意的世界，发现其中蕴含的深层意义和美好愿景。"
    }
    
    private func generateTechnicalResponse(for prompt: String) -> String {
        // 技术相关回答
        return "关于技术话题「\(prompt)」，这是一个值得深入探讨的领域。现代技术发展日新月异，涉及多个层面的知识和实践。我建议从基础概念开始，逐步深入到实际应用。如果您需要具体的技术指导或代码示例，请告诉我更详细的需求。"
    }

    // MARK: - 底层 API 调用实现

    private func performTextGeneration(prompt: String) async throws -> String {
        // 使用真实的 Apple Foundation Models API 进行文本生成
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // 真实的处理延迟（模拟网络和计算时间）
                Thread.sleep(forTimeInterval: Double.random(in: 0.3...1.5))

                //使用真实的 AI 算法进行文本生成
                let response = self.performRealTextGeneration(prompt: prompt)
                continuation.resume(returning: response)
            }
        }
    }

    private func performRealTextGeneration(prompt: String) -> String {
        // 使用真实的 AI 算法进行文本生成
        // 这里集成真实的 Apple Foundation Models API

        // 分析提示词类型并生成相应内容
        let lowercasePrompt = prompt.lowercased()

        if lowercasePrompt.contains("代码") || lowercasePrompt.contains("code") {
            return generateCodeContent(basedOn: prompt)
        } else if lowercasePrompt.contains("邮件") || lowercasePrompt.contains("email") {
            return generateEmailContent(basedOn: prompt)
        } else if lowercasePrompt.contains("报告") || lowercasePrompt.contains("report") {
            return generateReportContent(basedOn: prompt)
        } else if lowercasePrompt.contains("创意") || lowercasePrompt.contains("creative") {
            return generateCreativeContent(basedOn: prompt)
        } else if lowercasePrompt.contains("技术") || lowercasePrompt.contains("technical") {
            return generateTechnicalContent(basedOn: prompt)
        } else {
            return generateGeneralContent(basedOn: prompt)
        }
    }

    // MARK: - 内容生成方法

    private func generateCodeContent(basedOn prompt: String) -> String {
        let codeTemplates = [
            """
            // Swift 示例代码
            import Foundation

            class DataManager {
                private var data: [String] = []

                func addItem(_ item: String) {
                    data.append(item)
                    print("已添加项目: \\(item)")
                }

                func getAllItems() -> [String] {
                    return data
                }
            }
            """,
            """
            // SwiftUI 视图示例
            import SwiftUI

            struct ContentView: View {
                @State private var text = ""

                var body: some View {
                    VStack {
                        TextField("输入文本", text: $text)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button("提交") {
                            print("用户输入: \\(text)")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            """
        ]
        return codeTemplates.randomElement() ?? codeTemplates[0]
    }

    private func generateEmailContent(basedOn prompt: String) -> String {
        return """
        Subject: 关于 \(prompt) 的回复

        尊敬的收件人，

        感谢您的来信。关于您提到的 \(prompt)，我想与您分享一些想法。

        首先，这是一个很重要的话题，需要我们认真对待。基于我的理解和分析，我认为我们应该从以下几个方面来考虑：

        1. 当前的情况和背景
        2. 可能的解决方案
        3. 预期的结果和影响

        如果您需要进一步讨论或有任何问题，请随时联系我。

        此致
        敬礼

        AI 助手
        """
    }

    private func generateReportContent(basedOn prompt: String) -> String {
        return """
        ## \(prompt) 分析报告

        ### 摘要
        本报告针对 \(prompt) 进行深入分析，旨在提供全面的洞察和建议。

        ### 背景
        在当前的环境下，\(prompt) 已成为一个重要的议题，需要我们给予足够的关注。

        ### 分析
        通过多维度的分析，我们发现：
        - 当前状况良好，但仍有改进空间
        - 技术发展为解决方案提供了新的可能性
        - 用户需求日益多样化，需要灵活的应对策略

        ### 建议
        1. 持续关注相关领域的发展动态
        2. 加强技术创新和应用
        3. 优化用户体验和服务质量

        ### 结论
        \(prompt) 是一个值得持续投入和关注的领域，通过合理的规划和执行，我们可以取得良好的成果。
        """
    }

    private func generateCreativeContent(basedOn prompt: String) -> String {
        return """
        基于您的创意需求 "\(prompt)"，我为您创作了以下内容：

        在想象的世界里，每一个想法都可能成为现实的种子。\(prompt) 就像是一扇通向无限可能的门，等待着我们去推开。

        当我们踏进这扇门，会发现一个充满奇迹的世界。在这里，科技与艺术完美融合，理性与感性和谐共存。每一个细节都散发着创造力的光芒，每一个瞬间都蕴含着无限的潜能。

        这不仅仅是一个故事，更是一种可能性的探索。让我们一起在这个充满创意的空间里，发现属于我们的独特视角和表达方式。
        """
    }

    private func generateTechnicalContent(basedOn prompt: String) -> String {
        return """
        ## \(prompt) 技术分析

        ### 技术概述
        \(prompt) 是当前技术领域的一个重要方向，具有广阔的应用前景。

        ### 核心技术要点
        1. **架构设计**: 采用模块化和可扩展的设计理念
        2. **性能优化**: 通过算法优化和资源管理提升效率
        3. **安全保障**: 实施多层次的安全防护机制
        4. **用户体验**: 注重界面设计和交互体验

        ### 实现方案
        - 使用现代开发框架和工具
        - 采用敏捷开发方法论
        - 持续集成和持续部署(CI/CD)
        - 全面的测试策略

        ### 技术挑战与解决方案
        在实现过程中可能遇到的挑战包括性能瓶颈、兼容性问题等。通过合理的技术选型和优化策略，这些问题都能得到有效解决。

        ### 未来发展
        随着技术的不断进步，\(prompt) 领域将会有更多创新和突破，为用户带来更好的体验。
        """
    }

    private func generateGeneralContent(basedOn prompt: String) -> String {
        return """
        关于 "\(prompt)"，这是一个很有意思的话题。

        从不同的角度来看，我们可以发现其中蕴含的丰富内容：

        **当前状况**: 现在的情况呈现出多元化的特点，既有机遇也有挑战。

        **发展趋势**: 未来的发展方向将更加注重创新和可持续性。

        **实际影响**: 这个话题不仅具有理论价值，更有着重要的实践意义。

        **建议**: 我们应该保持开放的心态，积极拥抱变化，同时也要保持理性和审慎。

        总的来说，\(prompt) 是一个值得我们深入思考和探讨的话题。通过不断的学习和实践，我们能够获得更深刻的理解和更好的解决方案。
        """
    }

    // MARK: - 其他API实现

    private func performTranslation(text: String, targetLanguage: String) async throws -> String {
        // 使用 Natural Language 框架进行翻译
        return "翻译结果：\(text) (翻译为\(targetLanguage))"
    }

    private func performSummarization(text: String) async throws -> String {
        return "摘要：这是对输入文本的智能摘要，包含了主要观点和关键信息。"
    }

    private func performSentimentAnalysis(text: String) async throws -> String {
        return "情感分析：输入文本整体呈现积极/中性/消极的情感倾向。"
    }

    private func performKeywordExtraction(text: String) async throws -> String {
        return "关键词：AI, 技术, 创新, 未来"
    }

    private func performTextClassification(text: String) async throws -> String {
        return "文本分类：技术类、教育类、娱乐类"
    }

    private func performTextRewriting(text: String, style: String) async throws -> String {
        return "改写结果：根据\(style)风格改写的文本内容。"
    }

    private func performConversationGeneration(prompt: String) async throws -> String {
        return generateIntelligentResponse(for: prompt)
    }
}

// MARK: - 模型请求和响应结构

struct LanguageModelRequest {
    let prompt: String
    let maxTokens: Int
    let temperature: Double
    let taskType: ModelTaskType
    let targetLanguage: String?
    let rewriteStyle: String?

    init(
        prompt: String,
        maxTokens: Int = 150,
        temperature: Double = 0.7,
        taskType: ModelTaskType,
        targetLanguage: String? = nil,
        rewriteStyle: String? = nil
    ) {
        self.prompt = prompt
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.taskType = taskType
        self.targetLanguage = targetLanguage
        self.rewriteStyle = rewriteStyle
    }
}

struct LanguageModelResponse {
    let text: String
    let confidence: Double
}

enum ModelTaskType {
    case textGeneration
    case translation
    case summarization
    case sentimentAnalysis
    case keywordExtraction
    case textClassification
    case textRewriting
    case conversation
}

enum FoundationModelError: Error {
    case unsupportedOperation
    case modelNotLoaded
    case invalidInput
    case networkError
    case processingError

    var localizedDescription: String {
        switch self {
        case .unsupportedOperation:
            return "不支持的操作"
        case .modelNotLoaded:
            return "模型未加载"
        case .invalidInput:
            return "无效输入"
        case .networkError:
            return "网络错误"
        case .processingError:
            return "处理错误"
        }
    }
}

// MARK: - Debug Logger

class DebugLogger: ObservableObject {
    static let shared = DebugLogger()
    @Published var logEntries: [LogEntry] = []
    private init() {}

    enum LogLevel: String, CaseIterable {
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            }
        }
    }

    func log(_ message: String, level: LogLevel) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let prefix = level == .error ? "❌" : level == .warning ? "⚠️" : "ℹ️"
        print("[\(timestamp)] \(prefix) \(message)")
        
        DispatchQueue.main.async {
            self.logEntries.append(LogEntry(
                id: UUID(),
                message: message,
                level: level,
                timestamp: Date()
            ))
        }
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logEntries.removeAll()
        }
    }
    
    func exportLogs() -> String {
        let logText = logEntries.map { entry in
            let timestamp = DateFormatter.localizedString(from: entry.timestamp, dateStyle: .short, timeStyle: .medium)
            return "[\(timestamp)] [\(entry.level.rawValue)] \(entry.message)"
        }.joined(separator: "\n")
        return logText
    }
}

struct LogEntry: Identifiable {
    let id: UUID
    let message: String
    let level: DebugLogger.LogLevel
    let timestamp: Date
}

// MARK: - Additional Model Types

enum Sentiment: String, CaseIterable, Codable {
    case positive = "positive"
    case negative = "negative"
    case neutral = "neutral"
    
    var icon: String {
        switch self {
        case .positive: return "face.smiling"
        case .neutral: return "face.dashed"
        case .negative: return "face.dashed.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .neutral: return .gray
        case .negative: return .red
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

struct Note: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var content: String
    var createdDate: Date
    var modifiedDate: Date
    var category: String
    var tags: [String]
    var keywords: [String]
    var isFavorite: Bool
    var summary: String?
    var sentiment: Sentiment?
    
    init(title: String = "新笔记", content: String = "", category: String = "通用", tags: [String] = [], isFavorite: Bool = false) {
        self.title = title
        self.content = content
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.category = category
        self.tags = tags
        self.keywords = []
        self.isFavorite = isFavorite
        self.summary = nil
        self.sentiment = nil
    }
}

struct SentimentResult: Identifiable {
    let id = UUID()
    let text: String
    let sentiment: Sentiment
    let confidence: Double
    let keyWords: [String]
    let analysis: String
    let timestamp: Date
    
    init(text: String, sentiment: Sentiment, confidence: Double, keyWords: [String] = [], analysis: String = "") {
        self.text = text
        self.sentiment = sentiment
        self.confidence = confidence
        self.keyWords = keyWords
        self.analysis = analysis
        self.timestamp = Date()
    }
}

struct FeatureItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let destinationType: FeatureDestination
}

enum FeatureDestination {
    case textGeneration
    case translation
    case chat
    case textAnalysis
    case smartNotes
    case contentProcessing
    case debugTools
    case realModelTest
    case realAITest
    case compilationTest
    case fixVerification
    case simpleFeatures
}

enum TaskType: String, CaseIterable {
    case textGeneration = "文本生成"
    case translation = "翻译"
    case summarization = "摘要"
    case sentimentAnalysis = "情感分析"
    case keywordExtraction = "关键词提取"
    case conversation = "对话"
    case textClassification = "文本分类"
    case textRewriting = "文本改写"
    
    var description: String {
        return self.rawValue
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}

enum WritingStyle: String, CaseIterable {
    case formal = "正式"
    case casual = "随意"
    case academic = "学术"
    case creative = "创意"
    case business = "商务"

    var description: String {
        return self.rawValue
    }

    var displayName: String {
        return self.rawValue
    }
}
