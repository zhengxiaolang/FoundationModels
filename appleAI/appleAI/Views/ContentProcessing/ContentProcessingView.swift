import SwiftUI
import FoundationModels

struct ContentProcessingView: View {
    @EnvironmentObject var assistant: AIAssistant
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TextRewritingView()
                .environmentObject(assistant)
                .environmentObject(keyboardManager)
                .tabItem {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("文本改写")
                }
                .tag(0)

            ContentProcessingTranslationView()
                .environmentObject(assistant)
                .environmentObject(keyboardManager)
                .tabItem {
                    Image(systemName: "globe")
                    Text("语言翻译")
                }
                .tag(1)

            FormatConversionView()
                .environmentObject(assistant)
                .environmentObject(keyboardManager)
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
    @StateObject private var textManager = TextGenerationManager()
    @State private var inputText = ""
    @State private var rewrittenText = ""
    @State private var selectedStyle = WritingStyle.formal
    
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
                if textManager.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Text(textManager.isProcessing ? "改写中..." : "开始改写")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(inputText.isEmpty ? Color.gray : Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(inputText.isEmpty || textManager.isProcessing)
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
        guard !inputText.isEmpty else { return }
        
        Task {
            do {
                // 使用 TextGenerationManager 的文本改写
                let result = try await textManager.generateRewrite(
                    text: inputText,
                    style: selectedStyle.rawValue
                )
                
                await MainActor.run {
                    rewrittenText = result
                }
            } catch {
                await MainActor.run {
                    rewrittenText = "改写失败：\(error.localizedDescription)"
                }
                print("文本改写失败: \(error)")
            }
        }
    }
}

struct ContentProcessingTranslationView: View {
    @EnvironmentObject var assistant: AIAssistant
    @StateObject private var textManager = TextGenerationManager()
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var targetLanguage = "英文"
    
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
                    if textManager.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(textManager.isProcessing ? "翻译中..." : "开始翻译")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(inputText.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(inputText.isEmpty || textManager.isProcessing)
            
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
        guard !inputText.isEmpty else { return }
        
        Task {
            do {
                // 使用 TextGenerationManager 的真正AI翻译
                let result = try await textManager.generateTranslation(
                    text: inputText,
                    to: targetLanguage
                )
                
                await MainActor.run {
                    translatedText = result
                }
            } catch {
                await MainActor.run {
                    translatedText = "翻译失败：\(error.localizedDescription)"
                }
                print("翻译失败: \(error)")
            }
        }
    }
}

struct FormatConversionView: View {
    @EnvironmentObject var assistant: AIAssistant
    @EnvironmentObject var keyboardManager: KeyboardManager
    @State private var inputText = ""
    @State private var convertedText = ""
    @State private var selectedFormat = TextFormat.markdown
    @State private var isConverting = false
    @FocusState private var isTextEditorFocused: Bool
    
    private let sampleTexts = [
        "产品介绍\n\n苹果iPhone是一款智能手机，具有以下特点：\n- 高清摄像头\n- 快速处理器\n- 长续航电池\n\n价格：8999元",
        "会议记录\n\n时间：2024年1月15日\n地点：会议室A\n参与者：张三、李四、王五\n\n讨论内容：\n1. 项目进展汇报\n2. 下月计划制定\n3. 预算分配讨论",
        "员工信息\n\n姓名：张三\n部门：技术部\n职位：工程师\n工资：15000\n入职日期：2023-06-01\n\n姓名：李四\n部门：市场部\n职位：经理\n工资：18000\n入职日期：2022-03-15"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 输入区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("原始文本")
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(sampleTexts.enumerated()), id: \.offset) { index, sample in
                                Button("示例\(index + 1)") {
                                    inputText = sample
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
            
                // 格式选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("目标格式")
                        .font(.headline)
                    
                    // 格式描述
                    Text(selectedFormat.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
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
                }            // 转换按钮
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
            .onTapGesture {
                keyboardManager.dismissKeyboard()
            }
            
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
        .scrollViewKeyboardAware()
    }
    
    private func convertFormat() {
        isConverting = true
        
        Task {
            do {
                // 根据不同格式使用专门的指令
                let instructions = getInstructionsForFormat(selectedFormat)
                
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(to: inputText)
                
                await MainActor.run {
                    convertedText = response.content
                    isConverting = false
                }
            } catch {
                await MainActor.run {
                    convertedText = "格式转换失败：\(error.localizedDescription)"
                    isConverting = false
                }
                print("格式转换失败: \(error)")
            }
        }
    }
    
    private func getInstructionsForFormat(_ format: TextFormat) -> String {
        switch format {
        case .markdown:
            return """
            你是一个专业的文档格式转换专家。请将用户提供的文本转换为标准的Markdown格式。
            
            转换规则：
            1. 将标题转换为对应级别的Markdown标题（# ## ### 等）
            2. 将列表转换为Markdown列表格式（- 或 1. ）
            3. 强调文本使用 **粗体** 或 *斜体*
            4. 代码片段使用 `代码` 或 ```代码块```
            5. 链接使用 [文本](链接) 格式
            6. 保持段落间的空行分隔
            7. 只输出转换后的Markdown内容，不要添加解释
            
            请将以下内容转换为Markdown格式：
            """
            
        case .html:
            return """
            你是一个专业的HTML转换专家。请将用户提供的文本转换为标准的HTML格式。
            
            转换规则：
            1. 使用适当的HTML标签（<h1>-<h6>, <p>, <ul>, <ol>, <li>等）
            2. 保持HTML语法正确，标签要正确闭合
            3. 使用语义化的HTML标签
            4. 强调文本使用<strong>或<em>标签
            5. 代码使用<code>或<pre>标签
            6. 链接使用<a href="">标签
            7. 生成完整但简洁的HTML结构
            8. 只输出HTML代码，不要添加解释
            
            请将以下内容转换为HTML格式：
            """
            
        case .json:
            return """
            你是一个专业的JSON格式转换专家。请将用户提供的文本内容结构化为标准的JSON格式。
            
            转换规则：
            1. 分析文本内容的结构和层次
            2. 将内容转换为合理的JSON对象或数组
            3. 使用恰当的键名（英文，采用camelCase命名）
            4. 确保JSON格式正确，语法无误
            5. 对于列表内容，使用JSON数组
            6. 对于结构化信息，使用JSON对象
            7. 字符串值要正确转义特殊字符
            8. 只输出有效的JSON格式，不要添加解释
            
            请将以下内容转换为JSON格式：
            """
            
        case .csv:
            return """
            你是一个专业的CSV格式转换专家。请将用户提供的文本转换为标准的CSV格式。
            
            转换规则：
            1. 分析文本内容，识别表格化的信息
            2. 第一行作为表头（列名）
            3. 使用逗号分隔各列数据
            4. 包含逗号或换行的字段用双引号包围
            5. 双引号字段内的双引号要转义为两个双引号
            6. 每行数据占一行
            7. 保持数据的完整性和准确性
            8. 只输出CSV格式的数据，不要添加解释
            
            请将以下内容转换为CSV格式：
            """
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
        case .markdown: return "Markdown标记语言，用于文档编写"
        case .html: return "HTML网页标记语言"
        case .json: return "JSON数据交换格式"
        case .csv: return "CSV表格数据格式"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .markdown: return ".md"
        case .html: return ".html"
        case .json: return ".json"
        case .csv: return ".csv"
        }
    }
}

#Preview {
    NavigationView {
        ContentProcessingView()
            .environmentObject(AIAssistant())
    }
}
