import SwiftUI

struct ChatView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var showingClearAlert = false
    
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
                        if isLoading {
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
                        if isLoading {
                            proxy.scrollTo("loading", anchor: .bottom)
                        } else if let lastMessage = messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isLoading) { loading in
                    if loading {
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
                isLoading: isLoading,
                onSend: sendMessage
            )
        }
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
        isLoading = true
        
        Task {
            if let response = await assistant.generateText(
                prompt: prompt,
                maxTokens: 200,
                temperature: 0.7
            ) {
                let aiMessage = ChatMessage(
                    content: response,
                    isUser: false
                )
                
                await MainActor.run {
                    messages.append(aiMessage)
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        content: "抱歉，我现在无法回应。请稍后再试。",
                        isUser: false
                    )
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
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
    let isLoading: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 文本输入框
            TextField("输入消息...", text: $inputText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...4)
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
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationView {
        ChatView()
            .environmentObject(AIAssistant())
    }
}
