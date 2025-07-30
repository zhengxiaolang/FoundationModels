import SwiftUI

struct ContentProcessingView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TextRewritingView()
                .environmentObject(assistant)
                .tabItem {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("文本改写")
                }
                .tag(0)

            ContentProcessingTranslationView()
                .environmentObject(assistant)
                .tabItem {
                    Image(systemName: "globe")
                    Text("语言翻译")
                }
                .tag(1)

            FormatConversionView()
                .environmentObject(assistant)
                .tabItem {
                    Image(systemName: "doc.text.below.ecg")
                    Text("格式转换")
                }
                .tag(2)
        }
        .navigationTitle("内容处理")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TextRewritingView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var inputText = ""
    @State private var rewrittenText = ""
    @State private var selectedStyle = WritingStyle.formal
    @State private var isRewriting = false
    
    private let sampleTexts = [
        "这个产品的性能非常好，我很满意。",
        "会议将在明天上午9点开始，请准时参加。",
        "我们需要尽快完成这个项目，时间很紧迫。"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            inputSection
            styleSelectionSection
            rewriteButton
            resultSection
            Spacer()
        }
        .padding()
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("原文内容")
                .font(.headline)
            
            TextEditor(text: $inputText)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
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
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var styleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("改写风格")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WritingStyle.allCases, id: \.self) { style in
                        Button(action: {
                            selectedStyle = style
                        }) {
                            VStack(spacing: 4) {
                                Text(style.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Text(style.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedStyle == style ? Color.orange : Color(.systemGray6)
                            )
                            .foregroundColor(
                                selectedStyle == style ? .white : .primary
                            )
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var rewriteButton: some View {
        Button(action: rewriteText) {
            HStack {
                if isRewriting {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Text(isRewriting ? "改写中..." : "开始改写")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(inputText.isEmpty ? Color.gray : Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(inputText.isEmpty || isRewriting)
    }
    
    @ViewBuilder
    private var resultSection: some View {
        if !rewrittenText.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("改写结果")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("复制") {
                        UIPasteboard.general.string = rewrittenText
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(16)
                }
                
                ScrollView {
                    VStack(spacing: 12) {
                        // 原文
                        VStack(alignment: .leading, spacing: 4) {
                            Text("原文")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(inputText)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        Image(systemName: "arrow.down")
                            .foregroundColor(.orange)
                        
                        // 改写后
                        VStack(alignment: .leading, spacing: 4) {
                            Text("改写后 (\(selectedStyle.displayName))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(rewrittenText)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private func rewriteText() {
        isRewriting = true
        
        Task {
            if let result = await assistant.rewriteText(inputText, style: selectedStyle.rawValue) {
                await MainActor.run {
                    rewrittenText = result
                    isRewriting = false
                }
            } else {
                await MainActor.run {
                    isRewriting = false
                }
            }
        }
    }
}

struct ContentProcessingTranslationView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var targetLanguage = "英文"
    @State private var isTranslating = false
    
    private let languages = ["英文", "日文", "韩文", "法文", "德文", "西班牙文", "俄文", "阿拉伯文"]
    
    private let sampleTexts = [
        "你好，很高兴认识你！",
        "今天天气真不错，适合出去走走。",
        "我正在学习人工智能相关的知识。",
        "这个应用程序非常有用。"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // 输入区域
            VStack(alignment: .leading, spacing: 8) {
                Text("待翻译文本")
                    .font(.headline)
                
                TextEditor(text: $inputText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
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
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 目标语言选择
            VStack(alignment: .leading, spacing: 8) {
                Text("目标语言")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(languages, id: \.self) { language in
                            Button(language) {
                                targetLanguage = language
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                targetLanguage == language ? Color.blue : Color(.systemGray6)
                            )
                            .foregroundColor(
                                targetLanguage == language ? .white : .primary
                            )
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 翻译按钮
            Button(action: translateText) {
                HStack {
                    if isTranslating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isTranslating ? "翻译中..." : "开始翻译")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(inputText.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(inputText.isEmpty || isTranslating)
            
            // 翻译结果
            if !translatedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("翻译结果")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("复制") {
                            UIPasteboard.general.string = translatedText
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(16)
                    }
                    
                    VStack(spacing: 12) {
                        // 原文
                        VStack(alignment: .leading, spacing: 4) {
                            Text("原文 (中文)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(inputText)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        Image(systemName: "arrow.down")
                            .foregroundColor(.blue)
                        
                        // 翻译结果
                        VStack(alignment: .leading, spacing: 4) {
                            Text("翻译 (\(targetLanguage))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(translatedText)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func translateText() {
        isTranslating = true
        
        Task {
            if let result = await assistant.translateText(inputText, to: targetLanguage) {
                await MainActor.run {
                    translatedText = result
                    isTranslating = false
                }
            } else {
                await MainActor.run {
                    isTranslating = false
                }
            }
        }
    }
}

struct FormatConversionView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var inputText = ""
    @State private var convertedText = ""
    @State private var selectedFormat = TextFormat.markdown
    @State private var isConverting = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 输入区域
            VStack(alignment: .leading, spacing: 8) {
                Text("原始文本")
                    .font(.headline)
                
                TextEditor(text: $inputText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // 格式选择
            VStack(alignment: .leading, spacing: 8) {
                Text("目标格式")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    ForEach(TextFormat.allCases, id: \.self) { format in
                        Button(format.displayName) {
                            selectedFormat = format
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedFormat == format ? Color.purple : Color(.systemGray6)
                        )
                        .foregroundColor(
                            selectedFormat == format ? .white : .primary
                        )
                        .cornerRadius(16)
                    }
                }
            }
            
            // 转换按钮
            Button(action: convertFormat) {
                HStack {
                    if isConverting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isConverting ? "转换中..." : "格式转换")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(inputText.isEmpty ? Color.gray : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(inputText.isEmpty || isConverting)
            
            // 转换结果
            if !convertedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("转换结果")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("复制") {
                            UIPasteboard.general.string = convertedText
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(16)
                    }
                    
                    ScrollView {
                        Text(convertedText)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func convertFormat() {
        isConverting = true
        
        let prompt = """
        请将以下文本转换为\(selectedFormat.description)格式：
        
        \(inputText)
        
        转换后的\(selectedFormat.displayName)格式：
        """
        
        Task {
            if let result = await assistant.generateText(
                prompt: prompt,
                maxTokens: inputText.count * 2,
                temperature: 0.3
            ) {
                await MainActor.run {
                    convertedText = result
                    isConverting = false
                }
            } else {
                await MainActor.run {
                    isConverting = false
                }
            }
        }
    }
}

enum TextFormat: String, CaseIterable {
    case markdown = "markdown"
    case html = "html"
    case json = "json"
    case csv = "csv"
    
    var displayName: String {
        switch self {
        case .markdown: return "Markdown"
        case .html: return "HTML"
        case .json: return "JSON"
        case .csv: return "CSV"
        }
    }
    
    var description: String {
        switch self {
        case .markdown: return "Markdown标记语言"
        case .html: return "HTML网页标记"
        case .json: return "JSON数据格式"
        case .csv: return "CSV表格格式"
        }
    }
}

#Preview {
    NavigationView {
        ContentProcessingView()
            .environmentObject(AIAssistant())
    }
}
