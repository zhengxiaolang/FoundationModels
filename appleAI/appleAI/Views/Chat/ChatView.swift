import SwiftUI

struct ChatView: View {
    @EnvironmentObject var assistant: AIAssistant
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var showingClearAlert = false
    @State private var isProcessing = false
    
    private let quickPrompts = [
        "你好，请介绍一下自己",
        "什么是人工智能？",
        "请推荐一些学习编程的方法",
        "如何保持健康的生活方式？",
        "请解释一下可持续发展的重要性"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        // 欢迎消息
                        if messages.isEmpty {
                            WelcomeMessageView(quickPrompts: quickPrompts) { prompt in
                                inputText = prompt
                                sendMessage()
                            }
                        }
                        
                        // 聊天消息
                        ForEach(messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        // 加载指示器
                        if isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("AI 正在思考...")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .id("loading")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        if isProcessing {
                            proxy.scrollTo("loading", anchor: .bottom)
                        } else if let lastMessage = messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isProcessing) { processing in
                    if processing {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // 输入区域
            ChatInputView(
                inputText: $inputText,
                isLoading: isProcessing,
                onSend: sendMessage
            )
            .environmentObject(keyboardManager)
        }
        .keyboardAware()
        .environmentObject(keyboardManager)
        .navigationTitle("AI 助手")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("清空对话", role: .destructive) {
                        showingClearAlert = true
                    }
                    
                    Button("导出对话") {
                        exportChat()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("清空对话", isPresented: $showingClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                messages.removeAll()
            }
        } message: {
            Text("确定要清空所有对话记录吗？此操作无法撤销。")
        }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(
            content: inputText,
            isUser: true
        )

        messages.append(userMessage)
        let prompt = inputText
        inputText = ""
        keyboardManager.dismissKeyboard()
        isProcessing = true

        Task {
            do {
                // 使用正确的 LanguageModelSession API
                let context = getConversationContext()
                let instructions = """
                你是一个友好、有帮助的AI助手。请根据用户的消息生成自然、有用的回复。
                \(context.isEmpty ? "" : "对话上下文：\(context)")
                回复要求：
                1. 保持回复简洁、相关且有帮助
                2. 语气友好自然
                3. 如果不确定，可以诚实地表达不确定性
                4. 提供有价值的信息和建议
                """
                
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(to: prompt)

                let aiMessage = ChatMessage(
                    content: response.content,
                    isUser: false
                )

                await MainActor.run {
                    isProcessing = false
                    messages.append(aiMessage)
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    let errorMessage = ChatMessage(
                        content: "抱歉，我现在无法回应：\(error.localizedDescription)",
                        isUser: false
                    )
                    messages.append(errorMessage)
                }
                print("对话生成失败: \(error)")
            }
        }
    }

    private func getConversationContext() -> String {
        // 获取最近几条消息作为上下文
        let recentMessages = messages.suffix(4)
        return recentMessages.map { message in
            let sender = message.isUser ? "用户" : "助手"
            return "\(sender): \(message.content)"
        }.joined(separator: "\n")
    }
    
    private func exportChat() {
        let chatText = messages.map { message in
            let sender = message.isUser ? "用户" : "AI助手"
            let timestamp = DateFormatter.localizedString(from: message.timestamp, dateStyle: .short, timeStyle: .short)
            return "[\(timestamp)] \(sender): \(message.content)"
        }.joined(separator: "\n\n")
        
        UIPasteboard.general.string = chatText
    }
}

struct WelcomeMessageView: View {
    let quickPrompts: [String]
    let onPromptTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 欢迎信息
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("AI 助手")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Text("我是您的智能助手，可以帮助您解答问题、提供建议和进行对话。请随时向我提问！")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            // 快速提示
            VStack(alignment: .leading, spacing: 8) {
                Text("快速开始")
                    .font(.headline)
                
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button(action: {
                        onPromptTap(prompt)
                    }) {
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.orange)
                            
                            Text(prompt)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right.circle")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isUser ? Color.blue : Color(.systemGray5)
                    )
                    .foregroundColor(
                        message.isUser ? .white : .primary
                    )
                    .cornerRadius(18)
                
                Text(DateFormatter.localizedString(from: message.timestamp, dateStyle: .none, timeStyle: .short))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
    }
}

struct ChatInputView: View {
    @Binding var inputText: String
    @EnvironmentObject var keyboardManager: KeyboardManager
    let isLoading: Bool
    let onSend: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // 键盘关闭按钮 (当键盘显示时)
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
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                // 文本输入框
                TextField("输入消息...", text: $inputText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        if !isLoading {
                            onSend()
                        }
                    }
                
                // 发送按钮
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(inputText.isEmpty || isLoading ? .gray : .blue)
                }
                .disabled(inputText.isEmpty || isLoading)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationView {
        ChatView()
            .environmentObject(AIAssistant())
    }
}
