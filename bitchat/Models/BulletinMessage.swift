import Foundation

struct BulletinMessage {
    let id: Int
    let requiresAck: Bool
    let title: String
    let content: String

    /// Parse a BLE mesh bulletin message.
    /// Format: [BULLETIN:{id}:{ACK|INFO}] {title}\n{content}
    /// Example: [BULLETIN:42:ACK] Safety Notice\nFull content here
    static func parse(from text: String) -> BulletinMessage? {
        guard text.hasPrefix("[BULLETIN:") else { return nil }
        guard let closeBracket = text.firstIndex(of: "]") else { return nil }

        let inside = String(text[text.index(text.startIndex, offsetBy: 10)..<closeBracket])
        let parts = inside.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }

        guard let bulletinId = Int(parts[0]) else { return nil }

        let ackPart = parts[1].uppercased()
        let requiresAck: Bool
        switch ackPart {
        case "ACK": requiresAck = true
        case "INFO": requiresAck = false
        default: return nil
        }

        let afterBracket = String(text[text.index(after: closeBracket)...])
            .trimmingCharacters(in: .init(charactersIn: " "))

        let newlineSplit = afterBracket.split(separator: "\n", maxSplits: 1).map(String.init)
        guard !newlineSplit.isEmpty else { return nil }

        let title = newlineSplit[0].trimmingCharacters(in: .whitespaces)
        let content = newlineSplit.count > 1 ? newlineSplit[1] : ""

        return BulletinMessage(id: bulletinId, requiresAck: requiresAck, title: title, content: content)
    }
}
