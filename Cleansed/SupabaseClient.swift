//
//  SupabaseClient.swift
//  Cleansed
//

import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://xdhylpzxesvkgtvbpqsj.supabase.co")!,
    supabaseKey: "sb_publishable_cuVqwRNCvu-z6Vavv4TDNg_yGbbtPo8",
    options: SupabaseClientOptions(
        auth: SupabaseClientOptions.AuthOptions(
            // Fixes: "Initial session emitted after attempting to refresh the local stored session"
            autoRefreshToken: true,
            emitLocalSessionAsInitialSession: true
        )
    )
)
