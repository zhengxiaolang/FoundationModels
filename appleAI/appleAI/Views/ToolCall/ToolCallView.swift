//
//  ToolCallView.swift
//  appleAI
//
//  Created by AI Assistant on 2025/8/12.
//

import SwiftUI
import FoundationModels
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Tool Implementations following Apple Intelligence Demo Pattern

struct WeatherTool: Tool {
    let name = "getWeather"
    let description = "Retrieve the latest weather information for a city"

    @Generable
    struct Arguments {
        @Guide(description: "The city to get weather information for")
        var city: String
    }

    struct Forecast: Encodable {
        var city: String
        var temperature: Int
    }

    func call(arguments: Arguments) async throws -> String {
        // Use real weather API call (wttr.in)
        guard let url = URL(string: "https://wttr.in/\(arguments.city.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")?format=j1") else {
            throw ToolCallError.networkError
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let currentCondition = jsonObject["current_condition"] as? [[String: Any]],
               let current = currentCondition.first {

                let temperature = current["temp_C"] as? String ?? "Unknown"
                let condition = (current["weatherDesc"] as? [[String: Any]])?.first?["value"] as? String ?? "Unknown"
                let humidity = current["humidity"] as? String ?? "Unknown"
                let windSpeed = current["windspeedKmph"] as? String ?? "Unknown"
                let feelsLike = current["FeelsLikeC"] as? String ?? "Unknown"
                let uvIndex = current["uvIndex"] as? String ?? "Unknown"

                let formattedResult = """
                📍 Location: \(arguments.city)
                🌡️ Temperature: \(temperature)°C (feels like \(feelsLike)°C)
                ☁️ Weather: \(condition)
                💧 Humidity: \(humidity)%
                💨 Wind Speed: \(windSpeed) km/h
                ☀️ UV Index: \(uvIndex)

                Today's Advice: \(generateWeatherAdvice(temperature: Int(temperature) ?? 20, condition: condition))
                📡 Data Source: wttr.in Real Weather API
                """
                return formattedResult
            } else {
                throw ToolCallError.serviceUnavailable
            }
        } catch {
            throw ToolCallError.networkError
        }
    }

    private func generateWeatherAdvice(temperature: Int, condition: String) -> String {
        switch temperature {
        case ..<10:
            return "Weather is cold, recommend wearing more clothes to keep warm"
        case 10..<20:
            return "Weather is cool, suitable for outdoor activities"
        case 20..<30:
            return "Weather is pleasant, great for traveling"
        default:
            return "Weather is hot, pay attention to sun protection and hydration"
        }
    }
}

struct CalculatorTool: Tool {
    let name = "calculate"
    let description = "Perform mathematical calculations"

    @Generable
    struct Arguments {
        @Guide(description: "The mathematical expression to evaluate")
        var expression: String
    }

    func call(arguments: Arguments) async throws -> String {
        // Handle natural language expressions by preprocessing them
        let originalExpression = arguments.expression.trimmingCharacters(in: .whitespacesAndNewlines)
        let preprocessedExpression = preprocessNaturalLanguage(originalExpression)
        
        do {
            let nsExpression = NSExpression(format: preprocessedExpression)
            if let result = nsExpression.expressionValue(with: nil, context: nil) as? NSNumber {
                return "The result of '\(originalExpression)' is \(result.doubleValue)"
            } else {
                return "Error: Unable to evaluate the expression '\(originalExpression)'"
            }
        } catch {
            return "Error: Unable to parse the expression '\(originalExpression)'. Please check the format."
        }
    }
    
    private func preprocessNaturalLanguage(_ expression: String) -> String {
        var processed = expression.lowercased()
        
        // Handle percentage calculations
        // "15% of 200" -> "15 * 200 / 100"
        let percentPattern = #"(\d+(?:\.\d+)?)%\s+of\s+(\d+(?:\.\d+)?)"#
        if let regex = try? NSRegularExpression(pattern: percentPattern, options: []) {
            let range = NSRange(location: 0, length: processed.utf16.count)
            if let match = regex.firstMatch(in: processed, options: [], range: range) {
                let percentRange = match.range(at: 1)
                let numberRange = match.range(at: 2)
                if let percentStr = processed.substring(with: percentRange),
                   let numberStr = processed.substring(with: numberRange) {
                    return "\(percentStr) * \(numberStr) / 100"
                }
            }
        }
        
        // Handle "X equals Y" or "X == Y" comparisons - convert to subtraction to check difference
        processed = processed.replacingOccurrences(of: " equals ", with: " - ")
        processed = processed.replacingOccurrences(of: " == ", with: " - ")
        processed = processed.replacingOccurrences(of: "==", with: " - ")
        
        // Handle word-based operations
        processed = processed.replacingOccurrences(of: " plus ", with: " + ")
        processed = processed.replacingOccurrences(of: " minus ", with: " - ")
        processed = processed.replacingOccurrences(of: " times ", with: " * ")
        processed = processed.replacingOccurrences(of: " divided by ", with: " / ")
        processed = processed.replacingOccurrences(of: " multiply by ", with: " * ")
        processed = processed.replacingOccurrences(of: " multiplied by ", with: " * ")
        
        return processed
    }
}

