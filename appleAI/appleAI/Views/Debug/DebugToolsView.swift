import SwiftUI

struct DebugToolsView: View {
    @EnvironmentObject var assistant: AIAssistant
    @StateObject private var debugLogger = DebugLogger.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SystemInfoView()
                .environmentObject(assistant)
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("系统信息")
                }
                .tag(0)

            PerformanceMonitorView()
                .environmentObject(assistant)
                .tabItem {
                    Image(systemName: "speedometer")
                    Text("性能监控")
                }
                .tag(1)

            LogViewerView()
                .environmentObject(assistant)
                .tabItem {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("日志查看")
                }
                .tag(2)

            ErrorTrackingView()
                .environmentObject(assistant)
                .tabItem {
                    Image(systemName: "exclamationmark.triangle")
                    Text("错误追踪")
                }
                .tag(3)
        }
        .navigationTitle("调试工具")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SystemInfoView: View {
    @EnvironmentObject var assistant: AIAssistant
    
    var body: some View {
        List {
            Section("设备信息") {
                InfoRow(title: "设备型号", value: UIDevice.current.model)
                InfoRow(title: "系统版本", value: UIDevice.current.systemVersion)
                InfoRow(title: "设备名称", value: UIDevice.current.name)
                InfoRow(title: "设备标识", value: UIDevice.current.identifierForVendor?.uuidString ?? "未知")
            }
            
            Section("Foundation Models 支持") {
                InfoRow(
                    title: "设备支持",
                    value: FoundationLanguageModel.isSupported ? "✅ 支持" : "❌ 不支持",
                    valueColor: FoundationLanguageModel.isSupported ? .green : .red
                )
                InfoRow(
                    title: "模型状态",
                    value: assistant.isModelLoaded ? "✅ 已加载" : "⏳ 未加载",
                    valueColor: assistant.isModelLoaded ? .green : .orange
                )
                InfoRow(
                    title: "处理状态",
                    value: assistant.isProcessing ? "🔄 处理中" : "✅ 空闲",
                    valueColor: assistant.isProcessing ? .orange : .green
                )
            }
            
            Section("应用信息") {
                InfoRow(title: "应用版本", value: "1.0.0")
                InfoRow(title: "构建版本", value: "1")
                InfoRow(title: "Bundle ID", value: "com.example.foundationmodelsdemo")
            }
            
            Section("内存使用") {
                MemoryUsageView()
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(.medium)
        }
    }
}

struct MemoryUsageView: View {
    @State private var memoryUsage: Double = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("内存使用量")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(memoryUsage)) MB")
                    .fontWeight(.medium)
            }
            
            ProgressView(value: memoryUsage / 1024) // 假设最大1GB
                .progressViewStyle(LinearProgressViewStyle(tint: memoryUsage > 512 ? .red : .blue))
        }
        .onAppear {
            updateMemoryUsage()
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                updateMemoryUsage()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func updateMemoryUsage() {
        // 简化的内存使用模拟
        // 在实际应用中，可以使用更复杂的内存监控方法
        memoryUsage = Double.random(in: 100...400)
    }
}

struct PerformanceMonitorView: View {
    @State private var performanceMetrics: [PerformanceMetric] = []
    @State private var isMonitoring = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 监控控制
            HStack {
                Button(isMonitoring ? "停止监控" : "开始监控") {
                    toggleMonitoring()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                if isMonitoring {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("监控中")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            
            // 性能指标
            if !performanceMetrics.isEmpty {
                List(performanceMetrics) { metric in
                    PerformanceMetricRow(metric: metric)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("暂无性能数据")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("点击\"开始监控\"来收集性能数据")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func toggleMonitoring() {
        isMonitoring.toggle()
        
        if isMonitoring {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }
    
    private func startMonitoring() {
        // 模拟性能监控数据
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if !isMonitoring {
                timer.invalidate()
                return
            }
            
            let metric = PerformanceMetric(
                timestamp: Date(),
                cpuUsage: Double.random(in: 10...80),
                memoryUsage: Double.random(in: 100...500),
                responseTime: Double.random(in: 0.1...2.0)
            )
            
            performanceMetrics.append(metric)
            
            // 保持最近50条记录
            if performanceMetrics.count > 50 {
                performanceMetrics.removeFirst()
            }
        }
    }
    
    private func stopMonitoring() {
        // 停止监控逻辑
    }
}

struct PerformanceMetric: Identifiable {
    let id = UUID()
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Double
    let responseTime: Double
}

struct PerformanceMetricRow: View {
    let metric: PerformanceMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(DateFormatter.localizedString(from: metric.timestamp, dateStyle: .none, timeStyle: .medium))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                MetricIndicator(
                    title: "CPU",
                    value: "\(Int(metric.cpuUsage))%",
                    color: metric.cpuUsage > 70 ? .red : .blue
                )
                
                MetricIndicator(
                    title: "内存",
                    value: "\(Int(metric.memoryUsage))MB",
                    color: metric.memoryUsage > 400 ? .red : .green
                )
                
                MetricIndicator(
                    title: "响应",
                    value: String(format: "%.2fs", metric.responseTime),
                    color: metric.responseTime > 1.5 ? .red : .orange
                )
            }
        }
        .padding(.vertical, 4)
    }
}

struct MetricIndicator: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct LogViewerView: View {
    @StateObject private var debugLogger = DebugLogger.shared
    @State private var selectedLogLevel: DebugLogger.LogLevel?
    
    var filteredLogs: [LogEntry] {
        if let level = selectedLogLevel {
            return debugLogger.logEntries.filter { $0.level == level }
        }
        return debugLogger.logEntries
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 过滤器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button("全部") {
                        selectedLogLevel = nil
                    }
                    .buttonStyle(FilterButtonStyle(isSelected: selectedLogLevel == nil))
                    
                    ForEach(DebugLogger.LogLevel.allCases, id: \.self) { level in
                        Button(level.rawValue) {
                            selectedLogLevel = level
                        }
                        .buttonStyle(FilterButtonStyle(isSelected: selectedLogLevel == level))
                    }
                }
                .padding()
            }
            
            Divider()
            
            // 日志列表
            if filteredLogs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("暂无日志")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredLogs.reversed()) { log in
                    LogEntryRow(entry: log)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("清空日志") {
                        debugLogger.clearLogs()
                    }
                    
                    Button("导出日志") {
                        exportLogs()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private func exportLogs() {
        let logText = debugLogger.exportLogs()
        UIPasteboard.general.string = logText
    }
}

struct FilterButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
    }
}

