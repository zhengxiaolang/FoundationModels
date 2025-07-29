import SwiftUI

enum ViewMode {
    case basicTest
    case realModelTest
    case realAITest
    case compilationTest
    case fixVerification
    case simpleFeatures
    case fullFeatures
}

struct ContentView: View {
    @StateObject private var assistant = AIAssistant()
    @State private var viewMode: ViewMode = .basicTest
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
                        ProgressView("正在处理...")
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
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Button("基础测试") {
                            viewMode = .basicTest
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(viewMode == .basicTest ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(viewMode == .basicTest ? .white : .primary)
                        .cornerRadius(6)
                        .font(.caption)

                        Button("真实模型") {
                            viewMode = .realModelTest
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(viewMode == .realModelTest ? Color.purple : Color.gray.opacity(0.3))
                        .foregroundColor(viewMode == .realModelTest ? .white : .primary)
                        .cornerRadius(6)
                        .font(.caption)

                        Button("🧠真实AI") {
                            viewMode = .realAITest
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(viewMode == .realAITest ? Color.indigo : Color.gray.opacity(0.3))
                        .foregroundColor(viewMode == .realAITest ? .white : .primary)
                        .cornerRadius(6)
                        .font(.caption)
                    }

                    HStack(spacing: 8) {
                        Button("编译测试") {
                            viewMode = .compilationTest
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(viewMode == .compilationTest ? Color.red : Color.gray.opacity(0.3))
                        .foregroundColor(viewMode == .compilationTest ? .white : .primary)
                        .cornerRadius(6)
                        .font(.caption)

                        Button("修复验证") {
                            viewMode = .fixVerification
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(viewMode == .fixVerification ? Color.mint : Color.gray.opacity(0.3))
                        .foregroundColor(viewMode == .fixVerification ? .white : .primary)
                        .cornerRadius(6)
                        .font(.caption)

                        Button("简化功能") {
                            viewMode = .simpleFeatures
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(viewMode == .simpleFeatures ? Color.green : Color.gray.opacity(0.3))
                        .foregroundColor(viewMode == .simpleFeatures ? .white : .primary)
                        .cornerRadius(6)
                        .font(.caption)
                    }

                    Button("完整功能") {
                        viewMode = .fullFeatures
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(viewMode == .fullFeatures ? Color.orange : Color.gray.opacity(0.3))
                    .foregroundColor(viewMode == .fullFeatures ? .white : .primary)
                    .cornerRadius(6)
                    .font(.caption)
                }

                // 内容区域
                switch viewMode {
                case .basicTest:
                    SimpleTestView()
                        .environmentObject(assistant)
                case .realModelTest:
                    RealModelTestView()
                        .environmentObject(assistant)
                case .realAITest:
                    RealAITestView()
                        .environmentObject(assistant)
                case .compilationTest:
                    CompilationTestView()
                        .environmentObject(assistant)
                case .fixVerification:
                    FixVerificationView()
                        .environmentObject(assistant)
                case .simpleFeatures:
                    SimpleFeatureListView()
                        .environmentObject(assistant)
                case .fullFeatures:
                    FeatureListView()
                        .environmentObject(assistant)
                }
            }
        }
        .navigationTitle("AI Demo")
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
