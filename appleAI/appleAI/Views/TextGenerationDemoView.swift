import SwiftUI

struct TextGenerationDemoView: View {
    @StateObject private var textManager = TextGenerationManager()
    @State private var customInstructions = """
        Suggest five related topics. Keep them concise (three to seven words) and make sure they \
        build naturally from the person's topic.
        """
    @State private var userPrompt = "Making homemade bread"
    @State private var generatedResult = ""
    @State private var selectedTemplate: TextGenerationManager.InstructionTemplate = .relatedTopics
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 状态显示
                    statusSection
                    
                    // 模板选择
                    templateSection
                    
                    // 自定义指令输入
                    instructionsSection
                    
                    // 提示词输入
                    promptSection
                    
                    // 生成按钮
                    generateButton
                    
                    // 结果显示
                    resultSection
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("文本生成演示")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - 视图组件
    
    private var statusSection: some View {
        VStack(spacing: 10) {
            HStack {
                Circle()
                    .fill(textManager.isProcessing ? Color.orange : Color.green)
                    .frame(width: 12, height: 12)
                
                Text(textManager.isProcessing ? "正在生成..." : "就绪")
                    .font(.body)
                
                Spacer()
            }
            
            if let error = textManager.lastError {
                Text("错误: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择模板")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    templateButton("相关主题", template: .relatedTopics)
                    templateButton("创意写作", template: .creative(style: "创意"))
                    templateButton("技术解释", template: .technical)
                    templateButton("对话回复", template: .conversation(context: ""))
                    templateButton("文本摘要", template: .summary(maxLength: 100))
                    templateButton("自定义", template: .custom(instructions: customInstructions))
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func templateButton(_ title: String, template: TextGenerationManager.InstructionTemplate) -> some View {
        Button(title) {
            selectedTemplate = template
            updateInstructionsFromTemplate()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelectedTemplate(template) ? Color.blue : Color.gray.opacity(0.3))
        .foregroundColor(isSelectedTemplate(template) ? .white : .primary)
        .cornerRadius(20)
        .font(.caption)
    }
    
    private func isSelectedTemplate(_ template: TextGenerationManager.InstructionTemplate) -> Bool {
        switch (selectedTemplate, template) {
        case (.relatedTopics, .relatedTopics),
             (.technical, .technical):
            return true
        case (.creative(let style1), .creative(let style2)):
            return style1 == style2
        case (.conversation(let context1), .conversation(let context2)):
            return context1 == context2
        case (.summary(let length1), .summary(let length2)):
            return length1 == length2
        case (.custom(_), .custom(_)):
            return true
        default:
            return false
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("指令")
                .font(.headline)
            
            TextEditor(text: $customInstructions)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .font(.system(size: 14, family: .monospaced))
        }
    }
    
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("提示词")
                .font(.headline)
            
            TextField("输入您的提示词...", text: $userPrompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
    
    private var generateButton: some View {
        Button(action: generateText) {
            HStack {
                if textManager.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(textManager.isProcessing ? "生成中..." : "生成文本")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(textManager.isProcessing ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(textManager.isProcessing || userPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !generatedResult.isEmpty {
                Text("生成结果")
                    .font(.headline)
                
                Text(generatedResult)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 复制按钮
                HStack {
                    Spacer()
                    Button("复制") {
                        UIPasteboard.general.string = generatedResult
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - 方法
    
    private func updateInstructionsFromTemplate() {
        customInstructions = selectedTemplate.instructions
    }
    
    private func generateText() {
        Task {
            do {
                let result = try await textManager.generateText(instructions: customInstructions, prompt: userPrompt)
                await MainActor.run {
                    generatedResult = result
                }
            } catch {
                print("生成失败: \(error)")
            }
        }
    }
}

// MARK: - 预览

#Preview {
    TextGenerationDemoView()
}
