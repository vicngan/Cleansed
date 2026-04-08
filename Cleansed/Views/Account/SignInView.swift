import SwiftData
import SwiftUI

struct SignInView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query private var localTodos: [TodoItem]
    @Query private var localHabits: [Habit]

    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Logo
            Image(colorScheme == .dark ? "logo-dark" : "logo-light")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .padding(.bottom, 10)

            Text("Welcome to Cleansed")
                .font(.title2.bold())
                .textCase(.lowercase)

            // Error message
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            // Google sign-in
            Button(action: { Task { await signInWithGoogle() } }) {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Image("google-logo")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Continue with Google")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .foregroundColor(Color(.label))
                .cornerRadius(30)
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.gray.opacity(0.4), lineWidth: 1))
            }
            .disabled(isLoading)

            // Guest mode
            Button("Continue as Guest") {
                auth.continueAsGuest()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.top, 4)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        let wasGuest = auth.isGuest
        let todosToMigrate = wasGuest ? localTodos : []
        let habitsToMigrate = wasGuest ? localHabits : []

        do {
            try await auth.signInWithGoogle()
            // Session completion is handled via deep link (onOpenURL → handleDeepLink)
            // Migration runs after the deep link resolves and isAuthenticated flips
            if wasGuest, let userId = auth.currentUserId {
                await DataSyncManager.shared.migrateGuestData(
                    userId: userId,
                    localTodos: todosToMigrate,
                    localHabits: habitsToMigrate,
                    context: modelContext
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        SignInView()
            .environmentObject(AuthManager())
    }
}
