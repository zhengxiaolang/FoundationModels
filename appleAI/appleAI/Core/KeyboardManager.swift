import SwiftUI
import Combine

// MARK: - 键盘管理器
class KeyboardManager: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupKeyboardNotifications()
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
            }
            .map { $0.cgRectValue.height }
            .sink { [weak self] height in
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self?.keyboardHeight = height
                        self?.isKeyboardVisible = true
                    }
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self?.keyboardHeight = 0
                        self?.isKeyboardVisible = false
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                      to: nil, from: nil, for: nil)
    }
}

// MARK: - 键盘避让视图修饰符
struct KeyboardAwareModifier: ViewModifier {
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var currentOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .offset(y: currentOffset)
                .environmentObject(keyboardManager)
                .onReceive(keyboardManager.$keyboardHeight) { keyboardHeight in
                    // 如果键盘显示且高度大于0，调整偏移量
                    if keyboardHeight > 0 {
                        // 获取安全区域底部高度
                        let safeAreaBottom = geometry.safeAreaInsets.bottom
                        // 计算需要的偏移量，考虑安全区域
                        let offset = -(keyboardHeight - safeAreaBottom) / 2
                        withAnimation(.easeOut(duration: 0.25)) {
                            currentOffset = offset
                        }
                    } else {
                        // 键盘隐藏时重置偏移量
                        withAnimation(.easeOut(duration: 0.25)) {
                            currentOffset = 0
                        }
                    }
                }
                .onTapGesture {
                    keyboardManager.dismissKeyboard()
                }
        }
    }
}

extension View {
    func keyboardAware() -> some View {
        self.modifier(KeyboardAwareModifier())
    }
}

// MARK: - 智能输入框视图
struct SmartInputView: View {
    @Binding var text: String
    @EnvironmentObject var keyboardManager: KeyboardManager
    let placeholder: String
    let minHeight: CGFloat
    let maxHeight: CGFloat?
    let onSubmit: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String = "请输入...",
        minHeight: CGFloat = 100,
        maxHeight: CGFloat? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: minHeight, maxHeight: maxHeight)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .focused($isFocused)
                    .onSubmit {
                        onSubmit?()
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            HStack {
                                Spacer()
                                Button("完成") {
                                    isFocused = false
                                    keyboardManager.dismissKeyboard()
                                }
                                .font(.system(size: 16, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                        }
                    }
                
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - 键盘工具栏
struct KeyboardToolbar: View {
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: onDismiss) {
                HStack(spacing: 4) {
                    Image(systemName: "keyboard.chevron.compact.down")
                    Text("完成")
                }
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
    }
}

// MARK: - 增强的文本输入框
struct EnhancedTextField: View {
    @Binding var text: String
    @EnvironmentObject var keyboardManager: KeyboardManager
    let placeholder: String
    let onSubmit: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String = "请输入...",
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
                .onSubmit {
                    onSubmit?()
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button("完成") {
                                isFocused = false
                                keyboardManager.dismissKeyboard()
                            }
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }
                }
        }
    }
}

// MARK: - 增强的文本编辑器
struct EnhancedTextEditor: View {
    @Binding var text: String
    @EnvironmentObject var keyboardManager: KeyboardManager
    let placeholder: String
    let minHeight: CGFloat
    let maxHeight: CGFloat?
    
    @FocusState private var isFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String = "请输入...",
        minHeight: CGFloat = 100,
        maxHeight: CGFloat? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: minHeight, maxHeight: maxHeight)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .focused($isFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            HStack {
                                Spacer()
                                Button("完成") {
                                    isFocused = false
                                    keyboardManager.dismissKeyboard()
                                }
                                .font(.system(size: 16, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                        }
                    }
                
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - 智能输入区域视图
struct SmartInputSection<Content: View>: View {
    @EnvironmentObject var keyboardManager: KeyboardManager
    @Binding var inputText: String
    let title: String
    let placeholder: String
    let minHeight: CGFloat
    let buttonTitle: String
    let isProcessing: Bool
    let action: () -> Void
    let content: () -> Content
    
    init(
        inputText: Binding<String>,
        title: String = "输入内容",
        placeholder: String = "请输入...",
        minHeight: CGFloat = 100,
        buttonTitle: String = "开始处理",
        isProcessing: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self._inputText = inputText
        self.title = title
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.buttonTitle = buttonTitle
        self.isProcessing = isProcessing
        self.action = action
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            // 智能输入框
            SmartInputView(
                text: $inputText,
                placeholder: placeholder,
                minHeight: minHeight
            )
            
            // 额外内容
            content()
            
            // 处理按钮
            Button(action: action) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isProcessing ? "处理中..." : buttonTitle)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(inputText.isEmpty || isProcessing ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(inputText.isEmpty || isProcessing)
        }
    }
}

// MARK: - 滚动视图键盘避让修饰符
struct ScrollViewKeyboardAwareModifier: ViewModifier {
    @StateObject private var keyboardManager = KeyboardManager()
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ScrollView {
                content
                    .padding(.bottom, max(0, keyboardManager.keyboardHeight - geometry.safeAreaInsets.bottom))
                    .frame(minHeight: geometry.size.height - max(0, keyboardManager.keyboardHeight - geometry.safeAreaInsets.bottom))
            }
            .environmentObject(keyboardManager)
            .animation(.easeOut(duration: 0.25), value: keyboardManager.keyboardHeight)
            .onTapGesture {
                keyboardManager.dismissKeyboard()
            }
        }
    }
}

extension View {
    func scrollViewKeyboardAware() -> some View {
        self.modifier(ScrollViewKeyboardAwareModifier())
    }
}
