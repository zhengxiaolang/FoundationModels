import SwiftUI

struct SimpleFeatureListView: View {
    @EnvironmentObject var assistant: AIAssistant
    @StateObject private var keyboardManager = KeyboardManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // 状态显示
            VStack(spacing: 10) {
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
            
            // 简化的功能列表
            VStack(spacing: 16) {
                NavigationLink("文本生成", destination: SimpleTextGenerationView().environmentObject(keyboardManager))
                    .buttonStyle(.borderedProminent)
                
                NavigationLink("对话系统", destination: SimpleChatView().environmentObject(keyboardManager))
                    .buttonStyle(.borderedProminent)
                
                NavigationLink("调试工具", destination: SimpleDebugView().environmentObject(keyboardManager))
                    .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
        .keyboardAware()
        .environmentObject(keyboardManager)
        .navigationTitle("简化功能列表")
    }
}

struct SimpleTextGenerationView: View {
    @EnvironmentObject var assistant: AIAssistant
    @EnvironmentObject var keyboardManager: KeyboardManager
    @State private var prompt = ""
    @State private var result = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("文本生成测试")
                .font(.headline)
            
            // 键盘关闭按钮
            if keyboardManager.isKeyboardVisible {
                HStack {
                    Spacer()
                    Button(action: {
                        keyboardManager.dismissKeyboard()
                        isTextFieldFocused = false
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
            
            TextField("输入提示词", text: $prompt)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
            
            Button("生成文本") {
                generateText()
            }
            .disabled(!assistant.isModelLoaded || assistant.isProcessing)
            .buttonStyle(.borderedProminent)
            
            if !result.isEmpty {
                Text("结果:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(result)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .keyboardAware()
        .navigationTitle("文本生成")
    }
    
    private func generateText() {
        Task {
            if let generated = await assistant.generateText(prompt: prompt.isEmpty ? "测试提示" : prompt) {
                await MainActor.run {
                    result = generated
                }
            }
        }
    }
}

struct SimpleChatView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var message = ""
    @State private var response = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("对话测试")
                .font(.headline)
            
            TextField("输入消息", text: $message)
                .textFieldStyle(.roundedBorder)
            
            Button("发送") {
                sendMessage()
            }
            .disabled(!assistant.isModelLoaded || assistant.isProcessing)
            .buttonStyle(.borderedProminent)
            
            if !response.isEmpty {
                Text("回复:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(response)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("对话系统")
    }
    
    private func sendMessage() {
        Task {
            if let reply = await assistant.generateText(prompt: message.isEmpty ? "你好" : message) {
                await MainActor.run {
                    response = reply
                }
            }
        }
    }
}

struct SimpleDebugView: View {
    @EnvironmentObject var assistant: AIAssistant
    
    var body: some View {
        VStack(spacing: 16) {
            Text("调试信息")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("模型状态: \(assistant.isModelLoaded ? "已加载" : "未加载")")
                Text("处理中: \(assistant.isProcessing ? "是" : "否")")
                if let error = assistant.lastError {
                    Text("错误: \(error)")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Button("测试模型") {
                testModel()
            }
            .disabled(!assistant.isModelLoaded || assistant.isProcessing)
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .navigationTitle("调试工具")
    }
    
    private func testModel() {
        Task {
            _ = await assistant.generateText(prompt: "测试")
        }
    }
}

#Preview {
    NavigationView {
        SimpleFeatureListView()
            .environmentObject(AIAssistant())
    }
}
