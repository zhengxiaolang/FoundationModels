import SwiftUI

// 简单的启动测试视图
struct LaunchTestView: View {
    @StateObject private var assistant = AIAssistant()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🚀 Apple Foundation Models Demo")
                .font(.title)
                .fontWeight(.bold)
            
            Text("启动测试")
                .font(.headline)
            
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
            
            Button("测试文本生成") {
                testTextGeneration()
            }
            .disabled(!assistant.isModelLoaded || assistant.isProcessing)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func testTextGeneration() {
        Task {
            let result = await assistant.generateText(prompt: "测试提示")
            print("测试结果: \(result ?? "无结果")")
        }
    }
}

#Preview {
    LaunchTestView()
}
