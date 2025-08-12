//
//  ToolCallView.swift
//  appleAI
//
//  Created by AI Assistant on 2025/8/12.
//

import SwiftUI
import FoundationModels

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
        // Get a random temperature value. Use `WeatherKit` to get
        // a temperature for the city.
        let temperature = Int.random(in: 30...100)
        let formattedResult = """
        The forecast for '\(arguments.city)' is '\(temperature)' \
        degrees Fahrenheit.
        """
        return formattedResult
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
        // Simple calculation using NSExpression
        let cleanExpression = arguments.expression.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let nsExpression = NSExpression(format: cleanExpression)
            if let result = nsExpression.expressionValue(with: nil, context: nil) as? NSNumber {
                return "The result of '\(cleanExpression)' is \(result.doubleValue)"
            } else {
                throw CalculationError.invalidExpression
            }
        } catch {
            throw CalculationError.evaluationFailed
        }
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
        // Simple translation simulation
        let text = arguments.text
        let isEnglish = text.range(of: "[a-zA-Z]", options: .regularExpression) != nil

        if isEnglish {
            return "Translation to Chinese: This is the translated text - \(text)"
        } else {
            return "Translation to English: This is the translated text - \(text)"
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
                // Tool selector
                toolSelector

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
    }
    
    // MARK: - View Components

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
                
                Text("💡 You can use natural language! Try: 'What's the weather in Beijing?' or 'Calculate 25 * 4'")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)

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
                                    // Automatically clear previous results
                                    withAnimation(.easeInOut) {
                                        results.removeAll()
                                    }
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
        // Create a session with tools following official demo pattern
        let session = LanguageModelSession(
            tools: [WeatherTool(), CalculatorTool()],
            instructions: "Help the person with getting weather information and performing calculations"
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

        if lowercaseInput.contains("weather") || lowercaseInput.contains("temperature") || lowercaseInput.contains("forecast") {
            return .weather
        } else if lowercaseInput.contains("calculate") || lowercaseInput.contains("math") ||
                  lowercaseInput.contains("+") || lowercaseInput.contains("-") ||
                  lowercaseInput.contains("*") || lowercaseInput.contains("/") {
            return .calculator
        } else if lowercaseInput.contains("translate") || lowercaseInput.contains("translation") {
            return .translator
        } else if lowercaseInput.contains("search") || lowercaseInput.contains("find") || lowercaseInput.contains("lookup") {
            return .search
        } else if lowercaseInput.contains("qr") || lowercaseInput.contains("code") || lowercaseInput.contains("barcode") {
            return .qrGenerator
        } else if lowercaseInput.contains("color") || lowercaseInput.contains("palette") || lowercaseInput.contains("theme") {
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
        // Use Apple FoundationModels framework for translation
        let session = LanguageModelSession(
            instructions: "You are a translation assistant. Translate text between languages accurately."
        )

        let response = try await session.respond(to: "Translate this text: \(text)")

        return ToolCallResult(
            tool: .translator,
            input: text,
            output: response.content,
            success: true,
            metadata: [
                "text": text,
                "source": "Apple FoundationModels"
            ]
        )
    }
    
    private func performSearch(query: String) async throws -> ToolCallResult {
        // Use Apple FoundationModels framework for search
        let session = LanguageModelSession(
            instructions: "You are a search assistant. Provide helpful information and search results for user queries."
        )

        let response = try await session.respond(to: "Search for information about: \(query)")

        return ToolCallResult(
            tool: .search,
            input: query,
            output: response.content,
            success: true,
            metadata: [
                "query": query,
                "source": "Apple FoundationModels"
            ]
        )
    }
    
    private func generateQRCode(text: String) async throws -> ToolCallResult {
        // Use Apple FoundationModels framework for QR code generation
        let session = LanguageModelSession(
            instructions: "You are a QR code assistant. Help users generate QR codes and provide information about them."
        )

        let response = try await session.respond(to: "Generate a QR code for: \(text)")

        return ToolCallResult(
            tool: .qrGenerator,
            input: text,
            output: response.content,
            success: true,
            metadata: [
                "text": text,
                "source": "Apple FoundationModels"
            ]
        )
    }
    
    private func generateColorPalette(description: String) async throws -> ToolCallResult {
        // Use Apple FoundationModels framework for color palette generation
        let session = LanguageModelSession(
            instructions: "You are a color palette assistant. Generate beautiful color palettes based on themes and descriptions."
        )

        let response = try await session.respond(to: "Create a color palette for: \(description)")

        return ToolCallResult(
            tool: .colorPalette,
            input: description,
            output: response.content,
            success: true,
            metadata: [
                "theme": description,
                "source": "Apple FoundationModels"
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
        case .calculator: return "calculator"
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        ToolCallView()
            .environmentObject(AIAssistant())
    }
}
