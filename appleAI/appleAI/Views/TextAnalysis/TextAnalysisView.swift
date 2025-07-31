import SwiftUI

struct TextAnalysisView: View {
    @EnvironmentObject var assistant: AIAssistant
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SentimentAnalysisView()
                .environmentObject(assistant)
                .environmentObject(keyboardManager)
                .tabItem {
                    Image(systemName: "heart.text.square")
                    Text("情感分析")
                }
                .tag(0)

            KeywordExtractionView()
                .environmentObject(assistant)
                .environmentObject(keyboardManager)
                .tabItem {
                    Image(systemName: "tag")
                    Text("关键词提取")
                }
                .tag(1)

            TextClassificationView()
                .environmentObject(assistant)
                .environmentObject(keyboardManager)
                .tabItem {
                    Image(systemName: "folder.badge.questionmark")
                    Text("文本分类")
                }
                .tag(2)
        }
        .navigationTitle("文本分析")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SentimentAnalysisView: View {
    @EnvironmentObject var assistant: AIAssistant
    @EnvironmentObject var keyboardManager: KeyboardManager
    @StateObject private var textManager = TextGenerationManager()
    @State private var inputText = ""
    @State private var analysisResult = ""
    @State private var sentimentResult: SentimentResult?
    @State private var analysisHistory: [SentimentResult] = []
    @FocusState private var isTextEditorFocused: Bool
    
    private let sampleTexts = [
        "今天天气真好，心情特别愉快！",
        "这部电影太无聊了，完全浪费时间。",
        "这个产品的质量还算可以，价格也合理。",
        "工作进展顺利，团队合作很愉快。"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 输入区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("待分析文本")
                            .font(.headline)
                        
                        Spacer()
                        
                        // 键盘关闭按钮
                        if keyboardManager.isKeyboardVisible {
                            Button(action: {
                                keyboardManager.dismissKeyboard()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "keyboard.chevron.compact.down")
                                    Text("关闭键盘")
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    TextEditor(text: $inputText)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($isTextEditorFocused)
                    
                    // 示例文本
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sampleTexts, id: \.self) { sample in
                                Button(sample) {
                                    inputText = sample
                                    keyboardManager.dismissKeyboard()
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 分析按钮
                Button(action: analyzeSentiment) {
                    HStack {
                        if textManager.isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(textManager.isProcessing ? "分析中..." : "开始分析")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputText.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(inputText.isEmpty || textManager.isProcessing)
                
                // 分析结果
                if let result = sentimentResult {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("分析结果")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("复制结果") {
                                UIPasteboard.general.string = result.analysis
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                        }
                        
                        // 情感结果卡片
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: result.sentiment.icon)
                                    .foregroundColor(result.sentiment.color)
                                
                                Text(result.sentiment.displayName.capitalized)
                                    .font(.headline)
                                    .foregroundColor(result.sentiment.color)
                                
                                Spacer()
                                
                                Text("置信度: \(String(format: "%.1f", result.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(result.analysis)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(result.sentiment.color.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // 历史记录
                if !analysisHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("分析历史")
                            .font(.headline)
                        
                        ForEach(analysisHistory.prefix(3)) { result in
                            HStack {
                                Image(systemName: result.sentiment.icon)
                                    .foregroundColor(result.sentiment.color)
                                
                                Text(result.text.prefix(30) + (result.text.count > 30 ? "..." : ""))
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(result.sentiment.displayName)
                                    .font(.caption)
                                    .foregroundColor(result.sentiment.color)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .scrollViewKeyboardAware()
    }
    
    private func analyzeSentiment() {
        guard !inputText.isEmpty else { return }
        
        Task {
            do {
                // 使用 TextGenerationManager 的情感分析
                let result = try await textManager.analyzeSentiment(text: inputText)
                
                await MainActor.run {
                    // 创建简单的情感结果（这里应该解析AI的回复）
                    let sentiment: Sentiment = result.lowercased().contains("积极") ? .positive : 
                                             result.lowercased().contains("消极") ? .negative : .neutral
                    
                    let sentimentResult = SentimentResult(
                        text: inputText,
                        sentiment: sentiment,
                        confidence: 0.85,
                        keyWords: [], // 可以从AI回复中提取
                        analysis: result
                    )
                    
                    self.sentimentResult = sentimentResult
                    analysisHistory.insert(sentimentResult, at: 0)
                    if analysisHistory.count > 10 {
                        analysisHistory.removeLast()
                    }
                }
            } catch {
                await MainActor.run {
                    // 创建错误结果
                    let errorResult = SentimentResult(
                        text: inputText,
                        sentiment: .neutral,
                        confidence: 0.0,
                        keyWords: [],
                        analysis: "分析失败：\(error.localizedDescription)"
                    )
                    self.sentimentResult = errorResult
                }
                print("情感分析失败: \(error)")
            }
        }
    }
}

struct KeywordExtractionView: View {
    @EnvironmentObject var assistant: AIAssistant
    @EnvironmentObject var keyboardManager: KeyboardManager
    @StateObject private var textManager = TextGenerationManager()
    @State private var inputText = ""
    @State private var keywords: [String] = []
    @FocusState private var isTextEditorFocused: Bool
    
    private let sampleTexts = [
        "人工智能技术正在快速发展，机器学习和深度学习算法在各个领域都有广泛应用。",
        "可持续发展是当今世界面临的重要挑战，需要通过技术创新和政策改革来实现。",
        "移动互联网改变了人们的生活方式，智能手机成为了日常生活中不可缺少的工具。"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 输入区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("待提取文本")
                            .font(.headline)
                        
                        Spacer()
                        
                        if keyboardManager.isKeyboardVisible {
                            Button(action: {
                                keyboardManager.dismissKeyboard()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "keyboard.chevron.compact.down")
                                    Text("关闭键盘")
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    TextEditor(text: $inputText)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($isTextEditorFocused)
                    
                    // 示例文本
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sampleTexts, id: \.self) { sample in
                                Button(sample) {
                                    inputText = sample
                                    keyboardManager.dismissKeyboard()
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 提取按钮
                Button(action: extractKeywords) {
                    HStack {
                        if textManager.isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(textManager.isProcessing ? "提取中..." : "提取关键词")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputText.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(inputText.isEmpty || textManager.isProcessing)
                
                // 关键词结果
                if !keywords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("提取的关键词")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("复制全部") {
                                UIPasteboard.general.string = keywords.joined(separator: ", ")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(16)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 80))
                        ], spacing: 8) {
                            ForEach(keywords, id: \.self) { keyword in
                                KeywordTag(keyword: keyword)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .scrollViewKeyboardAware()
    }
    
    private func extractKeywords() {
        guard !inputText.isEmpty else { return }
        
        Task {
            do {
                // 使用 TextGenerationManager 的关键词提取
                let result = try await textManager.extractKeywords(text: inputText)
                
                await MainActor.run {
                    // 简单解析关键词（应该从AI回复中提取）
                    let extractedKeywords = result.components(separatedBy: CharacterSet(charactersIn: ",，\n"))
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                        .prefix(10) // 限制最多10个关键词
                    
                    keywords = Array(extractedKeywords)
                }
            } catch {
                await MainActor.run {
                    keywords = ["提取失败：\(error.localizedDescription)"]
                }
                print("关键词提取失败: \(error)")
            }
        }
    }
}

struct KeywordTag: View {
    let keyword: String
    
    var body: some View {
        Text(keyword)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(16)
    }
}

struct TextClassificationView: View {
    @EnvironmentObject var assistant: AIAssistant
    @EnvironmentObject var keyboardManager: KeyboardManager
    @StateObject private var textManager = TextGenerationManager()
    @State private var inputText = ""
    @State private var classification = ""
    @FocusState private var isTextEditorFocused: Bool
    
    private let classificationSamples = [
        "苹果公司发布了最新的iPhone 15系列，配备了全新的A17芯片。",
        "梅西在世界杯决赛中打进关键进球，帮助阿根廷夺冠。",
        "《阿凡达：水之道》票房突破20亿美元大关。",
        "美联储宣布加息0.25个百分点，全球股市出现波动。",
        "清华大学研究团队在量子计算领域取得重大突破。",
        "地中海饮食有助于降低心血管疾病风险。"
    ]
    
    private let categories = ["新闻", "科技", "娱乐", "体育", "财经", "教育", "健康", "旅游"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 输入区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("待分类文本")
                            .font(.headline)
                        
                        Spacer()
                        
                        // 键盘关闭按钮
                        if keyboardManager.isKeyboardVisible {
                            Button(action: {
                                keyboardManager.dismissKeyboard()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "keyboard.chevron.compact.down")
                                    Text("关闭键盘")
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    TextEditor(text: $inputText)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($isTextEditorFocused)
                    
                    // 示例文本
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(classificationSamples, id: \.self) { sample in
                                Button(sample) {
                                    inputText = sample
                                    keyboardManager.dismissKeyboard()
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 分类按钮
                Button(action: classifyText) {
                    HStack {
                        if textManager.isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(textManager.isProcessing ? "分类中..." : "开始分类")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputText.isEmpty ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(inputText.isEmpty || textManager.isProcessing)
                
                // 分类结果
                if !classification.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("分类结果")
                            .font(.headline)
                        
                        Text(classification)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .scrollViewKeyboardAware()
    }
    
    private func classifyText() {
        guard !inputText.isEmpty else { return }
        
        Task {
            do {
                // 使用 TextGenerationManager 的文本分类
                let result = try await textManager.classifyText(text: inputText)
                
                await MainActor.run {
                    classification = result
                }
            } catch {
                await MainActor.run {
                    classification = "分类失败：\(error.localizedDescription)"
                }
                print("文本分类失败: \(error)")
            }
        }
    }
}

#Preview {
    TextAnalysisView()
        .environmentObject(AIAssistant())
}
