import Foundation

/// Centralised translation preferences and in-memory cache.
/// Actual translation happens via SwiftUI's `.translationTask` modifier in views.
class TranslationService {
    static let shared = TranslationService()

    // MARK: - Preferences

    var preferredLanguage: String {
        get {
            UserDefaults.standard.string(forKey: "sitetalkie.preferredLanguage")
                ?? Locale.current.language.languageCode?.identifier
                ?? "en"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "sitetalkie.preferredLanguage")
        }
    }

    var isEnglish: Bool {
        preferredLanguage == "en"
    }

    var autoTranslateChats: Bool {
        get { UserDefaults.standard.bool(forKey: "sitetalkie.autoTranslateChats") }
        set { UserDefaults.standard.set(newValue, forKey: "sitetalkie.autoTranslateChats") }
    }

    /// Whether the Translation framework is available at runtime.
    var isTranslationAvailable: Bool {
        if #available(iOS 18.0, *) { return true }
        return false
    }

    // MARK: - Cache

    /// In-memory translation cache keyed by original text.
    private var cache: [String: String] = [:]
    private let lock = NSLock()

    func cached(_ text: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return cache[text]
    }

    func store(_ original: String, translated: String) {
        lock.lock()
        defer { lock.unlock() }
        cache[original] = translated
    }

    // MARK: - Language identifier mapping

    /// Maps a bare language code to a full language-region identifier
    /// that Apple's Translation framework expects.
    private static let regionMap: [String: String] = [
        "en": "en-GB", "pl": "pl-PL", "ro": "ro-RO", "pt": "pt-PT",
        "hi": "hi-IN", "ur": "ur-PK", "bg": "bg-BG", "lt": "lt-LT",
        "ar": "ar-SA", "es": "es-ES", "fr": "fr-FR", "de": "de-DE",
        "it": "it-IT", "bn": "bn-BD", "gu": "gu-IN", "pa": "pa-IN",
        "zh": "zh-CN", "ja": "ja-JP", "ko": "ko-KR", "tr": "tr-TR",
        "cs": "cs-CZ", "sk": "sk-SK", "hu": "hu-HU", "nl": "nl-NL",
        "cy": "cy-GB", "ga": "ga-IE", "ru": "ru-RU", "uk": "uk-UA",
    ]

    /// Returns a full locale identifier (e.g. "ro-RO") for a bare language code (e.g. "ro").
    /// If already a full identifier or not in the map, returns the input unchanged.
    static func fullLocaleIdentifier(for code: String) -> String {
        if code.contains("-") || code.contains("_") { return code }
        return regionMap[code] ?? code
    }

    // MARK: - Display helpers

    /// Display name for a language code in its own script (e.g. "Polski" for "pl").
    static func nativeDisplayName(for code: String) -> String {
        Locale(identifier: code).localizedString(forLanguageCode: code)?.capitalized ?? code
    }
}
