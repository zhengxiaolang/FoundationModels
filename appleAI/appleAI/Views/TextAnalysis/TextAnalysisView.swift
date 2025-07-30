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
    @State private var isAnalyzing = false
    @FocusState private var isTextEditorFocused: Bool
    
    private let sampleTexts = [
        "今天天气真好，心情特别愉快！",
        "这个产品质量太差了，非常失望。",
        "会议内容比较中性，没有特别的感受。",
        "收到了朋友的生日祝福，感到很温暖。",
        "工作压力很大，感觉有些疲惫。"
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
                                isTextEditorFocused = false
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
                        .frame(minHeight: 100)
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
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(16)
                                .lineLimit(1)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 分析按钮
                Button(action: analyzeSentiment) {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isAnalyzing ? "分析中..." : "分析情感")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputText.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(inputText.isEmpty || isAnalyzing)
                
                // 分析结果
                if let result = sentimentResult {
                    SentimentResultCard(result: result)
                }
                
                // 历史记录
                if !analysisHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("分析历史")
                            .font(.headline)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(analysisHistory.indices, id: \.self) { index in
                                let result = analysisHistory[index]
                                SentimentHistoryCard(result: result)
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
            .padding()
        }
        .scrollViewKeyboardAware()
    }
    
    private func analyzeSentiment() {
        isAnalyzing = true
        
        Task {
            if let result = await assistant.analyzeSentiment(text: inputText) {
                await MainActor.run {
                    sentimentResult = result
                    analysisHistory.insert(result, at: 0)
                    if analysisHistory.count > 10 {
                        analysisHistory.removeLast()
                    }
                    isAnalyzing = false
                }
            } else {
                await MainActor.run {
                    isAnalyzing = false
                }
            }
        }
    }
}

struct SentimentResultCard: View {
    let result: SentimentResult
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("情感分析结果")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                // 情感图标和标签
                VStack(spacing: 8) {
                    Text(result.sentiment.icon)
                        .font(.system(size: 40))
                    
                    Text(result.sentiment.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(result.sentiment.color)
                }
                
                Spacer()
                
                // 置信度
                VStack(alignment: .trailing, spacing: 4) {
                    Text("置信度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(result.confidence * 100))%")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    // 置信度进度条
                    ProgressView(value: result.confidence)
                        .progressViewStyle(LinearProgressViewStyle(tint: result.sentiment.color))
                        .frame(width: 80)
                }
            }
            
            // 分析文本预览
            Text(result.text)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(result.sentiment.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(result.sentiment.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SentimentHistoryCard: View {
    let result: SentimentResult
    
    var body: some View {
        HStack(spacing: 12) {
            Text(result.sentiment.icon)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.text)
                    .font(.caption)
                    .lineLimit(1)
                
                Text(result.sentiment.displayName)
                    .font(.caption2)
                    .foregroundColor(result.sentiment.color)
            }
            
            Spacer()
            
            Text("\(Int(result.confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct KeywordExtractionView: View {
    @EnvironmentObject var assistant: AIAssistant
    @EnvironmentObject var keyboardManager: KeyboardManager
    @State private var inputText = ""
    @State private var keywords: [String] = []
    @State private var isExtracting = false
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
                        Text("待分析文本")
                            .font(.headline)
                        
                        Spacer()
                        
                        // 键盘关闭按钮
                        if keyboardManager.isKeyboardVisible {
                            Button(action: {
                                keyboardManager.dismissKeyboard()
                                isTextEditorFocused = false
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("示例文本:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(sampleTexts, id: \.self) { sample in
                            Button(sample) {
                                inputText = sample
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                        }
                    }
                }
                
                // 提取按钮
                Button(action: extractKeywords) {
                    HStack {
                        if isExtracting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isExtracting ? "提取中..." : "提取关键词")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputText.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(inputText.isEmpty || isExtracting)
                
                // 关键词结果
                if !keywords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("提取的关键词")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(keywords.count)个")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // 关键词标签云
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(keywords, id: \.self) { keyword in
                                KeywordTag(keyword: keyword)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .scrollViewKeyboardAware()
    }
    
    private func extractKeywords() {
        isExtracting = true
        
        Task {
            if let result = await assistant.extractKeywords(from: inputText) {
                await MainActor.run {
                    keywords = result
                    isExtracting = false
                }
            } else {
                await MainActor.run {
                    isExtracting = false
                }
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
    @State private var inputText = ""
    @State private var classification = ""
    @State private var isClassifying = false
    @FocusState private var isTextEditorFocused: Bool
    
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
                                isTextEditorFocused = false
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
                }
                
                // 分类按钮
                Button(action: classifyText) {
                    HStack {
                        if isClassifying {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isClassifying ? "分类中..." : "文本分类")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputText.isEmpty ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(inputText.isEmpty || isClassifying)
                
                // 分类结果
                if !classification.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("分类结果")
                            .font(.headline)
                        
                        Text(classification)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                // 预定义分类
                VStack(alignment: .leading, spacing: 8) {
                    Text("常见分类")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(16)
                        }
                    }
                }
            }
            .padding()
        }
        .scrollViewKeyboardAware()
    }
    
    private func classifyText() {
        isClassifying = true
        
        let prompt = """
        请将以下文本分类到最合适的类别中，从这些选项中选择：\(categories.joined(separator: "、"))
        
        文本：\(inputText)
        
        分类：
        """
        
        Task {
            if let result = await assistant.generateText(
                prompt: prompt,
                maxTokens: 20,
                temperature: 0.1
            ) {
                await MainActor.run {
                    classification = result.trimmingCharacters(in: .whitespacesAndNewlines)
                    isClassifying = false
                }
            } else {
                await MainActor.run {
                    isClassifying = false
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        TextAnalysisView()
            .environmentObject(AIAssistant())
    }
}
