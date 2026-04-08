//
//  AuthManager.swift
//  Cleansed
//

import Foundation
import OSLog
import Supabase
import SwiftData
import UIKit

private let logger = Logger(subsystem: "com.cleansed", category: "Auth")

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isGuest = false
    @Published var currentUserId: UUID?
    @Published var currentUserEmail: String?

    init() {
        Task { await checkSession() }
    }

    // MARK: - Session

    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            self.isAuthenticated = true
            self.currentUserId = session.user.id
            self.currentUserEmail = session.user.email
        } catch {
            self.isAuthenticated = false
            self.currentUserId = nil
            self.currentUserEmail = nil
        }
    }

    // MARK: - Guest Mode

    func continueAsGuest() {
        isGuest = true
    }

    // MARK: - Auth Actions

    func signInWithGoogle() async throws {
        let url = try await supabase.auth.getOAuthSignInURL(
            provider: .google,
            redirectTo: URL(string: "cleansed://login-callback"),
            queryParams: [("prompt", "select_account")]
        )
        await UIApplication.shared.open(url)
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        self.isAuthenticated = false
        self.isGuest = false
        self.currentUserId = nil
        self.currentUserEmail = nil
    }

    func deleteAccount(context: ModelContext) async throws {
        try await supabase.rpc("delete_my_account").execute()
        DataSyncManager.shared.clearLocalData(context: context)
        self.isAuthenticated = false
        self.isGuest = false
        self.currentUserId = nil
        self.currentUserEmail = nil
    }

    // MARK: - Deep Link

    func handleDeepLink(_ url: URL) async {
        do {
            try await supabase.auth.session(from: url)
            await checkSession()
        } catch {
            logger.error("Deep link auth error: \(error)")
        }
    }
}
