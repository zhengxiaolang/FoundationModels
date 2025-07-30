import SwiftUI

struct TranslationView: View {
    @StateObject private var textManager = TextGenerationManager()
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var showResult = false
    @State private var selectedTargetLanguage: LanguageOption = .english
    @State private var detectedLanguage = "自动检测"
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题和说明
                    VStack(spacing: 12) {
                        Text("🌐 AI智能翻译")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("基于Apple AI技术的多语言翻译")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // 语言选择
                    VStack(alignment: .leading, spacing: 16) {
                        Text("翻译设置")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 16) {
                            // 源语言显示
                            VStack(spacing: 8) {
                                Text("源语言")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(detectedLanguage)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                            
                            // 目标语言选择
                            VStack(spacing: 8) {
                                Text("目标语言")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Menu {
                                    ForEach(LanguageOption.allCases, id: \.self) { language in
                                        Button(language.displayName) {
                                            selectedTargetLanguage = language
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedTargetLanguage.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // 输入区域
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("输入要翻译的文本")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // 键盘关闭按钮
                            if keyboardManager.isKeyboardVisible {
                                Button(action: {
                                    keyboardManager.dismissKeyboard()
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
                        
                        TextEditor(text: $inputText)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: inputText) { _ in
                                updateDetectedLanguage()
                            }
                        
                        if inputText.isEmpty {
                            Text("例如：Hello, how are you today?")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 翻译按钮
                    Button(action: translateText) {
                        HStack {
                            if textManager.isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }

                            Text(textManager.isProcessing ? "正在翻译..." : "🚀 开始翻译")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            inputText.isEmpty || textManager.isProcessing ?
                            Color.gray : Color.blue
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(inputText.isEmpty || textManager.isProcessing)
                    .padding(.horizontal)
                    .onTapGesture {
                        keyboardManager.dismissKeyboard()
                    }
                    
                    // 翻译结果
                    if showResult {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("翻译结果")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button("复制") {
                                    UIPasteboard.general.string = translatedText
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                            }
                            
                            Text(translatedText)
                                .font(.body)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                            
                            // 操作按钮
                            HStack(spacing: 12) {
                                Button("重新翻译") {
                                    translateText()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                                
                                Button("交换语言") {
                                    swapLanguages()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
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
            .navigationTitle("智能翻译")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .keyboardAware()
        .environmentObject(keyboardManager)
    }
    
    private func translateText() {
        guard !inputText.isEmpty else { return }

        keyboardManager.dismissKeyboard()

        Task {
            do {
                let result = try await textManager.generateTranslation(
                    text: inputText,
                    to: selectedTargetLanguage.displayName
                )

                await MainActor.run {
                    translatedText = result
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showResult = true
                    }
                }
            } catch {
                await MainActor.run {
                    translatedText = "翻译失败，请重试"
                    showResult = true
                }
                print("翻译失败: \(error)")
            }
        }
    }
    
    private func updateDetectedLanguage() {
        // 简单的语言检测逻辑
        if inputText.isEmpty {
            detectedLanguage = "自动检测"
            return
        }
        
        let chinesePattern = "[\u{4e00}-\u{9fff}]"
        let englishPattern = "[a-zA-Z]"
        
        if inputText.range(of: chinesePattern, options: .regularExpression) != nil {
            detectedLanguage = "中文"
        } else if inputText.range(of: englishPattern, options: .regularExpression) != nil {
            detectedLanguage = "英文"
        } else {
            detectedLanguage = "未知语言"
        }
    }
    
    private func swapLanguages() {
        // 交换输入和输出文本
        let temp = inputText
        inputText = translatedText
        translatedText = temp
        
        // 更新检测语言
        updateDetectedLanguage()
        
        // 如果有结果，重新翻译
        if showResult && !inputText.isEmpty {
            translateText()
        }
    }
}

enum LanguageOption: String, CaseIterable {
    case chinese = "zh"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case spanish = "es"
    
    var displayName: String {
        switch self {
        case .chinese:
            return "中文"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        case .french:
            return "Français"
        case .german:
            return "Deutsch"
        case .spanish:
            return "Español"
        }
    }
    
    var code: String {
        return self.rawValue
    }
}

#Preview {
    TranslationView()
        .environmentObject(AIAssistant())
}
