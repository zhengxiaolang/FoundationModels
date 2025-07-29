import SwiftUI

struct CompilationTestView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var testResults: [String] = []
    @State private var isRunningTests = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("编译测试")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("验证所有 AI 功能是否正常编译和运行")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("运行所有测试") {
                runAllTests()
            }
            .disabled(!assistant.isModelLoaded || isRunningTests)
            .buttonStyle(.borderedProminent)
            
            if isRunningTests {
                ProgressView("正在测试...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            if !testResults.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(testResults.enumerated()), id: \.offset) { index, result in
                            HStack {
                                Image(systemName: result.contains("✅") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(result.contains("✅") ? .green : .red)
                                
                                Text(result)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .frame(maxHeight: 300)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("编译测试")
    }
    
    private func runAllTests() {
        isRunningTests = true
        testResults.removeAll()
        
        Task {
            // 测试文本生成
            await testTextGeneration()
            
            // 测试翻译
            await testTranslation()
            
            // 测试摘要
            await testSummarization()
            
            // 测试情感分析
            await testSentimentAnalysis()
            
            // 测试关键词提取
            await testKeywordExtraction()
            
            // 测试文本分类
            await testTextClassification()
            
            // 测试文本改写
            await testTextRewriting()
            
            // 测试对话生成
            await testConversation()
            
            await MainActor.run {
                isRunningTests = false
            }
        }
    }
    
    private func testTextGeneration() async {
        do {
            let result = await assistant.generateText(prompt: "测试文本生成")
            await MainActor.run {
                if result != nil {
                    testResults.append("✅ 文本生成测试通过")
                } else {
                    testResults.append("❌ 文本生成测试失败")
                }
            }
        }
    }
    
    private func testTranslation() async {
        do {
            let result = await assistant.translateText("Hello", to: "zh")
            await MainActor.run {
                if result != nil {
                    testResults.append("✅ 翻译功能测试通过")
                } else {
                    testResults.append("❌ 翻译功能测试失败")
                }
            }
        }
    }
    
    private func testSummarization() async {
        do {
            let result = await assistant.summarizeText("这是一个很长的文本，需要进行摘要处理。人工智能技术正在快速发展。")
            await MainActor.run {
                if result != nil {
                    testResults.append("✅ 摘要功能测试通过")
                } else {
                    testResults.append("❌ 摘要功能测试失败")
                }
            }
        }
    }
    
    private func testSentimentAnalysis() async {
        do {
            let result = await assistant.analyzeSentiment("我今天很开心！")
            await MainActor.run {
                if result != nil {
                    testResults.append("✅ 情感分析测试通过")
                } else {
                    testResults.append("❌ 情感分析测试失败")
                }
            }
        }
    }
    
    private func testKeywordExtraction() async {
        do {
            let result = await assistant.extractKeywords("人工智能和机器学习是现代科技的重要组成部分")
            await MainActor.run {
                if result != nil {
                    testResults.append("✅ 关键词提取测试通过")
                } else {
                    testResults.append("❌ 关键词提取测试失败")
                }
            }
        }
    }
    
    private func testTextClassification() async {
        do {
            let result = await assistant.classifyText("苹果公司发布了新的iPhone")
            await MainActor.run {
                if result != nil {
                    testResults.append("✅ 文本分类测试通过")
                } else {
                    testResults.append("❌ 文本分类测试失败")
                }
            }
        }
    }
    
    private func testTextRewriting() async {
        do {
            let result = await assistant.rewriteText("这是一个测试", style: "formal")
            await MainActor.run {
                if result != nil {
                    testResults.append("✅ 文本改写测试通过")
                } else {
                    testResults.append("❌ 文本改写测试失败")
                }
            }
        }
    }
    
    private func testConversation() async {
        do {
            let result = await assistant.generateConversationResponse("你好")
            await MainActor.run {
                if result != nil {
                    testResults.append("✅ 对话生成测试通过")
                } else {
                    testResults.append("❌ 对话生成测试失败")
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CompilationTestView()
            .environmentObject(AIAssistant())
    }
}
