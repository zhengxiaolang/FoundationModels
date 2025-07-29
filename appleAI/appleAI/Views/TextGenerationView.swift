import SwiftUI

struct TextGenerationView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var inputText = ""
    @State private var generatedText = ""
    @State private var isGenerating = false
    @State private var showResult = false
    @State private var selectedCategory: GenerationCategory = .general
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题和说明
                    VStack(spacing: 12) {
                        Text("🧠 AI文本生成")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("输入您的描述，AI将为您生成高质量的内容")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // 类别选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("选择生成类型")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(GenerationCategory.allCases, id: \.self) { category in
                                CategoryCard(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 输入区域
                    VStack(alignment: .leading, spacing: 12) {
                        Text("输入描述")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextEditor(text: $inputText)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        
                        if inputText.isEmpty {
                            Text(selectedCategory.placeholder)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 生成按钮
                    Button(action: generateText) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            
                            Text(isGenerating ? "正在生成..." : "🚀 开始生成")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            inputText.isEmpty || isGenerating ? 
                            Color.gray : selectedCategory.color
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(inputText.isEmpty || isGenerating)
                    .padding(.horizontal)
                    
                    // 结果显示
                    if showResult {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("生成结果")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button("复制") {
                                    UIPasteboard.general.string = generatedText
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            ScrollView {
                                Text(generatedText)
                                    .font(.body)
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedCategory.color.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .frame(maxHeight: 300)
                            
                            // 操作按钮
                            HStack(spacing: 12) {
                                Button("重新生成") {
                                    generateText()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory.color.opacity(0.1))
                                .foregroundColor(selectedCategory.color)
                                .cornerRadius(8)
                                
                                Button("清空结果") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showResult = false
                                        generatedText = ""
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .slide))
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("文本生成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateText() {
        guard !inputText.isEmpty else { return }
        
        isGenerating = true
        
        Task {
            // 根据选择的类别构建提示词
            let prompt = buildPrompt(for: selectedCategory, with: inputText)
            
            let result = await assistant.generateText(prompt: prompt)
            
            await MainActor.run {
                isGenerating = false
                if let result = result {
                    generatedText = result
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showResult = true
                    }
                } else {
                    generatedText = "生成失败，请重试"
                    showResult = true
                }
            }
        }
    }
    
    private func buildPrompt(for category: GenerationCategory, with input: String) -> String {
        switch category {
        case .general:
            return input
        case .creative:
            return "请基于以下描述创作一个富有创意的内容：\n\n\(input)"
        case .technical:
            return "请基于以下技术需求提供专业的技术解决方案：\n\n\(input)"
        case .business:
            return "请基于以下商业需求提供专业的商业分析和建议：\n\n\(input)"
        case .educational:
            return "请基于以下教育需求提供详细的学习内容和解释：\n\n\(input)"
        case .marketing:
            return "请基于以下营销需求创作吸引人的营销内容：\n\n\(input)"
        }
    }
}

enum GenerationCategory: String, CaseIterable {
    case general = "通用"
    case creative = "创意"
    case technical = "技术"
    case business = "商业"
    case educational = "教育"
    case marketing = "营销"
    
    var icon: String {
        switch self {
        case .general:
            return "doc.text"
        case .creative:
            return "paintbrush"
        case .technical:
            return "gear"
        case .business:
            return "briefcase"
        case .educational:
            return "book"
        case .marketing:
            return "megaphone"
        }
    }
    
    var color: Color {
        switch self {
        case .general:
            return .blue
        case .creative:
            return .purple
        case .technical:
            return .green
        case .business:
            return .orange
        case .educational:
            return .red
        case .marketing:
            return .pink
        }
    }
    
    var placeholder: String {
        switch self {
        case .general:
            return "例如：写一篇关于人工智能发展的文章"
        case .creative:
            return "例如：创作一个关于未来世界的科幻故事"
        case .technical:
            return "例如：解释如何在iOS中实现数据持久化"
        case .business:
            return "例如：分析电商行业的发展趋势和机会"
        case .educational:
            return "例如：解释量子物理的基本概念"
        case .marketing:
            return "例如：为新产品设计一个吸引人的广告文案"
        }
    }
}

struct CategoryCard: View {
    let category: GenerationCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ? category.color : category.color.opacity(0.1)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(category.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TextGenerationView()
        .environmentObject(AIAssistant())
}
