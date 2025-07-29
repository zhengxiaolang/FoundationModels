import SwiftUI

struct SmartNotesView: View {
    @EnvironmentObject var assistant: AIAssistant
    @State private var notes: [Note] = []
    @State private var selectedNote: Note?
    @State private var showingNewNote = false
    @State private var searchText = ""
    
    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notes.sorted { $0.updatedAt > $1.updatedAt }
        } else {
            return notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // 笔记列表
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                
                if filteredNotes.isEmpty {
                    EmptyNotesView(showingNewNote: $showingNewNote)
                } else {
                    List(filteredNotes, selection: $selectedNote) { note in
                        NoteRowView(note: note)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("删除", role: .destructive) {
                                    deleteNote(note)
                                }
                            }
                    }
                }
            }
            .navigationTitle("智能笔记")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新建") {
                        showingNewNote = true
                    }
                }
            }
        } detail: {
            if let note = selectedNote {
                NoteDetailView(
                    note: binding(for: note),
                    onUpdate: updateNote
                )
                .environmentObject(assistant)
            } else {
                NoteEmptyDetailView()
            }
        }
        .sheet(isPresented: $showingNewNote) {
            NewNoteView { newNote in
                notes.append(newNote)
                selectedNote = newNote
            }
            .environmentObject(assistant)
        }
        .onAppear {
            loadSampleNotes()
        }
    }
    
    private func binding(for note: Note) -> Binding<Note> {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else {
            fatalError("Note not found")
        }
        return $notes[index]
    }
    
    private func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
    }
    
    private func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        if selectedNote?.id == note.id {
            selectedNote = nil
        }
    }
    
    private func loadSampleNotes() {
        if notes.isEmpty {
            notes = [
                Note(
                    title: "AI 学习笔记",
                    content: "人工智能是计算机科学的一个分支，它试图理解智能的实质，并生产出一种新的能以人类智能相似的方式做出反应的智能机器。机器学习是实现人工智能的一种方法，通过算法使机器能够从数据中学习并做出决策。"
                ),
                Note(
                    title: "项目会议记录",
                    content: "今天的项目会议讨论了以下几个重点：1. 项目进度符合预期，目前完成度为70%；2. 需要加强团队协作，提高沟通效率；3. 下周将进行用户测试，收集反馈意见；4. 预计项目将在下个月底完成。"
                )
            ]
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索笔记...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("清除") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
}

struct EmptyNotesView: View {
    @Binding var showingNewNote: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("还没有笔记")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("创建您的第一个智能笔记")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("新建笔记") {
                showingNewNote = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(DateFormatter.localizedString(from: note.updatedAt, dateStyle: .short, timeStyle: .none))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(note.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if let summary = note.summary {
                Text("摘要: \(summary)")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
            
            HStack {
                if let sentiment = note.sentiment {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(sentiment.color)
                            .frame(width: 8, height: 8)
                        
                        Text(sentiment.displayName)
                            .font(.caption2)
                            .foregroundColor(sentiment.color)
                    }
                }
                
                if !note.keywords.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        
                        Text("\(note.keywords.count)个关键词")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

struct NoteEmptyDetailView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("选择一个笔记")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("从左侧列表中选择一个笔记来查看和编辑")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NoteDetailView: View {
    @Binding var note: Note
    let onUpdate: (Note) -> Void
    @EnvironmentObject var assistant: AIAssistant
    @State private var isAnalyzing = false
    @State private var showingAITools = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 编辑区域
            ScrollView {
                VStack(spacing: 16) {
                    // 标题编辑
                    TextField("笔记标题", text: $note.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // 内容编辑
                    TextEditor(text: $note.content)
                        .font(.body)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    // AI 分析结果
                    AIAnalysisSection(note: note)
                }
                .padding()
            }
            
            Divider()
            
            // AI 工具栏
            AIToolsBar(
                note: $note,
                isAnalyzing: $isAnalyzing,
                onUpdate: onUpdate
            )
        }
        .navigationTitle("笔记详情")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: note.title) { _ in
            note.updatedAt = Date()
            onUpdate(note)
        }
        .onChange(of: note.content) { _ in
            note.updatedAt = Date()
            onUpdate(note)
        }
    }
}

struct AIAnalysisSection: View {
    let note: Note
    
    var body: some View {
        VStack(spacing: 12) {
            if let summary = note.summary {
                AnalysisCard(
                    title: "AI 摘要",
                    content: summary,
                    color: .blue,
                    icon: "doc.text"
                )
            }
            
            if let sentiment = note.sentiment {
                AnalysisCard(
                    title: "情感分析",
                    content: "\(sentiment.icon) \(sentiment.displayName)",
                    color: sentiment.color,
                    icon: "heart"
                )
            }
            
            if !note.keywords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(.orange)
                        Text("关键词")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                        ForEach(note.keywords, id: \.self) { keyword in
                            Text(keyword)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

struct AnalysisCard: View {
    let title: String
    let content: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            Text(content)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AIToolsBar: View {
    @Binding var note: Note
    @Binding var isAnalyzing: Bool
    let onUpdate: (Note) -> Void
    @EnvironmentObject var assistant: AIAssistant
    
    var body: some View {
        HStack(spacing: 16) {
            Button("生成摘要") {
                generateSummary()
            }
            .disabled(isAnalyzing || note.content.isEmpty)
            
            Button("分析情感") {
                analyzeSentiment()
            }
            .disabled(isAnalyzing || note.content.isEmpty)
            
            Button("提取关键词") {
                extractKeywords()
            }
            .disabled(isAnalyzing || note.content.isEmpty)
            
            if isAnalyzing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func generateSummary() {
        isAnalyzing = true
        Task {
            if let summary = await assistant.summarizeText(note.content) {
                await MainActor.run {
                    note.summary = summary
                    note.updatedAt = Date()
                    onUpdate(note)
                    isAnalyzing = false
                }
            } else {
                await MainActor.run {
                    isAnalyzing = false
                }
            }
        }
    }
    
    private func analyzeSentiment() {
        isAnalyzing = true
        Task {
            if let result = await assistant.analyzeSentiment(text: note.content) {
                await MainActor.run {
                    note.sentiment = result.sentiment
                    note.updatedAt = Date()
                    onUpdate(note)
                    isAnalyzing = false
                }
            } else {
                await MainActor.run {
                    isAnalyzing = false
                }
            }
        }
    }
    
    private func extractKeywords() {
        isAnalyzing = true
        Task {
            if let keywords = await assistant.extractKeywords(from: note.content) {
                await MainActor.run {
                    note.keywords = keywords
                    note.updatedAt = Date()
                    onUpdate(note)
                    isAnalyzing = false
                }
            } else {
                await MainActor.run {
                    isAnalyzing = false
                }
            }
        }
    }
}

struct NewNoteView: View {
    let onSave: (Note) -> Void
    @State private var title = ""
    @State private var content = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("笔记标题", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                
                TextEditor(text: $content)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("新建笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let note = Note(title: title.isEmpty ? "无标题" : title, content: content)
                        onSave(note)
                        dismiss()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SmartNotesView()
            .environmentObject(AIAssistant())
    }
}