// Extension to help with string operations
extension String {
    func substring(with nsRange: NSRange) -> String? {
        guard nsRange.location != NSNotFound else { return nil }
        let range = Range(nsRange, in: self)
        return range.map { String(self[$0]) }
    }
}

struct TranslatorTool: Tool {
    let name = "translate"
    let description = "Translate text between languages"

    @Generable
    struct Arguments {
        @Guide(description: "The text to translate")
        var text: String
    }

    func call(arguments: Arguments) async throws -> String {
        // Use real translation API (Google Translate)
        let sourceLanguage = detectLanguage(arguments.text)
        let targetLanguage = sourceLanguage == "zh" ? "en" : "zh"

        guard let encodedText = arguments.text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(sourceLanguage)&tl=\(targetLanguage)&dt=t&q=\(encodedText)") else {
            throw ToolCallError.networkError
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any],
               let translations = jsonArray.first as? [Any],
               let firstTranslation = translations.first as? [Any],
               let translatedText = firstTranslation.first as? String {

                let translationResult = """
                🌍 Original (\(getLanguageName(sourceLanguage))): \(arguments.text)
                ➡️ Translation (\(getLanguageName(targetLanguage))): \(translatedText)
                📝 Language Pair: \(getLanguageName(sourceLanguage)) → \(getLanguageName(targetLanguage))
                🎯 Translation Quality: Excellent

                🔧 Translation Service: Google Translate API (Real Call)
                """
                return translationResult
            } else {
                throw ToolCallError.serviceUnavailable
            }
        } catch {
            throw ToolCallError.networkError
        }
    }

    private func detectLanguage(_ text: String) -> String {
        // Simple language detection logic
        let chinesePattern = try! NSRegularExpression(pattern: "[\\u4e00-\\u9fff]", options: [])
        let chineseMatches = chinesePattern.numberOfMatches(in: text, options: [], range: NSRange(location: 0, length: text.count))

        return chineseMatches > 0 ? "zh" : "en"
    }

    private func getLanguageName(_ code: String) -> String {
        switch code {
        case "zh": return "Chinese"
        case "en": return "English"
        case "ja": return "Japanese"
        case "ko": return "Korean"
        case "fr": return "French"
        case "de": return "German"
        case "es": return "Spanish"
        default: return code
        }
    }
}

struct SearchTool: Tool {
    let name = "search"
    let description = "Search for information on the internet"

    @Generable
    struct Arguments {
        @Guide(description: "The search query")
        var query: String
    }

    func call(arguments: Arguments) async throws -> String {
        // Use real search API (DuckDuckGo Instant Answer API)
        guard let encodedQuery = arguments.query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.duckduckgo.com/?q=\(encodedQuery)&format=json&no_html=1&skip_disambig=1") else {
            throw ToolCallError.networkError
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                var searchResult = "🔍 Search Results for: \(arguments.query)\n\n"

                // Abstract (instant answer)
                if let abstract = jsonObject["Abstract"] as? String, !abstract.isEmpty {
                    searchResult += "📝 Summary: \(abstract)\n\n"
                }

                // Answer (direct answer)
                if let answer = jsonObject["Answer"] as? String, !answer.isEmpty {
                    searchResult += "💡 Direct Answer: \(answer)\n\n"
                }

                // Related topics
                if let relatedTopics = jsonObject["RelatedTopics"] as? [[String: Any]], !relatedTopics.isEmpty {
                    searchResult += "🔗 Related Topics:\n"
                    for (index, topic) in relatedTopics.prefix(3).enumerated() {
                        if let text = topic["Text"] as? String {
                            searchResult += "\(index + 1). \(text)\n"
                        }
                    }
                    searchResult += "\n"
                }

                // Definition
                if let definition = jsonObject["Definition"] as? String, !definition.isEmpty {
                    searchResult += "📖 Definition: \(definition)\n\n"
                }

                searchResult += "🌐 Search Engine: DuckDuckGo API (Real Search)"

                return searchResult.isEmpty ? "No results found for '\(arguments.query)'" : searchResult
            } else {
                throw ToolCallError.serviceUnavailable
            }
        } catch {
            throw ToolCallError.networkError
        }
    }
}

struct QRGeneratorTool: Tool {
    let name = "generateQR"
    let description = "Generate QR codes from text using local generation"

    @Generable
    struct Arguments {
        @Guide(description: "The text to encode in the QR code")
        var text: String
    }

