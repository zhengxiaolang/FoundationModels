import SwiftUI

struct RealAITestView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false
    @State private var currentTest = ""
    @State private var showTextGeneration = false
    @State private var showTranslation = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🧠 真实AI模型测试")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("验证所有功能都使用真实的Apple AI技术")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !currentTest.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    
                    Text("正在测试: \(currentTest)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(spacing: 16) {
                // AI功能体验按钮
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    // 文本生成
                    Button("🎨 文本生成") {
                        showTextGeneration = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                    // 智能翻译
                    Button("🌐 智能翻译") {
                        showTranslation = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }

                // 其他测试按钮
                Button("🧪 运行技术测试") {
                    runRealAITests()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(assistant.isModelLoaded && !isRunningTests ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(!assistant.isModelLoaded || isRunningTests)
                .font(.headline)
            }
            
            if !testResults.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(testResults, id: \.id) { result in
                            TestResultCard(result: result)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 400)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("真实AI测试")
        .sheet(isPresented: $showTextGeneration) {
            TextGenerationView()
                .environmentObject(assistant)
        }
        .sheet(isPresented: $showTranslation) {
            TranslationView()
                .environmentObject(assistant)
        }
    }
    
    private func runRealAITests() {
        isRunningTests = true
        testResults.removeAll()
        
        Task {
            // 测试技术内容生成
            await testTechnicalGeneration()

            // 测试智能对话
            await testIntelligentConversation()

            // 测试真实翻译
            await testRealTranslation()

            // 测试意图识别
            await testIntentRecognition()

            await MainActor.run {
                isRunningTests = false
                currentTest = ""
            }
        }
    }
    
    private func testTechnicalGeneration() async {
        await MainActor.run {
            currentTest = "技术内容生成"
        }
        
        let result = await assistant.generateText(prompt: "解释SwiftUI中的数据绑定技术原理")
        
        await MainActor.run {
            testResults.append(TestResult(
                title: "⚙️ 技术内容生成",
                description: "测试AI的技术解释能力",
                input: "解释SwiftUI中的数据绑定技术原理",
                output: result ?? "测试失败",
                isSuccess: result != nil,
                category: .technical
            ))
        }
    }
    
    private func testIntelligentConversation() async {
        await MainActor.run {
            currentTest = "智能对话"
        }
        
        let result = await assistant.generateConversationResponse("你好，请介绍一下你的AI能力")
        
        await MainActor.run {
            testResults.append(TestResult(
                title: "💬 智能对话",
                description: "测试AI的对话理解和响应能力",
                input: "你好，请介绍一下你的AI能力",
                output: result ?? "测试失败",
                isSuccess: result != nil,
                category: .conversation
            ))
        }
    }
    
    private func testRealTranslation() async {
        await MainActor.run {
            currentTest = "真实翻译"
        }
        
        let result = await assistant.translateText("Hello, how are you today?", to: "zh")
        
        await MainActor.run {
            testResults.append(TestResult(
                title: "🌐 真实翻译",
                description: "测试基于真实算法的翻译功能",
                input: "Hello, how are you today?",
                output: result ?? "测试失败",
                isSuccess: result != nil,
                category: .translation
            ))
        }
    }
    
    private func testIntentRecognition() async {
        await MainActor.run {
            currentTest = "意图识别"
        }
        
        let result = await assistant.analyzeSentiment("我对这个新功能感到非常兴奋和满意！")
        
        await MainActor.run {
            testResults.append(TestResult(
                title: "🎯 意图识别",
                description: "测试AI的情感和意图分析能力",
                input: "我对这个新功能感到非常兴奋和满意！",
                output: result ?? "测试失败",
                isSuccess: result != nil,
                category: .analysis
            ))
        }
    }
}

struct TestResult {
    let id = UUID()
    let title: String
    let description: String
    let input: String
    let output: String
    let isSuccess: Bool
    let category: TestCategory
}

enum TestCategory {
    case creative
    case technical
    case conversation
    case translation
    case analysis
    
    var color: Color {
        switch self {
        case .creative:
            return .purple
        case .technical:
            return .blue
        case .conversation:
            return .green
        case .translation:
            return .orange
        case .analysis:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .creative:
            return "paintbrush.fill"
        case .technical:
            return "gear.circle.fill"
        case .conversation:
            return "bubble.left.and.bubble.right.fill"
        case .translation:
            return "globe"
        case .analysis:
            return "chart.bar.fill"
        }
    }
}

struct TestResultCard: View {
    let result: TestResult
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.category.icon)
                    .foregroundColor(result.category.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.headline)
                    
                    Text(result.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.isSuccess ? .green : .red)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("输入:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(result.input)
                        .font(.caption)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text("输出:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(result.output)
                        .font(.caption)
                        .padding(8)
                        .background(result.isSuccess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NavigationView {
        RealAITestView()
            .environmentObject(AIAssistant())
    }
}
