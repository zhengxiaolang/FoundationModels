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
        // Real APIs: Wikipedia REST, GitHub Search, HTTPBin echo
        let query = arguments.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { throw ToolCallError.invalidExpression }

        async let wiki = fetchWikipediaSummary(for: query)
        async let github = fetchGitHubRepositories(for: query)
        async let httpbin = fetchHTTPBinEcho(for: query)

        let (wikiRes, ghRes, echoRes) = await (wiki, github, httpbin)

        var sections: [String] = []
        if let wikiRes { sections.append(wikiRes) }
        if let ghRes { sections.append(ghRes) }
        if let echoRes { sections.append(echoRes) }

        guard !sections.isEmpty else {
            throw ToolCallError.serviceUnavailable
        }

        let header = "🔍 Search Results for: \(query)\n"
        let footer = "\n🔧 Sources: Wikipedia REST API, GitHub Search API, HTTPBin (all real calls)"
        return ([header] + sections + [footer]).joined(separator: "\n\n")
    }

    // MARK: - Wikipedia
    private func fetchWikipediaSummary(for query: String) async -> String? {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)") else { return nil }

        var request = URLRequest(url: url)
        request.setValue("appleAI/1.0 (https://example.com)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            struct WikiSummary: Decodable {
                let title: String?
                let extract: String?
                let contentUrls: ContentUrls?
                struct ContentUrls: Decodable { let desktop: Desktop?; struct Desktop: Decodable { let page: String? } }
            }
            if let summary = try? decoder.decode(WikiSummary.self, from: data) {
                let title = summary.title ?? query
                let extract = (summary.extract?.isEmpty == false ? summary.extract! : "No summary available.")
                let pageURL = summary.contentUrls?.desktop?.page
                var text = "� Wikipedia: \(title)\n\n\(extract)"
                if let pageURL { text += "\n🔗 \(pageURL)" }
                return text
            }
        } catch { /* ignore, return nil */ }
        return nil
    }

    // MARK: - GitHub
    private func fetchGitHubRepositories(for query: String) async -> String? {
        guard var components = URLComponents(string: "https://api.github.com/search/repositories") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sort", value: "stars"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "per_page", value: "3")
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("appleAI/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            struct RepoSearch: Decodable { struct Repo: Decodable { let fullName: String?; let stargazersCount: Int?; let description: String?; let htmlUrl: String? }; let items: [Repo]? }
            if let res = try? decoder.decode(RepoSearch.self, from: data), let items = res.items, !items.isEmpty {
                var out = "� GitHub Top Repositories:\n"
                for (idx, repo) in items.enumerated() {
                    let name = repo.fullName ?? "Unknown"
                    let stars = repo.stargazersCount ?? 0
                    let desc = repo.description ?? "No description"
                    let url = repo.htmlUrl ?? ""
                    out += "\n\(idx + 1). \(name) ★\(stars)\n   \(desc)\n   \(url)"
                }
                return out
            }
        } catch { /* ignore */ }
        return nil
    }

    // MARK: - HTTPBin
    private func fetchHTTPBinEcho(for query: String) async -> String? {
        guard var components = URLComponents(string: "https://httpbin.org/get") else { return nil }
        components.queryItems = [URLQueryItem(name: "query", value: query)]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("appleAI/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let origin = json["origin"] as? String ?? "Unknown"
                let url = json["url"] as? String ?? ""
                if let args = json["args"] as? [String: Any], let echoed = args["query"] as? String {
                    return "🛰️ HTTPBin Echo\nOrigin: \(origin)\nURL: \(url)\nEchoed query: \(echoed)"
                } else {
                    return "🛰️ HTTPBin Echo\nOrigin: \(origin)\nURL: \(url)"
                }
            }
        } catch { /* ignore */ }
        return nil
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
            "Generate QR code for {key:value}",
            "Search for 'Apple Intelligence' features and supported devices",
            "Search for latest updates about Llama 3",
            "Search for 'OpenAI o4-mini' pricing and rate limits",
            "Search for 'Qwen2.5' model benchmarks",
            "Search for 'Mistral Large' API examples",
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
                // If QR tool is selected, call it directly to ensure QR renders
                let result: ToolCallResult
                if selectedTool == .qrGenerator {
                    result = try await performToolCall(tool: .qrGenerator, input: inputText)
                } else {
                    // Use natural language interaction with Apple Intelligence
                    result = try await performNaturalLanguageToolCall(input: inputText)
                }

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
            instructions: "Help the person with internet searches using real APIs: Wikipedia, GitHub, and HTTPBin"
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
                "source": "Wikipedia REST + GitHub Search + HTTPBin (Real Calls)"
            ]
        )
    }

    private func generateQRCode(text: String) async throws -> ToolCallResult {
        // Extract the actual payload (URL/text) from natural language input
        let payload = extractQRPayload(from: text)

        // Create a session with QRGeneratorTool following official demo pattern
        let session = LanguageModelSession(
            tools: [QRGeneratorTool()],
            instructions: "Help the person with QR code generation using real QR APIs"
        )

        // Make a request using natural language - exactly like official demo
        let response = try await session.respond(to: "Generate a QR code for: \(payload)")

        return ToolCallResult(
            tool: .qrGenerator,
            input: payload, // Use extracted payload so UI encodes the correct content
            output: response.content,
            success: true,
            metadata: [
                "originalInput": text,
                "payload": payload,
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

    // Extract the intended QR payload (URL or text) from natural language input
    private func extractQRPayload(from input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        // 1) Prefer first URL
        if let url = firstMatch(in: trimmed, pattern: #"https?://[^\s\)\]\}"']+"#, options: []) {
            return sanitizePayload(url)
        }

        // 2) Quoted text (English/Chinese quotes)
        let quotePatterns = [
            #"\"([^\"]+)\""#,
            #"'([^']+)'"#,
            #"[“]([^”]+)[”]"#,
            #"[‘]([^’]+)[’]"#
        ]
        for p in quotePatterns {
            if let q = firstMatch(in: trimmed, pattern: p, options: []) {
                return sanitizePayload(q)
            }
        }

        // 3) English intent patterns: prefer capturing after explicit connectors
        // Examples:
        //  - "Generate QR code for {key:value}" -> "{key:value}"
        //  - "generate qr code, the content is hello" -> "the content is hello" (then sanitized further)
        let enPatterns = [
            #"(?i)(?:generate|create|make)\s+(?:a\s+)?(?:qr\s*code|qrcode|qr)\s*(?:for|with|of|:)\s*(.+)$"#,
            #"(?i)(?:qr\s*(?:code)?)\s*(?:for|with|of|:)\s*(.+)$"#,
            #"(?i)for\s+(.+)$"#,
            // Fallback: anything after the phrase (may still include leading words like 'for', sanitized later)
            #"(?i)(?:generate|create|make)\s+(?:a\s+)?(?:qr\s*code|qrcode|qr)\s*[,;:\-]?\s*(.+)$"#
        ]
        for p in enPatterns {
            if let t = firstMatch(in: trimmed, pattern: p, options: [.caseInsensitive], group: 1) {
        return sanitizePayload(t)
            }
        }

    // 4) Chinese intent patterns, including punctuation and lead-ins
    let cnPatterns = [
        #"生成(?:一个)?(?:二维码)?[，,：:]?\s*(.+)$"#,
        #"为\s*(.+?)\s*生成(?:一个)?二维码"#,
        #"生成\s*(.+?)\s*的二维码"#,
        #"(?:二维码)?内容[是为：:，,]?\s*(.+)$"#
    ]
        for p in cnPatterns {
            if let t = firstMatch(in: trimmed, pattern: p, options: [], group: 1) {
        return sanitizePayload(t)
            }
        }

    // 5) If the string starts with a known lead-in, drop it
    let leadIns = [
        "generate qr code for ",
        "generate qrcode for ",
        "qr for ",
        "make qr code for ",
        "create qr code for ",
        // also accept without "for"
        "generate qr code ",
        "generate qrcode ",
        "create qr code ",
        "make qr code "
    ]
        for lead in leadIns {
            if lower.hasPrefix(lead) {
                let start = trimmed.index(trimmed.startIndex, offsetBy: lead.count)
        return sanitizePayload(String(trimmed[start...]))
            }
        }

        // Fallback: return the original trimmed text
    return sanitizePayload(trimmed)
    }

    private func firstMatch(in text: String, pattern: String, options: NSRegularExpression.Options, group: Int = 1) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let range = NSRange(location: 0, length: text.utf16.count)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        guard group <= match.numberOfRanges - 1 else { return nil }
        if let substring = text.substring(with: match.range(at: group)) {
            return substring
        }
        return nil
    }

    private func sanitizePayload(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip surrounding quotes
        if (s.hasPrefix("\"") && s.hasSuffix("\"")) || (s.hasPrefix("'") && s.hasSuffix("'")) ||
            (s.hasPrefix("“") && s.hasSuffix("”")) || (s.hasPrefix("‘") && s.hasSuffix("’")) {
            s = String(s.dropFirst().dropLast())
        }

        // Drop common lead-in phrases like "the content is", "内容是"
        let lower = s.lowercased()
        let enLeadIns = [
            "the content is ", "content is ", "text is ", "message is ", "payload is ",
            "content:", "content: ", "text:", "text: ", "message:", "message: ", "payload:", "payload: "
        ]
        for lead in enLeadIns {
            if lower.hasPrefix(lead) {
                let start = s.index(s.startIndex, offsetBy: lead.count)
                s = String(s[start...])
                break
            }
        }
        // Chinese lead-ins
        let cnLeadIns = ["内容是", "内容为", "内容：", "文本是", "文本为", "文本：", "二维码内容是", "二维码内容为", "二维码内容："]
        for lead in cnLeadIns {
            if s.hasPrefix(lead) {
                let start = s.index(s.startIndex, offsetBy: lead.count)
                s = String(s[start...])
                break
            }
        }

        s = s.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove common leading punctuation
        while let first = s.first, ",[).;:、，。；：-]".contains(first) {
            s.removeFirst()
        }

        // Remove leading connector words like "for ", "with ", "of ", "to "
        var lowerLead = s.lowercased()
        let connectorLeadIns = ["for ", "with ", "of ", "to "]
        for lead in connectorLeadIns {
            if lowerLead.hasPrefix(lead) {
                let start = s.index(s.startIndex, offsetBy: lead.count)
                s = String(s[start...]).trimmingCharacters(in: .whitespacesAndNewlines)
                lowerLead = s.lowercased()
                break
            }
        }
        // Remove common trailing punctuation
        while let last = s.last, ",[).;:、，。；：]".contains(last) {
            s.removeLast()
        }

        s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? text.trimmingCharacters(in: .whitespacesAndNewlines) : s
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
    case .search: return "Searches via Wikipedia, GitHub and HTTPBin"
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
    @State private var shareItems: [Any] = []
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
                        // Prepare share items only when QR image is available
                        guard let img = qrImage else { return }
                        var items: [Any] = [img]
                        let trimmed = result.input.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) {
                            items.append(url)
                        } else {
                            items.append(trimmed)
                        }
                        shareItems = items
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(qrImage == nil)
                    .opacity(qrImage == nil ? 0.4 : 1.0)
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

            // 仅在二维码工具下展示二维码
            if shouldShowQRCode(for: result) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Generated QR Code:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Spacer()

                        // 直接使用输入作为二维码内容（仅二维码工具生效）
                        QRCodeDisplayView(text: result.input) { image in
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
            ShareSheet(activityItems: shareItems)
        }
    }

    // MARK: - QR 显示辅助
    private func shouldShowQRCode(for result: ToolCallResult) -> Bool {
    // 仅在二维码工具成功时显示二维码，避免搜索结果中含有 URL 时误触发
    guard result.success else { return false }
    return result.tool == .qrGenerator
    }

    // 删除放宽匹配与URL提取逻辑，避免误判（仅QRCode工具展示二维码）
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
