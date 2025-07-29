import Foundation

// 模拟 Apple Foundation Models Framework
// 这是一个模拟实现，用于演示目的

struct MockLanguageModel {
    static var isSupported: Bool {
        // 模拟设备支持检查
        return true
    }
    
    init() throws {
        // 模拟初始化过程
    }
    
    func generate(_ request: MockLanguageModelRequest) async throws -> MockLanguageModelResponse {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...2_000_000_000))
        
        // 模拟生成响应
        let response = generateMockResponse(for: request)
        return MockLanguageModelResponse(text: response)
    }
    
    private func generateMockResponse(for request: MockLanguageModelRequest) -> String {
        let prompt = request.prompt.lowercased()
        
        // 根据提示词类型生成不同的模拟响应
        if prompt.contains("情感") || prompt.contains("sentiment") {
            return ["positive", "negative", "neutral"].randomElement() ?? "neutral"
        } else if prompt.contains("摘要") || prompt.contains("总结") {
            return "这是一个智能生成的文本摘要，展示了原文的核心内容和主要观点。"
        } else if prompt.contains("关键词") {
            return "人工智能, 机器学习, 深度学习, 神经网络, 自然语言处理"
        } else if prompt.contains("翻译") {
            if prompt.contains("英文") || prompt.contains("english") {
                return "This is a translated text demonstrating the translation capabilities."
            } else {
                return "这是一个翻译后的文本，展示了翻译功能。"
            }
        } else if prompt.contains("改写") || prompt.contains("rewrite") {
            return "这是经过智能改写的文本，保持了原意但采用了不同的表达方式。"
        } else if prompt.contains("创意") || prompt.contains("故事") {
            return "在一个遥远的未来，人工智能与人类和谐共存，共同创造着美好的世界。科技的发展让生活变得更加便利，而人类的创造力依然是推动社会进步的重要力量。"
        } else if prompt.contains("聊天") || prompt.contains("对话") {
            return "我是您的AI助手，很高兴为您服务！我可以帮助您处理各种文本相关的任务，包括写作、分析、翻译等。请告诉我您需要什么帮助。"
        } else {
            // 默认创意文本生成
            let responses = [
                "人工智能正在改变我们的世界，从日常生活到工作方式，AI技术都在发挥着重要作用。",
                "创新是推动社会进步的动力，而技术的发展为我们提供了无限的可能性。",
                "在数字化时代，我们需要学会与技术和谐共处，利用AI的力量来提升生活质量。",
                "教育的未来将更加个性化，AI助手可以为每个学习者提供定制化的学习体验。",
                "可持续发展是我们共同的目标，技术创新可以帮助我们建设更加绿色的未来。"
            ]
            return responses.randomElement() ?? responses[0]
        }
    }
}

struct MockLanguageModelRequest {
    let prompt: String
    let maxTokens: Int
    let temperature: Double
    
    init(prompt: String, maxTokens: Int = 150, temperature: Double = 0.7) {
        self.prompt = prompt
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}

struct MockLanguageModelResponse {
    let text: String
}

// MARK: - 数据模型

struct SentimentResult {
    let text: String
    let sentiment: Sentiment
    let confidence: Double
}

enum Sentiment: String, CaseIterable {
    case positive = "positive"
    case negative = "negative"
    case neutral = "neutral"
    
    var displayName: String {
        switch self {
        case .positive: return "积极"
        case .negative: return "消极"
        case .neutral: return "中性"
        }
    }
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .positive: return "😊"
        case .negative: return "😔"
        case .neutral: return "😐"
        }
    }
}

enum WritingStyle: String, CaseIterable {
    case formal = "formal"
    case casual = "casual"
    case academic = "academic"
    case creative = "creative"
    case business = "business"
    
    var displayName: String {
        switch self {
        case .formal: return "正式"
        case .casual: return "随意"
        case .academic: return "学术"
        case .creative: return "创意"
        case .business: return "商务"
        }
    }
    
    var description: String {
        switch self {
        case .formal: return "正式、严谨"
        case .casual: return "轻松、随意"
        case .academic: return "学术、专业"
        case .creative: return "创意、生动"
        case .business: return "商务、专业"
        }
    }
}

// MARK: - 聊天消息模型

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    init(text: String, isUser: Bool, timestamp: Date = Date()) {
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// MARK: - 笔记模型

struct Note: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var content: String
    var summary: String?
    var sentiment: Sentiment?
    var keywords: [String] = []
    let createdAt = Date()
    var updatedAt = Date()
    
    init(title: String, content: String) {
        self.title = title
        self.content = content
    }
}

// MARK: - 功能项模型

struct FeatureItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let destination: AnyView
    
    init<Destination: View>(
        title: String,
        description: String,
        icon: String,
        color: Color,
        destination: Destination
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.destination = AnyView(destination)
    }
}

// MARK: - 错误处理

enum FoundationModelsError: LocalizedError {
    case modelNotSupported
    case modelNotLoaded
    case requestFailed(String)
    case quotaExceeded
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .modelNotSupported:
            return "设备不支持 Foundation Models"
        case .modelNotLoaded:
            return "模型未加载"
        case .requestFailed(let message):
            return "请求失败: \(message)"
        case .quotaExceeded:
            return "已超出使用配额"
        case .networkError:
            return "网络连接错误"
        }
    }
}

import SwiftUI

// MARK: - 调试日志管理器

class DebugLogger: ObservableObject {
    static let shared = DebugLogger()

    @Published var logs: [LogEntry] = []

    private init() {}

    func log(_ message: String, level: LogLevel = .info) {
        let entry = LogEntry(
            message: message,
            level: level,
            timestamp: Date()
        )

        DispatchQueue.main.async {
            self.logs.append(entry)

            // 保持最近1000条日志
            if self.logs.count > 1000 {
                self.logs.removeFirst(self.logs.count - 1000)
            }
        }

        #if DEBUG
        print("[\(level.rawValue)] \(message)")
        #endif
    }

    func clearLogs() {
        logs.removeAll()
    }

    func exportLogs() -> String {
        return logs.map { entry in
            "[\(DateFormatter.localizedString(from: entry.timestamp, dateStyle: .short, timeStyle: .medium))] [\(entry.level.rawValue)] \(entry.message)"
        }.joined(separator: "\n")
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let level: LogLevel
    let timestamp: Date
}

enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"

    var color: Color {
        switch self {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}
