import SwiftData
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.modelContext) private var modelContext

    @State private var showDeleteAlert = false
    @State private var isDeletingAccount = false
    @State private var deleteError: String?

    var body: some View {
        List {
            Section {
                if auth.isAuthenticated {
                    if let email = auth.currentUserEmail {
                        Label(email, systemImage: "person.circle.fill")
                            .foregroundStyle(Color.primary)
                    }

                    Button(role: .destructive) {
                        Task {
                            DataSyncManager.shared.clearLocalData(context: modelContext)
                            try? await auth.signOut()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "arrow.backward.circle")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        if isDeletingAccount {
                            HStack {
                                ProgressView()
                                Text("Deleting…")
                            }
                        } else {
                            Label("Delete Account", systemImage: "trash.fill")
                        }
                    }
                    .disabled(isDeletingAccount)
                } else if auth.isGuest {
                    Label("Guest", systemImage: "person.circle")
                        .foregroundStyle(Color.secondary)
                    NavigationLink(destination: SignInView().environmentObject(auth)) {
                        Label("Create Account or Sign In", systemImage: "arrow.right.circle")
                            .foregroundStyle(Color.primary)
                    }
                } else {
                    NavigationLink(destination: SignInView().environmentObject(auth)) {
                        Label("Sign in", systemImage: "person.circle")
                            .foregroundStyle(Color.primary)
                    }
                }
            } header: {
                Text("Account Management")
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task { await performDeleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all your data. This cannot be undone.")
        }
        .alert("Error", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteError ?? "")
        }
    }

    private func performDeleteAccount() async {
        isDeletingAccount = true
        do {
            try await auth.deleteAccount(context: modelContext)
        } catch {
            isDeletingAccount = false
            deleteError = error.localizedDescription
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
