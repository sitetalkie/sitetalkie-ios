import Testing
import Foundation
@testable import bitchat

@MainActor
struct LocationNotesManagerTests {
    @Test func subscribeUsesGeoRelaysAndAppendsNotes() throws {
        var relaysCaptured: [String] = []
        var storedHandler: ((NostrEvent) -> Void)?
        var storedEOSE: (() -> Void)?
        let deps = LocationNotesDependencies(
            relayLookup: { _, _ in ["wss://relay.one"] },
            subscribe: { filter, id, relays, handler, eose in
                #expect(filter.kinds == [1])
                #expect(!id.isEmpty)
                relaysCaptured = relays
                storedHandler = handler
                storedEOSE = eose
            },
            unsubscribe: { _ in },
            sendEvent: { _, _ in },
            deriveIdentity: { _ in throw TestError.shouldNotDerive },
            now: { Date() }
        )

        let manager = LocationNotesManager(geohash: "u4pruydq", dependencies: deps)
        #expect(relaysCaptured == ["wss://relay.one"])
        #expect(manager.state == .loading)

        let identity = try NostrIdentity.generate()
        let event = NostrEvent(
            pubkey: identity.publicKeyHex,
            createdAt: Date(),
            kind: .textNote,
            tags: [["g", "u4pruydq"]],
            content: "hi"
        )
        let signed = try event.sign(with: identity.schnorrSigningKey())
        storedHandler?(signed)
        storedEOSE?()

        #expect(manager.state == .ready)
        #expect(manager.notes.count == 1)
        #expect(manager.notes.first?.content == "hi")
    }

    private enum TestError: Error {
        case shouldNotDerive
    }
}