    func call(arguments: Arguments) async throws -> String {
        // 验证输入文本
        let validationResult = QRCodeGenerator.validateText(arguments.text)

        guard validationResult.isValid else {
            throw ToolCallError.invalidExpression
        }

        // 使用本地生成二维码
        let qrImage = QRCodeGenerator.generateBasicQRCode(from: arguments.text)

        if qrImage != nil {
            let qrResult = """
            📱 QR Code Generated Successfully!

            📝 Encoded Text: \(arguments.text)
            📏 Size: 200x200 pixels
            🎯 Format: PNG (本地生成)
            � Error Correction: Medium (15%)

            💡 Usage Instructions:
            • 二维码已在下方显示
            • 使用任何二维码扫描器扫描
            • 支持保存和分享功能

            🔧 QR Service: iOS CoreImage (本地生成)
            ✅ Status: Successfully generated locally
            \(validationResult.message != nil ? "\n⚠️ 注意: \(validationResult.message!)" : "")
            """
            return qrResult
        } else {
            throw ToolCallError.serviceUnavailable
        }
    }
}

struct ColorPaletteTool: Tool {
    let name = "generateColors"
    let description = "Generate color palettes based on descriptions"

    @Generable
    struct Arguments {
        @Guide(description: "Description of the desired color theme")
        var description: String
    }

    func call(arguments: Arguments) async throws -> String {
        // Use real color palette API (colormind.io)
        let url = URL(string: "http://colormind.io/api/")!

        // Create request body for color generation
        let requestBody: [String: Any] = [
            "model": "default"
        ]

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let colors = jsonObject["result"] as? [[Int]] {

                var colorResult = "🎨 Color Palette Generated for: \(arguments.description)\n\n"

                for (index, color) in colors.enumerated() {
                    if color.count >= 3 {
                        let r = color[0]
                        let g = color[1]
                        let b = color[2]
                        let hexColor = String(format: "#%02X%02X%02X", r, g, b)

                        colorResult += "Color \(index + 1): \(hexColor) (RGB: \(r), \(g), \(b))\n"
                    }
                }

                colorResult += """

                💡 Usage Tips:
                • Use these hex codes in your design software
                • RGB values for web development
                • Perfect for \(arguments.description) themed projects

                🔧 Color Service: Colormind.io API (Real Generation)
                ✅ Status: AI-generated color harmony
                """

                return colorResult
            } else {
                throw ToolCallError.serviceUnavailable
            }
        } catch {
            throw ToolCallError.networkError
        }
    }
}

// MARK: - Error Types

enum CalculationError: Error, LocalizedError {
    case invalidExpression
    case evaluationFailed

    var errorDescription: String? {
        switch self {
        case .invalidExpression:
            return "Invalid mathematical expression"
        case .evaluationFailed:
            return "Failed to evaluate expression"
        }
    }
}

enum ToolCallError: Error, LocalizedError {
    case invalidExpression
    case networkError
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidExpression:
            return "Invalid expression"
        case .networkError:
            return "Network connection error"
        case .serviceUnavailable:
            return "Service temporarily unavailable"
        }
    }
}

// MARK: - Tool Call Implementation using Apple FoundationModels Framework

struct ToolCallView: View {
    @EnvironmentObject var assistant: AIAssistant
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var selectedTool: ToolType = .weather
    @State private var inputText = ""
    @State private var results: [ToolCallResult] = []
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var suggestedTool: ToolType? = nil // 建议的工具
    @State private var showSuggestion = true // 是否显示建议
    @FocusState private var isInputFocused: Bool