struct LogEntryRow: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.level.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(entry.level.color.opacity(0.2))
                    .foregroundColor(entry.level.color)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(DateFormatter.localizedString(from: entry.timestamp, dateStyle: .none, timeStyle: .medium))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(entry.message)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 2)
    }
}

struct ErrorTrackingView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var testErrors: [ErrorReport] = []
    
    var body: some View {
        VStack(spacing: 16) {
            // 错误统计
            if !testErrors.isEmpty {
                ErrorStatsView(errors: testErrors)
            }
            
            // 测试按钮
            VStack(spacing: 12) {
                Text("错误测试")
                    .font(.headline)
                
                Button("模拟网络错误") {
                    simulateNetworkError()
                }
                .buttonStyle(.bordered)
                
                Button("模拟模型错误") {
                    simulateModelError()
                }
                .buttonStyle(.bordered)
                
                Button("模拟内存错误") {
                    simulateMemoryError()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            // 错误列表
            if !testErrors.isEmpty {
                List(testErrors.reversed()) { error in
                    ErrorReportRow(error: error)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("暂无错误")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("系统运行正常")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func simulateNetworkError() {
        let error = ErrorReport(
            type: .network,
            message: "网络连接超时",
            timestamp: Date(),
            details: "无法连接到服务器，请检查网络连接"
        )
        testErrors.append(error)
        DebugLogger.shared.log("模拟网络错误: \(error.message)", level: .error)
    }
    
    private func simulateModelError() {
        let error = ErrorReport(
            type: .model,
            message: "模型加载失败",
            timestamp: Date(),
            details: "Foundation Models 初始化时发生错误"
        )
        testErrors.append(error)
        DebugLogger.shared.log("模拟模型错误: \(error.message)", level: .error)
    }
    
    private func simulateMemoryError() {
        let error = ErrorReport(
            type: .memory,
            message: "内存不足",
            timestamp: Date(),
            details: "应用内存使用量过高，可能影响性能"
        )
        testErrors.append(error)
        DebugLogger.shared.log("模拟内存错误: \(error.message)", level: .warning)
    }
}

struct ErrorStatsView: View {
    let errors: [ErrorReport]
    
    var errorCounts: [ErrorType: Int] {
        Dictionary(grouping: errors, by: \.type)
            .mapValues { $0.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("错误统计")
                .font(.headline)
            
            HStack(spacing: 16) {
                ForEach(ErrorType.allCases, id: \.self) { type in
                    VStack(spacing: 4) {
                        Text("\(errorCounts[type] ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(type.color)
                        
                        Text(type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ErrorReport: Identifiable {
    let id = UUID()
    let type: ErrorType
    let message: String
    let timestamp: Date
    let details: String
}

enum ErrorType: String, CaseIterable {
    case network = "network"
    case model = "model"
    case memory = "memory"
    
    var displayName: String {
        switch self {
        case .network: return "网络"
        case .model: return "模型"
        case .memory: return "内存"
        }
    }
    
    var color: Color {
        switch self {
        case .network: return .red
        case .model: return .orange
        case .memory: return .purple
        }
    }
}

struct ErrorReportRow: View {
    let error: ErrorReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(error.type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(error.type.color.opacity(0.2))
                    .foregroundColor(error.type.color)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(DateFormatter.localizedString(from: error.timestamp, dateStyle: .short, timeStyle: .short))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(error.message)
                .font(.body)
                .fontWeight(.medium)
            
            Text(error.details)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        DebugToolsView()
            .environmentObject(AIAssistant())
    }
}
