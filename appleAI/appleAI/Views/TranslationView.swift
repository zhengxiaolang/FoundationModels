import SwiftUI

struct TranslationView: View {
    @EnvironmentObject var assistant: AIAssistant
    @StateObject private var textManager = TextGenerationManager()
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var showResult = false
    @State private var selectedTargetLanguage: LanguageOption = .english
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
                        Text("目标语言设置")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("翻译为：")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
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
                                
                                Button("复制结果") {
                                    UIPasteboard.general.string = translatedText
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                            }
                            
                            // Instructions 说明
                            VStack(alignment: .leading, spacing: 8) {
                                Text("翻译指令")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text("将以下文本翻译为\(selectedTargetLanguage.displayName)，要求准确传达原意，语言自然流畅，符合目标语言的表达习惯。")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(6)
                            }
                            
                            // 用户输入
                            VStack(alignment: .leading, spacing: 8) {
                                Text("原文内容")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text(inputText)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // 翻译结果
                            VStack(alignment: .leading, spacing: 8) {
                                Text("翻译结果")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text(translatedText)
                                    .font(.body)
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
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
        .scrollViewKeyboardAware()
        .environmentObject(keyboardManager)
    }
    
    private func translateText() {
        guard !inputText.isEmpty else { return }

        keyboardManager.dismissKeyboard()

        Task {
            do {
                // 使用 TextGenerationManager 的真正AI翻译
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
                    translatedText = "翻译失败：\(error.localizedDescription)"
                    showResult = true
                }
                print("翻译失败: \(error)")
            }
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
