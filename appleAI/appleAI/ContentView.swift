import SwiftUI

struct ContentView: View {
    @StateObject private var assistant = AIAssistant()
    @State private var showSplashScreen = true

    var body: some View {
        ZStack {
            if showSplashScreen {
                // 启动加载界面
                SplashScreenView(assistant: assistant)
                    .transition(.opacity)
            } else {
                // 主界面
                mainContentView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplashScreen)
        .onChange(of: assistant.isModelLoaded) { isLoaded in
            if isLoaded {
                // 模型加载完成后延迟1秒显示主界面
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showSplashScreen = false
                }
            }
        }
    }

    private var mainContentView: some View {
        NavigationView {
            HomeView()
                .environmentObject(assistant)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - 主页视图

struct HomeView: View {
    @EnvironmentObject var assistant: AIAssistant

    // 功能列表数据
    private let features: [FeatureItem] = [
        FeatureItem(
            title: "文本生成",
            description: "智能文本创作与内容生成",
            icon: "doc.text",
            color: .blue,
            destinationType: .textGeneration
        ),
        FeatureItem(
            title: "语言翻译",
            description: "多语言智能翻译服务",
            icon: "globe",
            color: .green,
            destinationType: .translation
        ),
        FeatureItem(
            title: "内容摘要",
            description: "智能文本摘要与提取",
            icon: "doc.plaintext",
            color: .orange,
            destinationType: .contentProcessing
        ),
        FeatureItem(
            title: "智能对话",
            description: "AI 助手对话交流",
            icon: "bubble.left.and.bubble.right",
            color: .purple,
            destinationType: .chat
        ),
        FeatureItem(
            title: "文本分析",
            description: "情感分析与关键词提取",
            icon: "chart.bar.doc.horizontal",
            color: .red,
            destinationType: .textAnalysis
        ),
        FeatureItem(
            title: "智能笔记",
            description: "AI 增强的笔记管理",
            icon: "note.text",
            color: .mint,
            destinationType: .smartNotes
        ),
        FeatureItem(
            title: "工具调用",
            description: "AI 工具调用演示",
            icon: "wrench.and.screwdriver",
            color: .indigo,
            destinationType: .toolCall
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 头部状态
                headerSection

                // 功能网格
                featuresGrid

                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("AI 助手")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - 视图组件

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Foundation Models")
                        .font(.title3)
                        .fontWeight(.semibold)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(assistant.isModelLoaded ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)

                        Text(assistant.isModelLoaded ? "就绪" : "加载中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if assistant.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(0.8)
                }
            }

            if let error = assistant.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)

                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var featuresGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(features) { feature in
                HomeFeatureCard(feature: feature)
            }
        }

    }
}

// MARK: - 功能卡片组件

struct HomeFeatureCard: View {
    let feature: FeatureItem
    @EnvironmentObject var assistant: AIAssistant

    var body: some View {
        NavigationLink(destination: destinationView) {
            VStack(spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(feature.color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: feature.icon)
                        .font(.title2)
                        .foregroundColor(feature.color)
                }

                // 文本内容
                VStack(spacing: 4) {
                    Text(feature.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text(feature.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding()
            .frame(height: 140)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var destinationView: some View {
        switch feature.destinationType {
        case .textGeneration:
            TextGenerationView()
                .environmentObject(assistant)
        case .translation:
            TranslationView()
                .environmentObject(assistant)
        case .contentProcessing:
            ContentProcessingView()
                .environmentObject(assistant)
        case .chat:
            ChatView()
                .environmentObject(assistant)
        case .textAnalysis:
            TextAnalysisView()
                .environmentObject(assistant)
        case .smartNotes:
            SmartNotesView()
                .environmentObject(assistant)
        case .toolCall:
            ToolCallView()
                .environmentObject(assistant)
        default:
            Text("功能开发中...")
                .navigationTitle(feature.title)
        }
    }
}

struct SplashScreenView: View {
    let assistant: AIAssistant
    @State private var animationPhase = 0
    @State private var showDetails = false

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // 主标题和图标
                VStack(spacing: 20) {
                    // 动画图标
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .scaleEffect(animationPhase == 0 ? 0.8 : 1.2)
                            .opacity(animationPhase == 0 ? 1 : 0.3)

                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .scaleEffect(animationPhase == 1 ? 0.8 : 1.1)
                            .opacity(animationPhase == 1 ? 1 : 0.5)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white)
                            .scaleEffect(animationPhase == 2 ? 1.2 : 1.0)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            animationPhase = 1
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                animationPhase = 2
                            }
                        }
                    }

                    // 标题
                    VStack(spacing: 8) {
                        Text("Apple Foundation Models")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("AI Demo")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                Spacer()

                // 加载状态
                VStack(spacing: 16) {
                    // 加载进度
                    VStack(spacing: 12) {
                        HStack {
                            Circle()
                                .fill(assistant.isModelLoaded ? Color.green : Color.orange)
                                .frame(width: 12, height: 12)

                            Text(assistant.isModelLoaded ? "模型加载完成" : assistant.loadingProgress)
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        if !assistant.isModelLoaded {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)

                                // 动态点点点动画
                                HStack(spacing: 2) {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .fill(Color.white.opacity(0.8))
                                            .frame(width: 4, height: 4)
                                            .scaleEffect(animationPhase == index ? 1.5 : 1.0)
                                            .animation(
                                                .easeInOut(duration: 0.6)
                                                .repeatForever(autoreverses: true)
                                                .delay(Double(index) * 0.2),
                                                value: animationPhase
                                            )
                                    }
                                }
                            }
                        }
                    }

                    // 详细信息
                    if showDetails {
                        VStack(spacing: 8) {
                            Text("• 加载 Natural Language 框架")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))

                            Text("• 初始化文本处理模型")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))

                            Text("• 准备 AI 功能模块")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .transition(.opacity)
                    }

                    if let error = assistant.lastError {
                        Text("初始化失败: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                    }
                }

                Spacer()

                // 底部信息
                VStack(spacing: 4) {
                    Text("基于真实 Apple AI 框架")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Text("设备端处理 • 隐私保护")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 50)
            }
            .padding()
        }
        .onAppear {
            // 启动点点点动画
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }

            // 延迟显示详细信息
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showDetails = true
                }
            }
        }
    }
}



#Preview {
    ContentView()
}
