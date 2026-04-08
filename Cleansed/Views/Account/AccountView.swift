import SwiftData
import SwiftUI

struct AccountView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Brand Header
                VStack(spacing: 8) {
                    Image(colorScheme == .dark ? "logo-dark" : "logo-light")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                }
                .padding(.vertical, 20)

                List {
                    NavigationLink(destination: ProfileView().environmentObject(auth)) {
                        Label("Profile", systemImage: "person.circle")
                            .font(.headline)
                            .padding(.vertical, 8)
                    }

                    NavigationLink(destination: AppSettingsView()) {
                        Label("Settings", systemImage: "gearshape")
                            .font(.headline)
                            .padding(.vertical, 8)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .background(Color(.systemBackground))
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(AuthManager())
}
