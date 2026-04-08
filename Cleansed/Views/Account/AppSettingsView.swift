import SwiftUI

struct AppSettingsView: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @State private var showTutorial = false
    
    var body: some View {
        List {
            Section {
                Picker(selection: $appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                } label: {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }

                Button {
                    showTutorial = true
                } label: {
                    Label("Tutorial", systemImage: "book.fill")
                }
                .foregroundStyle(Color.primary)

                NavigationLink(destination: WidgetSettingsView()) {
                    Label("Widget", systemImage: "square.stack.3d.up.fill")
                }
            } header: {
                Text("Settings")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showTutorial) {
            TutorialView()
        }
    }
}

#Preview {
    AppSettingsView()
}
