import SwiftUI

struct TextGenerationView: View {
    @EnvironmentObject var assistant: AIAssistant
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CreativeWritingView()
                .environmentObject(assistant)
                .environmentObject(keyboardManager)
                .tabItem {
                    Image(systemName: "pencil.and.outline")
                    Text("创意写作")
                }
                .tag(0)

            TextSummaryView()
                .environmentObject(assistant)
                .environmentObject(keyboardManager)
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("文本摘要")
                }
                .tag(1)

            TextCompletionView()
                .environmentObject(assistant)
                .environmentObject(keyboardManager)
                .tabItem {
                    Image(systemName: "text.append")
                    Text("文本补全")
                }
                .tag(2)
        }
        .navigationTitle("文本生成")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreativeWritingView: View {
    @EnvironmentObject var keyboardManager: KeyboardManager
    @StateObject private var textManager = TextGenerationManager()
    @State private var prompt = ""
    @State private var generatedText = ""
    @FocusState private var isTextEditorFocused: Bool

    private let promptSuggestions = [
        "写一个关于未来科技的短故事",
        "创作一首关于春天的诗歌",
        "描述一个神秘的古老城市",
        "写一段关于友谊的感人故事",
        "创作一个科幻小说的开头"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 输入区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("创意提示")
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
                    
                    TextEditor(text: $prompt)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($isTextEditorFocused)
                    
                    // 提示建议
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(promptSuggestions, id: \.self) { suggestion in
                                Button(suggestion) {
                                    prompt = suggestion
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
                
                // 生成按钮
                Button(action: generateCreativeText) {
                    HStack {
                        if textManager.isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(textManager.isProcessing ? "生成中..." : "开始创作")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(prompt.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(prompt.isEmpty || textManager.isProcessing)
                .onTapGesture {
                    keyboardManager.dismissKeyboard()
                }
                
                // 结果区域
                if !generatedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("生成结果")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("复制") {
                                UIPasteboard.general.string = generatedText
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(16)
                        }
                        
                        Text(generatedText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding()
        }
        .scrollViewKeyboardAware()
    }
    
    private func generateCreativeText() {
        keyboardManager.dismissKeyboard()

        Task {
            do {
                let result = try await textManager.generateCreativeContent(
                    prompt: prompt,
                    style: "创意"
                )
                await MainActor.run {
                    generatedText = result
                }
            } catch {
                print("创意文本生成失败: \(error)")
            }
        }
    }
}

struct TextSummaryView: View {
    @EnvironmentObject var keyboardManager: KeyboardManager
    @StateObject private var textManager = TextGenerationManager()
    @State private var inputText = ""
    @State private var summary = ""
    @State private var maxLength = 100
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 输入区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("原文内容")
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
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($isTextEditorFocused)
                    
                    // 摘要长度设置
                    HStack {
                        Text("摘要长度: \(maxLength)字")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Slider(value: Binding(
                            get: { Double(maxLength) },
                            set: { maxLength = Int($0) }
                        ), in: 50...300, step: 25)
                        .frame(width: 120)
                    }
                }
                
                // 生成按钮
                Button(action: generateSummary) {
                    HStack {
                        if textManager.isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(textManager.isProcessing ? "生成中..." : "生成摘要")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputText.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(inputText.isEmpty || textManager.isProcessing)
                .onTapGesture {
                    keyboardManager.dismissKeyboard()
                }
                
                // 摘要结果
                if !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("智能摘要")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(summary.count)字")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("复制") {
                                UIPasteboard.general.string = summary
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(16)
                        }
                        
                        Text(summary)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .scrollViewKeyboardAware()
    }
    
    private func generateSummary() {
        keyboardManager.dismissKeyboard()

        Task {
            do {
                let result = try await textManager.generateSummary(
                    for: inputText,
                    maxLength: maxLength
                )
                await MainActor.run {
                    summary = result
                }
            } catch {
                print("摘要生成失败: \(error)")
            }
        }
    }
}

struct TextCompletionView: View {
    @EnvironmentObject var keyboardManager: KeyboardManager
    @StateObject private var textManager = TextGenerationManager()
    @State private var inputText = ""
    @State private var completedText = ""
    @FocusState private var isTextEditorFocused: Bool
    
    private let completionPrompts = [
        "在一个阳光明媚的早晨，",
        "科技的发展让我们的生活",
        "教育的未来将会",
        "人工智能的应用",
        "可持续发展需要我们"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 输入区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("开始文本")
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
                        .focused($isTextEditorFocused)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    // 示例提示
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(completionPrompts, id: \.self) { prompt in
                                Button(prompt) {
                                    inputText = prompt
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
                
                // 补全按钮
                Button(action: completeText) {
                    HStack {
                        if textManager.isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(textManager.isProcessing ? "补全中..." : "智能补全")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputText.isEmpty ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(inputText.isEmpty || textManager.isProcessing)
                .onTapGesture {
                    keyboardManager.dismissKeyboard()
                }
                
                // 补全结果
                if !completedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("补全结果")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("复制全文") {
                                UIPasteboard.general.string = inputText + completedText
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(16)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // 原文
                            Text(inputText)
                                .foregroundColor(.primary)
                            
                            // 补全部分
                            Text(completedText)
                                .foregroundColor(.orange)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding()
        }
        .scrollViewKeyboardAware()
    }
    
    private func completeText() {
        keyboardManager.dismissKeyboard()

        let instructions = """
            请继续完成以下文本，保持风格一致，内容自然流畅。
            只返回续写的部分，不要重复原文。
            """

        Task {
            do {
                let result = try await textManager.generateText(
                    instructions: instructions,
                    prompt: inputText
                )
                await MainActor.run {
                    completedText = result
                }
            } catch {
                print("文本补全失败: \(error)")
            }
        }
    }
}

#Preview {
    NavigationView {
        TextGenerationView()
            .environmentObject(AIAssistant())
    }
}