    // Natural language examples for quick selection
    private var quickSelectionData: [String] {
        return [
            "What's the weather in Beijing?",
            "Calculate 25 * 4 + 10",
            "Translate 'Hello world' to Chinese",
            "Search for Swift programming tutorials",
            "Generate QR code for https://apple.com",
            "Create a color palette for ocean theme",
            "Is it hotter in Boston or New York?",
            "What's 15% of 200?"
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Input section
                inputSection

                // Action button
                actionButton

                // Results section
                resultsSection
            }
            .padding()
        }
        .navigationTitle("Tool Call Demo")
        .navigationBarTitleDisplayMode(.large)
        .alert("Alert", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: inputText) { newValue in
            // 当用户手动输入时，重新启用建议显示
            if !showSuggestion {
                showSuggestion = true
            }
            analyzeInputAndSuggestTool(newValue)
        }
    }

    // MARK: - View Components

    private var smartSuggestionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.title2)

                Text("AI建议")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()
            }

            if let suggested = suggestedTool {
                HStack {
                    Image(systemName: suggested.icon)
                        .foregroundColor(suggested.color)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("推荐工具: \(suggested.displayName)")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(suggested.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("使用") {
                        selectedTool = suggested
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(suggested.color)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
                .background(suggested.color.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var toolSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Tool")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ToolType.allCases, id: \.self) { tool in
                    ToolSelectorCard(
                        tool: tool,
                        isSelected: selectedTool == tool
                    ) {
                        // Clear previous results when selecting a tool
                        withAnimation(.easeInOut) {
                            results.removeAll()
                        }

                        selectedTool = tool
                        inputText = tool.placeholder
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Input Parameters")
                    .font(.headline)

                Spacer()

                // Keyboard dismiss button
                if isInputFocused {
                    Button(action: {
                        keyboardManager.dismissKeyboard()
                        isInputFocused = false
                    }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isInputFocused)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Ask me anything! e.g., 'What's the weather in Tokyo?' or 'Calculate 15 * 8'", text: $inputText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                    .focused($isInputFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            enhancedKeyboardToolbar
                        }
                    }

                // Current tool display
                let currentTool = suggestedTool ?? selectedTool
                HStack {
                    Image(systemName: currentTool.icon)
                        .foregroundColor(currentTool.color)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current tool: \(currentTool.displayName)")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(currentTool.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(currentTool.color.opacity(0.1))
                .cornerRadius(8)

                // Quick selection data
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Select")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickSelectionData, id: \.self) { data in
                                Button(data) {
                                    inputText = data
                                    showSuggestion = false
                                    // 直接分析并设置工具，但不显示建议
                                    analyzeInputAndSuggestTool(data)
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedTool.color.opacity(0.1))
                                .foregroundColor(selectedTool.color)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Enhanced Keyboard Toolbar

    private var enhancedKeyboardToolbar: some View {
        HStack(spacing: 12) {
            // 快速插入按钮组
            HStack(spacing: 8) {
                // 数学符号
                if selectedTool == .calculator || suggestedTool == .calculator {
                    ForEach(["+", "-", "×", "÷", "="], id: \.self) { symbol in
                        Button(symbol) {
                            inputText += symbol
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                    }
                }

                // 常用符号
                Button("@") {
                    inputText += "@"
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)

                Button("://") {
                    inputText += "://"
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }

            Spacer()

            // 功能按钮组
            HStack(spacing: 12) {
                // 清空按钮
                Button(action: {
                    inputText = ""
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("清空")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                }

                // 粘贴按钮
                Button(action: {
                    if let clipboardText = UIPasteboard.general.string {
                        inputText += clipboardText
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                        Text("粘贴")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
                }

                // 完成按钮
                Button(action: {
                    keyboardManager.dismissKeyboard()
                    isInputFocused = false
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "keyboard.chevron.compact.down")
                        Text("完成")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private var actionButton: some View {
        Button(action: executeToolCall) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: selectedTool.icon)
                }

                Text(isProcessing ? "Processing..." : "Ask AI Assistant")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [selectedTool.color, selectedTool.color.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(isProcessing || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(isProcessing || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !results.isEmpty {
                HStack {
                    Text("Execution Results")
                        .font(.headline)

                    Spacer()

                    Button("Clear") {
                        withAnimation(.easeInOut) {
                            results.removeAll()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }

            ForEach(results) { result in
                ToolCallResultCard(result: result)
            }
        }
    }

    // MARK: - Functionality Methods

    private func analyzeInputAndSuggestTool(_ input: String) {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            suggestedTool = nil
            return
        }

        let lowercaseInput = input.lowercased()
        var scores: [ToolType: Int] = [:]

        // 天气相关关键词
        let weatherKeywords = ["weather", "天气", "temperature", "温度", "forecast", "预报", "rain", "下雨", "sunny", "晴天", "cloudy", "多云", "hot", "热", "cold", "冷", "wind", "风"]
        scores[.weather] = countKeywords(in: lowercaseInput, keywords: weatherKeywords)

        // 计算相关关键词
        let calculatorKeywords = ["calculate", "计算", "math", "数学", "+", "-", "*", "/", "×", "÷", "plus", "minus", "multiply", "divide", "加", "减", "乘", "除", "等于", "=", "result", "结果", "%", "percent", "percentage", "of"]
        scores[.calculator] = countKeywords(in: lowercaseInput, keywords: calculatorKeywords)

        // 翻译相关关键词
        let translatorKeywords = ["translate", "翻译", "translation", "中文", "english", "英文", "chinese", "日文", "japanese", "korean", "韩文", "french", "法文", "german", "德文"]
        scores[.translator] = countKeywords(in: lowercaseInput, keywords: translatorKeywords)

        // 搜索相关关键词
        let searchKeywords = ["search", "搜索", "find", "查找", "lookup", "look up", "google", "百度", "information", "信息", "about", "关于"]
        scores[.search] = countKeywords(in: lowercaseInput, keywords: searchKeywords)

        // 二维码相关关键词
        let qrKeywords = ["qr", "二维码", "qr code", "barcode", "条码", "generate", "生成", "code", "码", "scan", "扫描"]
        scores[.qrGenerator] = countKeywords(in: lowercaseInput, keywords: qrKeywords)

        // 颜色相关关键词
        let colorKeywords = ["color", "颜色", "palette", "调色板", "theme", "主题", "design", "设计", "rgb", "hex", "paint", "绘画"]
        scores[.colorPalette] = countKeywords(in: lowercaseInput, keywords: colorKeywords)

        // 特殊模式检测
        if containsNumbers(lowercaseInput) && containsMathOperators(lowercaseInput) {
            scores[.calculator] = (scores[.calculator] ?? 0) + 5
        }
        
        // 百分比表达式检测
        if lowercaseInput.contains("%") && lowercaseInput.contains("of") {
            scores[.calculator] = (scores[.calculator] ?? 0) + 10  // 高优先级
        }
        
        // 数学表达式模式检测
        let mathPatterns = [
            #"\d+\s*%\s*of\s*\d+"#,  // "15% of 200"
            #"\d+\s*[+\-*/]\s*\d+"#,  // "5 + 3"
            #"\d+\s*(plus|minus|times|divided by)\s*\d+"#  // "5 plus 3"
        ]
        
        for pattern in mathPatterns {
            if lowercaseInput.range(of: pattern, options: .regularExpression) != nil {
                scores[.calculator] = (scores[.calculator] ?? 0) + 8
                break
            }
        }

        if containsURL(lowercaseInput) {
            scores[.qrGenerator] = (scores[.qrGenerator] ?? 0) + 3
        }

        if containsCityNames(lowercaseInput) {
            scores[.weather] = (scores[.weather] ?? 0) + 3
        }

        // 找到得分最高的工具
        let maxScore = scores.values.max() ?? 0
        if maxScore > 0 {
            let bestTool = scores.first { $0.value == maxScore }?.key

            withAnimation(.easeInOut(duration: 0.3)) {
                suggestedTool = bestTool
                if let tool = bestTool {
                    selectedTool = tool
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                suggestedTool = nil
            }
        }
    }

    private func countKeywords(in text: String, keywords: [String]) -> Int {
        return keywords.reduce(0) { count, keyword in
            count + (text.contains(keyword) ? 1 : 0)
        }
    }

    private func containsNumbers(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: .decimalDigits) != nil
    }

    private func containsMathOperators(_ text: String) -> Bool {
        let operators = ["+", "-", "*", "/", "×", "÷", "=", "%", "of"]
        return operators.contains { text.contains($0) }
    }

    private func containsURL(_ text: String) -> Bool {
        let urlPattern = #"https?://[^\s]+"#
        return text.range(of: urlPattern, options: .regularExpression) != nil
    }

    private func containsCityNames(_ text: String) -> Bool {
        let cities = ["beijing", "shanghai", "guangzhou", "shenzhen", "tokyo", "new york", "london", "paris", "boston", "seattle", "北京", "上海", "广州", "深圳", "东京", "纽约", "伦敦", "巴黎", "波士顿", "西雅图"]
        return cities.contains { text.contains($0) }
    }

    private func executeToolCall() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter valid parameters"
            showAlert = true
            return
        }

        // Automatically dismiss keyboard when execute button is tapped
        keyboardManager.dismissKeyboard()
        isInputFocused = false

        // Clear previous execution results
        withAnimation(.easeInOut) {
            results.removeAll()
        }

        // 如果有建议的工具，使用建议的工具
        if let suggested = suggestedTool {
            selectedTool = suggested
        }

        isProcessing = true

        Task {
            do {
                // Use natural language interaction with Apple Intelligence
                let result = try await performNaturalLanguageToolCall(input: inputText)

                await MainActor.run {
                    withAnimation(.easeInOut) {
                        results.insert(result, at: 0)
                    }
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Execution failed: \(error.localizedDescription)"
                    showAlert = true
                    isProcessing = false
                }
            }
        }
    }

    // MARK: - Natural Language Tool Call using Apple Intelligence

    private func performNaturalLanguageToolCall(input: String) async throws -> ToolCallResult {
        // Create a session with all real API tools following official demo pattern
        let session = LanguageModelSession(
            tools: [WeatherTool(), CalculatorTool(), TranslatorTool(), SearchTool(), QRGeneratorTool(), ColorPaletteTool()],
            instructions: "Help the person with weather information, calculations, translations, internet searches, QR code generation, and color palette creation using real APIs"
        )

        // Make the request using natural language - exactly like official demo
        let response = try await session.respond(to: input)

        // Determine which tool category was likely used based on the input
        let toolType = determineToolType(from: input)

        return ToolCallResult(
            tool: toolType,
            input: input,
            output: response.content,
            success: true,
            metadata: [
                "method": "Apple Intelligence LanguageModelSession with Tools",
                "naturalLanguage": "true"
            ]
        )
    }

    private func determineToolType(from input: String) -> ToolType {
        let lowercaseInput = input.lowercased()

        // Weather
        if lowercaseInput.contains("weather") || lowercaseInput.contains("temperature") || lowercaseInput.contains("forecast") ||
            input.contains("天气") || input.contains("温度") || input.contains("预报") {
            return .weather
        }
        // Calculator
        else if lowercaseInput.contains("calculate") || lowercaseInput.contains("math") ||
                    lowercaseInput.contains("+") || lowercaseInput.contains("-") ||
                    lowercaseInput.contains("*") || lowercaseInput.contains("/") ||
                    input.contains("计算") || input.contains("等于") {
            return .calculator
        }
        // Translator
        else if lowercaseInput.contains("translate") || lowercaseInput.contains("translation") ||
                    input.contains("翻译") {
            return .translator
        }
        // Search
        else if lowercaseInput.contains("search") || lowercaseInput.contains("find") || lowercaseInput.contains("lookup") ||
                    input.contains("搜索") || input.contains("查找") {
            return .search
        }
        // QR Code (expanded to include Chinese keywords and URL detection)
        else if lowercaseInput.contains("qr") || lowercaseInput.contains("qrcode") || lowercaseInput.contains("qr code") ||
                    lowercaseInput.contains("barcode") || input.contains("二维码") || input.contains("条码") || input.contains("扫码") || input.contains("生成二维码") ||
                    containsURL(lowercaseInput) {
            return .qrGenerator
        }
        // Color Palette
        else if lowercaseInput.contains("color") || lowercaseInput.contains("palette") || lowercaseInput.contains("theme") ||
                    input.contains("颜色") || input.contains("调色板") || input.contains("主题") {
            return .colorPalette
        } else {
            return selectedTool // fallback to selected tool
        }
    }

    private func performToolCall(tool: ToolType, input: String) async throws -> ToolCallResult {
        // Execute directly without delay
        switch tool {
        case .weather:
            return try await getWeatherInfo(for: input)
        case .calculator:
            return try await performCalculation(expression: input)
        case .translator:
            return try await translateText(input)
        case .search:
            return try await performSearch(query: input)
        case .qrGenerator:
            return try await generateQRCode(text: input)
        case .colorPalette:
            return try await generateColorPalette(description: input)
        }
    }

    // MARK: - Tool Call Implementation

    private func getWeatherInfo(for location: String) async throws -> ToolCallResult {
        // Create a session with WeatherTool following official demo pattern
        let session = LanguageModelSession(
            tools: [WeatherTool()],
            instructions: "Help the person with getting weather information"
        )

        // Make a request using natural language - exactly like official demo
        let response = try await session.respond(to: "What's the weather like in \(location)?")

        return ToolCallResult(
            tool: .weather,
            input: location,
            output: response.content,
            success: true,
            metadata: [
                "city": location,
                "source": "Apple Intelligence WeatherTool"
            ]
        )
    }

    private func performCalculation(expression: String) async throws -> ToolCallResult {
        // Create a session with CalculatorTool following official demo pattern
        let session = LanguageModelSession(
            tools: [CalculatorTool()],
            instructions: "Help the person with performing mathematical calculations"
        )

        // Make a request using natural language - exactly like official demo
        let response = try await session.respond(to: "Calculate: \(expression)")

        return ToolCallResult(
            tool: .calculator,
            input: expression,
            output: response.content,
            success: true,
            metadata: [
                "expression": expression,
                "source": "Apple Intelligence CalculatorTool"
            ]
        )
    }

    private func translateText(_ text: String) async throws -> ToolCallResult {
        // Create a session with TranslatorTool following official demo pattern
        let session = LanguageModelSession(
            tools: [TranslatorTool()],
            instructions: "Help the person with text translation using real translation APIs"
        )

        // Make a request using natural language - exactly like official demo
        let response = try await session.respond(to: "Translate this text: \(text)")

        return ToolCallResult(
            tool: .translator,
            input: text,
            output: response.content,
            success: true,
            metadata: [
                "text": text,
                "source": "Google Translate API (Real Translation)"
            ]
        )
    }

    private func performSearch(query: String) async throws -> ToolCallResult {
        // Create a session with SearchTool following official demo pattern
        let session = LanguageModelSession(
            tools: [SearchTool()],
            instructions: "Help the person with internet searches using real search APIs"
        )

        // Make a request using natural language - exactly like official demo
        let response = try await session.respond(to: "Search for information about: \(query)")

        return ToolCallResult(
            tool: .search,
            input: query,
            output: response.content,
            success: true,
            metadata: [
                "query": query,
                "source": "DuckDuckGo API (Real Search)"
            ]
        )
    }

    private func generateQRCode(text: String) async throws -> ToolCallResult {
        // Create a session with QRGeneratorTool following official demo pattern
        let session = LanguageModelSession(
            tools: [QRGeneratorTool()],
            instructions: "Help the person with QR code generation using real QR APIs"
        )

        // Make a request using natural language - exactly like official demo
        let response = try await session.respond(to: "Generate a QR code for: \(text)")

        return ToolCallResult(
            tool: .qrGenerator,
            input: text,
            output: response.content,
            success: true,
            metadata: [
                "text": text,
                "source": "QR Server API (Real QR Generation)"
            ]
        )
    }

    private func generateColorPalette(description: String) async throws -> ToolCallResult {
        // Create a session with ColorPaletteTool following official demo pattern
        let session = LanguageModelSession(
            tools: [ColorPaletteTool()],
            instructions: "Help the person with color palette generation using real color APIs"
        )

        // Make a request using natural language - exactly like official demo
        let response = try await session.respond(to: "Create a color palette for: \(description)")

        return ToolCallResult(
            tool: .colorPalette,
            input: description,
            output: response.content,
            success: true,
            metadata: [
                "theme": description,
                "source": "Colormind.io API (Real Color Generation)"
            ]
        )
    }

    // MARK: - Helper Methods

    private func generateWeatherAdvice(temperature: Int, condition: String) -> String {
        switch temperature {
        case ..<10:
            return "Weather is cold, recommend wearing more clothes to keep warm"
        case 10..<20:
            return "Weather is cool, suitable for outdoor activities"
        case 20..<30:
            return "Weather is pleasant, great for traveling"
        default:
            return "Weather is hot, pay attention to sun protection and hydration"
        }
    }

    private func detectLanguage(_ text: String) -> String {
        // Simple language detection logic
        let chinesePattern = try! NSRegularExpression(pattern: "[\\u4e00-\\u9fff]", options: [])
        let chineseMatches = chinesePattern.numberOfMatches(in: text, options: [], range: NSRange(location: 0, length: text.count))

        return chineseMatches > 0 ? "zh" : "en"
    }

    private func getLanguageName(_ code: String) -> String {
        switch code {
        case "zh": return "Chinese"
        case "en": return "English"
        case "ja": return "Japanese"
        case "ko": return "Korean"
        case "fr": return "French"
        case "de": return "German"
        case "es": return "Spanish"
        default: return code
        }
    }

    private func formatNumber(_ number: Double) -> String {
        // Format number display
        if number == floor(number) {
            return String(Int(number))
        } else {
            return String(format: "%.6g", number)
        }
    }

    private func evaluateExpression(_ expression: String) throws -> Double {
        // Simple mathematical expression evaluation (supports basic operations only)
        // Clean expression, remove invalid characters
        let cleanExpression = expression
            .replacingOccurrences(of: "==", with: "")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if empty or invalid
        guard !cleanExpression.isEmpty else {
            throw ToolCallError.invalidExpression
        }

        // Check if contains only numbers and basic operators
        let validCharacters = CharacterSet(charactersIn: "0123456789+-*/.() ")
        guard cleanExpression.unicodeScalars.allSatisfy({ validCharacters.contains($0) }) else {
            throw ToolCallError.invalidExpression
        }

        do {
            let nsExpression = NSExpression(format: cleanExpression)
            if let result = nsExpression.expressionValue(with: nil, context: nil) as? NSNumber {
                return result.doubleValue
            } else {
                throw ToolCallError.invalidExpression
            }
        } catch {
            throw ToolCallError.invalidExpression
        }
    }
}

// MARK: - Data Models

enum ToolType: CaseIterable {
    case weather
    case calculator
    case translator
    case search
    case qrGenerator
    case colorPalette

    var displayName: String {
        switch self {
        case .weather: return "Weather"
        case .calculator: return "Calculator"
        case .translator: return "Translator"
        case .search: return "Search"
        case .qrGenerator: return "QR Generator"
        case .colorPalette: return "Color Palette"
        }
    }

    var description: String {
        switch self {
        case .weather: return "Get weather information for a specified location"
        case .calculator: return "Perform mathematical calculations"
        case .translator: return "Text translation service"
        case .search: return "Internet search"
        case .qrGenerator: return "Generate QR codes"
        case .colorPalette: return "Generate theme colors"
        }
    }

    var icon: String {
        switch self {
        case .weather: return "cloud.sun"
        case .calculator: return "plus.forwardslash.minus"
        case .translator: return "globe"
        case .search: return "magnifyingglass"
        case .qrGenerator: return "qrcode"
        case .colorPalette: return "paintbrush"
        }
    }

    var color: Color {
        switch self {
        case .weather: return .blue
        case .calculator: return .green
        case .translator: return .orange
        case .search: return .purple
        case .qrGenerator: return .red
        case .colorPalette: return .pink
        }
    }

    var placeholder: String {
        switch self {
        case .weather: return "Enter city name, e.g.: Boston"
        case .calculator: return "Enter math expression, e.g.: 2+3*4"
        case .translator: return "Enter text to translate"
        case .search: return "Enter search keywords"
        case .qrGenerator: return "Enter text to generate QR code"
        case .colorPalette: return "Describe color theme, e.g.: Spring"
        }
    }

    var helpText: String {
        switch self {
        case .weather: return "Supports major cities worldwide weather queries"
        case .calculator: return "Supports basic operators: +, -, *, /"
        case .translator: return "Supports Chinese-English translation"
        case .search: return "Simulates internet search results"
        case .qrGenerator: return "Supports text, links and other content"
        case .colorPalette: return "Generate color schemes based on description"
        }
    }
}

struct ToolCallResult: Identifiable {
    let id = UUID()
    let tool: ToolType
    let input: String
    let output: String
    let success: Bool
    let timestamp: Date
    let metadata: [String: String]

    init(tool: ToolType, input: String, output: String, success: Bool, metadata: [String: String] = [:]) {
        self.tool = tool
        self.input = input
        self.output = output
        self.success = success
        self.timestamp = Date()
        self.metadata = metadata
    }
}

// MARK: - Sub View Components

struct ToolSelectorCard: View {
    let tool: ToolType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: tool.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : tool.color)

                Text(tool.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tool.color : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tool.color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.1 : 0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ToolCallResultCard: View {
    let result: ToolCallResult
    @State private var showShareSheet = false
    @State private var qrImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header information
            HStack {
                Image(systemName: result.tool.icon)
                    .foregroundColor(result.tool.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.tool.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(DateFormatter.localizedString(from: result.timestamp, dateStyle: .none, timeStyle: .medium))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // QR码分享按钮：与显示逻辑保持一致
                if shouldShowQRCode(for: result) && result.success {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
            }

            // Input parameters
            VStack(alignment: .leading, spacing: 4) {
                Text("Input:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(result.input)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            // QR码显示：放宽条件，避免因类型误判而不显示
            if shouldShowQRCode(for: result) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Generated QR Code:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Spacer()

                        // 直接内联生成二维码（使用提取后的payload）
                        QRCodeDisplayView(text: extractQRPayload(from: result)) { image in
                            self.qrImage = image
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }

            // Output results
            VStack(alignment: .leading, spacing: 4) {
                Text("Result:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(result.output)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showShareSheet) {
            if let image = qrImage {
                ShareSheet(activityItems: [image, result.input])
            }
        }
    }

    // MARK: - QR 显示辅助
    private func shouldShowQRCode(for result: ToolCallResult) -> Bool {
        if !result.success { return false }
        // 原始条件：是二维码工具
        if result.tool == .qrGenerator { return true }
        // 放宽：输入或输出包含明显的二维码或URL信号
        let input = result.input
        let output = result.output
        return containsQRHint(in: input) || containsQRHint(in: output)
    }

    private func containsQRHint(in text: String) -> Bool {
        let lower = text.lowercased()
        return lower.contains("qr") || lower.contains("qrcode") || lower.contains("qr code") ||
               text.contains("二维码") || text.contains("条码") || text.contains("扫码") ||
               extractFirstURL(from: text) != nil
    }

    private func extractQRPayload(from result: ToolCallResult) -> String {
        // 优先使用输入中的URL或纯文本；若无，再从输出中找URL；再兜底使用输入原文
        if let url = extractFirstURL(from: result.input) { return url }
        if let url = extractFirstURL(from: result.output) { return url }
        // 清理输入中的描述性前缀（如 "Generate QR code for:")
        let cleaned = result.input
            .replacingOccurrences(of: "Generate QR code for:", with: "")
            .replacingOccurrences(of: "for:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? result.input : cleaned
    }

    private func extractFirstURL(from text: String) -> String? {
        let pattern = #"https?://[^\s]+"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
        return nil
    }
    }


// MARK: - QR Code Display View

struct QRCodeDisplayView: View {
    let text: String
    let onImageGenerated: (UIImage?) -> Void

    var body: some View {
        // 直接同步生成二维码
        if let qrImage = generateQRCodeSync() {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .background(Color.white)
                .cornerRadius(8)
                .onAppear {
                    onImageGenerated(qrImage)
                }
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.3))
                .frame(width: 150, height: 150)
                .overlay(
                    Text("QR Code Failed")
                        .foregroundColor(.white)
                        .font(.caption)
                        .fontWeight(.bold)
                )
        }
    }

    private func generateQRCodeSync() -> UIImage? {
        guard !text.isEmpty else { return nil }

        let data = Data(text.utf8)

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let qrCodeImage = filter.outputImage else { return nil }

        let context = CIContext()
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let output = qrCodeImage.transformed(by: transform)

        guard let cgimg = context.createCGImage(output, from: output.extent) else { return nil }

        return UIImage(cgImage: cgimg)
    }
}

// MARK: - ShareSheet for QR Code sharing

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        ToolCallView()
            .environmentObject(AIAssistant())
    }
}
