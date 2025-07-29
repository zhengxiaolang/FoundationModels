import SwiftUI

struct RealModelTestView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var inputText = ""
    @State private var result = ""
    @State private var selectedTask: TaskType = .textGeneration
    @State private var targetLanguage = "en"
    @State private var rewriteStyle = "formal"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("真实模型测试")
                .font(.title2)
                .fontWeight(.bold)
            
            // 任务类型选择
            VStack(alignment: .leading, spacing: 8) {
                Text("选择任务类型")
                    .font(.headline)
                
                Picker("任务类型", selection: $selectedTask) {
                    Text("文本生成").tag(TaskType.textGeneration)
                    Text("翻译").tag(TaskType.translation)
                    Text("摘要").tag(TaskType.summarization)
                    Text("情感分析").tag(TaskType.sentimentAnalysis)
                    Text("关键词提取").tag(TaskType.keywordExtraction)
                    Text("文本分类").tag(TaskType.textClassification)
                    Text("文本改写").tag(TaskType.textRewriting)
                    Text("对话生成").tag(TaskType.conversation)
                }
                .pickerStyle(.menu)
            }
            
            // 额外参数
            if selectedTask == .translation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("目标语言")
                        .font(.headline)
                    
                    Picker("目标语言", selection: $targetLanguage) {
                        Text("英文").tag("en")
                        Text("中文").tag("zh")
                        Text("日文").tag("ja")
                        Text("韩文").tag("ko")
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            if selectedTask == .textRewriting {
                VStack(alignment: .leading, spacing: 8) {
                    Text("改写风格")
                        .font(.headline)
                    
                    Picker("改写风格", selection: $rewriteStyle) {
                        Text("正式").tag("formal")
                        Text("随意").tag("casual")
                        Text("专业").tag("professional")
                        Text("创意").tag("creative")
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            // 输入区域
            VStack(alignment: .leading, spacing: 8) {
                Text("输入文本")
                    .font(.headline)
                
                TextEditor(text: $inputText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            
            // 执行按钮
            Button("执行任务") {
                executeTask()
            }
            .disabled(!assistant.isModelLoaded || assistant.isProcessing || inputText.isEmpty)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // 结果显示
            if !result.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("结果")
                        .font(.headline)
                    
                    ScrollView {
                        Text(result)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("真实模型测试")
    }
    
    private func executeTask() {
        Task {
            let taskResult: String?
            
            switch selectedTask {
            case .textGeneration:
                taskResult = await assistant.generateText(prompt: inputText)
            case .translation:
                taskResult = await assistant.translateText(inputText, to: targetLanguage)
            case .summarization:
                taskResult = await assistant.summarizeText(inputText)
            case .sentimentAnalysis:
                taskResult = await assistant.analyzeSentiment(inputText)
            case .keywordExtraction:
                taskResult = await assistant.extractKeywords(inputText)
            case .textClassification:
                taskResult = await assistant.classifyText(inputText)
            case .textRewriting:
                taskResult = await assistant.rewriteText(inputText, style: rewriteStyle)
            case .conversation:
                taskResult = await assistant.generateConversationResponse(inputText)
            }
            
            await MainActor.run {
                result = taskResult ?? "任务执行失败"
            }
        }
    }
}

struct QuickTestView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var results: [String] = []
    
    var body: some View {
        VStack(spacing: 16) {
            Text("快速功能测试")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    QuickTestButton(title: "文本生成", prompt: "写一个关于AI的短文") { result in
                        results.append("文本生成: \(result)")
                    }
                    
                    QuickTestButton(title: "情感分析", prompt: "我今天很开心，因为学会了新技术！") { result in
                        results.append("情感分析: \(result)")
                    }
                    
                    QuickTestButton(title: "关键词提取", prompt: "人工智能技术正在快速发展，机器学习和深度学习是其核心技术。") { result in
                        results.append("关键词提取: \(result)")
                    }
                    
                    QuickTestButton(title: "文本分类", prompt: "苹果公司发布了新的iPhone，搭载了最新的A17芯片。") { result in
                        results.append("文本分类: \(result)")
                    }
                    
                    QuickTestButton(title: "对话测试", prompt: "你好，请介绍一下自己") { result in
                        results.append("对话: \(result)")
                    }
                }
                .padding()
            }
            
            if !results.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("测试结果")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                                Text(result)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .font(.caption)
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
        .padding()
        .navigationTitle("快速测试")
    }
}

struct QuickTestButton: View {
    let title: String
    let prompt: String
    let onResult: (String) -> Void
    
    @EnvironmentObject var assistant: AIAssistant
    @State private var isLoading = false
    
    var body: some View {
        Button(title) {
            executeTest()
        }
        .disabled(!assistant.isModelLoaded || assistant.isProcessing || isLoading)
        .buttonStyle(.bordered)
        .overlay(
            Group {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        )
    }
    
    private func executeTest() {
        isLoading = true
        Task {
            let result = await assistant.generateText(prompt: prompt)
            await MainActor.run {
                isLoading = false
                onResult(result ?? "测试失败")
            }
        }
    }
}

#Preview {
    NavigationView {
        RealModelTestView()
            .environmentObject(AIAssistant())
    }
}
