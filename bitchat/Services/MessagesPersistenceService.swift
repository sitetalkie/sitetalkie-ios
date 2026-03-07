//
// MessagesPersistenceService.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import BitLogger
import Foundation
import Combine

/// Manages persistent message storage using Keychain + JSON
@MainActor
final class MessagesPersistenceService: ObservableObject {

    struct ConversationMessages: Codable {
        let conversationKey: String
        var messages: [BitchatMessage]
        let lastUpdated: Date
    }

    private static let storageKey = "com.sitetalkie.app.messages"
    private static let keychainService = "com.sitetalkie.app.messages"
    private let keychain: KeychainManagerProtocol

    @Published private(set) var conversations: [String: ConversationMessages] = [:]

    static let shared = MessagesPersistenceService()

    // Debounced save timer
    private var saveDebounceTimer: Timer?
    private let saveDebounceInterval: TimeInterval = 0.3

    init(keychain: KeychainManagerProtocol = KeychainManager()) {
        self.keychain = keychain
        loadMessages()
    }

    /// Append a new message to a conversation
    func appendMessage(_ message: BitchatMessage, to conversationKey: String) {
        var conversation = conversations[conversationKey] ?? ConversationMessages(
            conversationKey: conversationKey,
            messages: [],
            lastUpdated: Date()
        )

        // Check for duplicate messages
        guard !conversation.messages.contains(where: { $0.id == message.id }) else {
            return
        }

        // Append message
        conversation.messages.append(message)

        conversation = ConversationMessages(
            conversationKey: conversationKey,
            messages: conversation.messages,
            lastUpdated: Date()
        )

        conversations[conversationKey] = conversation
        scheduleSave()
    }

    /// Load messages for a specific conversation
    func loadMessages(for conversationKey: String, limit: Int = 100) -> [BitchatMessage] {
        guard let conversation = conversations[conversationKey] else {
            return []
        }

        return Array(conversation.messages.suffix(limit))
    }

    /// Clear all messages (for panic mode)
    func clearAllMessages() {
        SecureLogger.warning("🧹 Clearing all persisted messages (panic mode)", category: .session)

        conversations.removeAll()
        saveToDisk()

        // Delete from keychain directly
        keychain.delete(
            key: Self.storageKey,
            service: Self.keychainService
        )
    }

    /// Immediately persist to disk (called on app background)
    func persistToDisk() {
        saveDebounceTimer?.invalidate()
        saveToDisk()
    }

    // MARK: - Private Methods

    private func scheduleSave() {
        saveDebounceTimer?.invalidate()
        saveDebounceTimer = Timer.scheduledTimer(withTimeInterval: saveDebounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.saveToDisk()
            }
        }
    }

    private func saveToDisk() {
        let conversationArray = Array(conversations.values)

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(conversationArray)

            // Store in keychain for security
            keychain.save(
                key: Self.storageKey,
                data: data,
                service: Self.keychainService,
                accessible: nil
            )

            SecureLogger.info("💾 Saved \(conversations.count) conversations to storage", category: .session)
        } catch {
            SecureLogger.error("Failed to save messages: \(error)", category: .session)
        }
    }

    private func loadMessages() {
        guard let data = keychain.load(
            key: Self.storageKey,
            service: Self.keychainService
        ) else {
            SecureLogger.info("No persisted messages found (first launch or cleared)", category: .session)
            return
        }

        do {
            let decoder = JSONDecoder()
            let conversationArray = try decoder.decode([ConversationMessages].self, from: data)

            SecureLogger.info("✅ Loaded \(conversationArray.count) conversations from storage", category: .session)

            // Convert to dictionary
            conversations = Dictionary(uniqueKeysWithValues: conversationArray.map { ($0.conversationKey, $0) })
        } catch {
            SecureLogger.error("Failed to load messages: \(error)", category: .session)
        }
    }
}
