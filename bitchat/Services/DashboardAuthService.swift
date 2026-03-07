//
// DashboardAuthService.swift
// bitchat
//
// Handles "Sign in with SiteTalkie Dashboard" deep link authentication.
// Signs a Nostr event (kind 27235) with the device's mesh identity
// and POSTs to the Supabase edge function for verification.
//

import Foundation
import BitLogger

#if os(iOS)

enum DashboardAuthError: Error, LocalizedError {
    case noIdentity
    case signingFailed
    case networkError(String)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .noIdentity: return "No mesh identity found."
        case .signingFailed: return "Failed to sign challenge."
        case .networkError(let msg): return msg
        case .serverError(let msg): return msg
        }
    }
}

struct DashboardAuthService {
    private static let verifyURL = "https://gwolhiudnwacaqvpgmca.supabase.co/functions/v1/nip46-verify"

    /// Sign the challenge and POST to the dashboard verify endpoint.
    static func signInToDashboard(
        sessionId: String,
        challenge: String,
        idBridge: NostrIdentityBridge
    ) async throws {
        // 1. Get existing Nostr identity
        guard let identity = try idBridge.getCurrentNostrIdentity() else {
            throw DashboardAuthError.noIdentity
        }

        // 2. Create and sign a kind 27235 event with the challenge as content
        let event = NostrEvent(
            pubkey: identity.publicKeyHex,
            createdAt: Date(),
            kind: .httpAuth,
            tags: [],
            content: challenge
        )

        let signedEvent: NostrEvent
        do {
            signedEvent = try event.sign(with: identity.schnorrSigningKey())
        } catch {
            throw DashboardAuthError.signingFailed
        }

        // 3. Convert signed event to a dictionary for nested embedding
        let signedEventDict: [String: Any] = [
            "id": signedEvent.id,
            "pubkey": signedEvent.pubkey,
            "created_at": signedEvent.created_at,
            "kind": signedEvent.kind,
            "tags": signedEvent.tags,
            "content": signedEvent.content,
            "sig": signedEvent.sig ?? ""
        ]

        // 4. Build request body with signedEvent as a nested object
        let body: [String: Any] = [
            "sessionId": sessionId,
            "npub": identity.npub,
            "signedEvent": signedEventDict,
            "challenge": challenge
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: body)

        // 5. POST to Supabase edge function
        guard let url = URL(string: verifyURL) else {
            throw DashboardAuthError.networkError("Invalid verify URL.")
        }

        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3b2xoaXVkbndhY2FxdnBnbWNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0ODMwMzUsImV4cCI6MjA4ODA1OTAzNX0.YYWMzTMVOVK_Yn0rVdZkdnPbq32_PzXM3oeq3wwg9SE"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = jsonData
        request.timeoutInterval = 15

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw DashboardAuthError.networkError("Network request failed: \(error.localizedDescription)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DashboardAuthError.networkError("Invalid response.")
        }

        // 6. Parse response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let success = json["success"] as? Bool, success {
            SecureLogger.info("Dashboard auth succeeded for session \(sessionId)", category: .session)
            return
        }

        let errorMsg: String
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let msg = json["error"] as? String {
            errorMsg = msg
        } else {
            errorMsg = "Server returned status \(httpResponse.statusCode)."
        }
        throw DashboardAuthError.serverError(errorMsg)
    }
}

#endif
