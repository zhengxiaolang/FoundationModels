import SwiftUI

struct FeatureListView: View {
    @StateObject private var assistant = AIAssistant()
    
    private let features: [FeatureItem] = [
        FeatureItem(
            title: "文本生成",
            description: "创意写作、内容摘要、文本补全",
            icon: "pencil.and.outline",
            color: .blue,
            destination: TextGenerationView()
        ),
        FeatureItem(
            title: "文本分析",
            description: "情感分析、关键词提取、文本分类",
            icon: "chart.bar.doc.horizontal",
            color: .green,
            destination: TextAnalysisView()
        ),
        FeatureItem(
            title: "对话系统",
            description: "智能聊天机器人、问答系统",
            icon: "bubble.left.and.bubble.right",
            color: .purple,
            destination: ChatView()
        ),
        FeatureItem(
            title: "内容处理",
            description: "文本改写、语言翻译、格式转换",
            icon: "arrow.triangle.2.circlepath",
            color: .orange,
            destination: ContentProcessingView()
        ),
        FeatureItem(
            title: "智能笔记",
            description: "AI增强的笔记应用",
            icon: "note.text",
            color: .indigo,
            destination: SmartNotesView()
        ),
        FeatureItem(
            title: "调试工具",
            description: "性能监控、错误追踪、日志查看",
            icon: "wrench.and.screwdriver",
            color: .red,
            destination: DebugToolsView()
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部状态区域
            StatusHeaderView(assistant: assistant)

            // 功能列表
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(features) { feature in
                        NavigationLink(destination: feature.destination) {
                            FeatureCardView(feature: feature)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Foundation Models Demo")
        .navigationBarTitleDisplayMode(.large)
        .environmentObject(assistant)
    }
}

struct StatusHeaderView: View {
    @ObservedObject var assistant: AIAssistant
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: assistant.isModelLoaded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(assistant.isModelLoaded ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("模型状态")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(assistant.isModelLoaded ? "已加载" : "加载中...")
                        .font(.headline)
                        .foregroundColor(assistant.isModelLoaded ? .primary : .orange)
                }
                
                Spacer()
                
                if assistant.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let error = assistant.lastError {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct FeatureCardView: View {
    let feature: FeatureItem
    
    var body: some View {
        VStack(spacing: 12) {
            // 图标
            Image(systemName: feature.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(feature.color)
                .frame(height: 40)
            
            // 标题
            Text(feature.title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // 描述
            Text(feature.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(feature.color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    FeatureListView()
}
