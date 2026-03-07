import SwiftUI

#if canImport(Translation)
import Translation
#endif

#if os(iOS)

/// Invisible view that triggers translation for a single string.
/// Fires on appear; result delivered via callback.
@available(iOS 18.0, *)
struct AutoTranslateTask: View {
    let text: String
    let onTranslated: (String) -> Void

    @State private var config: TranslationSession.Configuration?

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .translationTask(config) { session in
                do {
                    let response = try await session.translate(text)
                    TranslationService.shared.store(text, translated: response.targetText)
                    await MainActor.run { onTranslated(response.targetText) }
                } catch {
                }
            }
            .onAppear {
                triggerIfNeeded()
            }
    }

    private func triggerIfNeeded() {
        if let cached = TranslationService.shared.cached(text) {
            onTranslated(cached)
        } else {
            let preferred = TranslationService.fullLocaleIdentifier(for: TranslationService.shared.preferredLanguage)
            config = .init(target: Locale.Language(identifier: preferred))
        }
    }
}

/// Invisible view that batch-translates multiple strings from English.
/// Fires on appear; results delivered via callback.
@available(iOS 18.0, *)
struct BatchTranslateTask: View {
    let texts: [String]
    let onComplete: ([String: String]) -> Void

    @State private var config: TranslationSession.Configuration?

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .translationTask(config) { session in
                do {
                    let requests = texts.enumerated().map { i, text in
                        TranslationSession.Request(sourceText: text, clientIdentifier: "\(i)")
                    }
                    let responses = try await session.translations(from: requests)

                    var results: [String: String] = [:]
                    for response in responses {
                        if let idStr = response.clientIdentifier,
                           let idx = Int(idStr), idx < texts.count {
                            let original = texts[idx]
                            results[original] = response.targetText
                            TranslationService.shared.store(original, translated: response.targetText)
                        }
                    }
                    await MainActor.run { onComplete(results) }
                } catch {
                }
            }
            .onAppear {
                triggerIfNeeded()
            }
    }

    private func triggerIfNeeded() {
        var allCached = true
        var cachedResults: [String: String] = [:]
        for text in texts {
            if let cached = TranslationService.shared.cached(text) {
                cachedResults[text] = cached
            } else {
                allCached = false
            }
        }
        if allCached && !cachedResults.isEmpty {
            onComplete(cachedResults)
        } else {
            let preferred = TranslationService.fullLocaleIdentifier(for: TranslationService.shared.preferredLanguage)
            config = .init(
                source: Locale.Language(identifier: "en-GB"),
                target: Locale.Language(identifier: preferred)
            )
        }
    }
}

/// Self-contained chat message translation card.
/// Shows translated text below a chat bubble when auto-translate is ON.
struct ChatMessageTranslation: View {
    let text: String

    @State private var translatedText: String?

    private let tertiaryText = Color(red: 0.353, green: 0.369, blue: 0.400)

    var body: some View {
        if TranslationService.shared.autoTranslateChats,
           TranslationService.shared.isTranslationAvailable,
           !TranslationService.shared.isEnglish {
            VStack(alignment: .leading, spacing: 2) {
                if let translated = translatedText {
                    Text(translated)
                        .font(.bitchatSystem(size: 13))
                        .foregroundColor(Color(red: 0.941, green: 0.941, blue: 0.941))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(red: 0.141, green: 0.149, blue: 0.157))
                        )

                    Text("Translated")
                        .font(.bitchatSystem(size: 9))
                        .foregroundColor(tertiaryText)
                        .padding(.leading, 4)
                }
            }
            .overlay { translateOverlay }
        }
    }

    @ViewBuilder
    private var translateOverlay: some View {
        if #available(iOS 18.0, *), translatedText == nil {
            AutoTranslateTask(text: text) { translated in
                translatedText = translated
            }
        }
    }
}

#endif
