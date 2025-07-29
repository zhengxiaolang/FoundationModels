import SwiftUI

struct ContentView: View {
    @StateObject private var assistant = AIAssistant()
    @State private var showTestView = true // 默认显示测试视图

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 状态显示
                VStack(spacing: 10) {
                    Text("🚀 Apple Foundation Models Demo")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        Circle()
                            .fill(assistant.isModelLoaded ? Color.green : Color.orange)
                            .frame(width: 12, height: 12)

                        Text(assistant.isModelLoaded ? "模型已加载" : "模型加载中...")
                            .font(.body)
                    }

                    if assistant.isProcessing {
                        ProgressView("正在初始化...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }

                    if let error = assistant.lastError {
                        Text("错误: \(error)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()

                // 切换按钮
                Button(showTestView ? "显示完整功能" : "显示测试视图") {
                    showTestView.toggle()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                // 内容区域
                if showTestView {
                    SimpleTestView()
                        .environmentObject(assistant)
                } else {
                    FeatureListView()
                        .environmentObject(assistant)
                }
            }
        }
        .navigationTitle("AI Demo")
    }
}

struct SimpleTestView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var testResult = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("基础功能测试")
                .font(.headline)

            Button("测试文本生成") {
                testTextGeneration()
            }
            .disabled(!assistant.isModelLoaded || assistant.isProcessing)
            .buttonStyle(.borderedProminent)

            if !testResult.isEmpty {
                Text("测试结果:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(testResult)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }

    private func testTextGeneration() {
        Task {
            if let result = await assistant.generateText(prompt: "测试提示") {
                await MainActor.run {
                    testResult = result
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
