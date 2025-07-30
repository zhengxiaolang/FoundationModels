import SwiftUI

struct CleanFeatureListView: View {
    @EnvironmentObject var assistant: AIAssistant
    
    var body: some View {
        VStack(spacing: 20) {
            Text("选择AI功能")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                
                // 文本生成
                NavigationLink(destination: TextGenerationView().environmentObject(assistant)) {
                    FeatureCard(
                        title: "文本生成",
                        icon: "pencil.and.outline",
                        color: .blue,
                        description: "创意写作、摘要"
                    )
                }
                
                // 智能翻译
                NavigationLink(destination: TranslationView().environmentObject(assistant)) {
                    FeatureCard(
                        title: "智能翻译",
                        icon: "globe",
                        color: .green,
                        description: "多语言翻译"
                    )
                }
                
                // 对话聊天
                NavigationLink(destination: ChatView().environmentObject(assistant)) {
                    FeatureCard(
                        title: "智能对话",
                        icon: "bubble.left.and.bubble.right",
                        color: .purple,
                        description: "AI助手聊天"
                    )
                }
                
                // 文本分析
                NavigationLink(destination: TextAnalysisView().environmentObject(assistant)) {
                    FeatureCard(
                        title: "文本分析",
                        icon: "chart.bar.doc.horizontal",
                        color: .orange,
                        description: "情感分析、关键词"
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct FeatureCard: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SettingsView: View {
    @EnvironmentObject var assistant: AIAssistant
    
    var body: some View {
        VStack(spacing: 20) {
            Text("设置和调试")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)
            
            VStack(spacing: 16) {
                // 模型状态
                VStack(alignment: .leading, spacing: 8) {
                    Text("模型状态")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("加载状态: \(assistant.isModelLoaded ? "✅ 已加载" : "⏳ 加载中")")
                        Text("处理状态: \(assistant.isProcessing ? "🔄 处理中" : "✅ 就绪")")
                        
                        if let error = assistant.lastError {
                            Text("错误: \(error)")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // 调试选项
                VStack(alignment: .leading, spacing: 8) {
                    Text("调试工具")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        NavigationLink(destination: DebugToolsView().environmentObject(assistant)) {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver")
                                    .foregroundColor(.red)
                                Text("系统调试")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        Button("重启AI模型") {
                            // 重启模型逻辑
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        CleanFeatureListView()
            .environmentObject(AIAssistant())
    }
}
