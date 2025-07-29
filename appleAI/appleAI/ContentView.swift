import SwiftUI

struct ContentView: View {
    @State private var showTestView = false

    var body: some View {
        NavigationView {
            VStack {
                // 添加一个切换按钮用于测试
                HStack {
                    Button(showTestView ? "显示完整功能" : "显示测试视图") {
                        showTestView.toggle()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()

                if showTestView {
                    LaunchTestView()
                } else {
                    FeatureListView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
