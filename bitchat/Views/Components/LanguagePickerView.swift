import SwiftUI

#if os(iOS)

struct LanguagePickerView: View {
    @Binding var selectedLanguageCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    // Design system — matches SettingsView
    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071)
    private let cardBackground = Color(red: 0.102, green: 0.110, blue: 0.125)
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)
    private let labelText = Color(red: 0.541, green: 0.557, blue: 0.588)

    /// Common construction-site languages (shown first).
    private static let commonCodes: [String] = [
        "en", "pl", "ro", "pt", "ur", "hi", "bg", "lt",
        "bn", "gu", "pa", "ar", "es", "it", "fr", "de"
    ]

    /// All other languages the device supports (excluding common ones).
    private var allOtherLanguages: [(code: String, native: String, english: String)] {
        let commonSet = Set(Self.commonCodes)
        let availableCodes = Locale.LanguageCode.isoLanguageCodes.map { $0.identifier }
        return availableCodes
            .filter { !commonSet.contains($0) }
            .compactMap { code -> (String, String, String)? in
                let native = Locale(identifier: code).localizedString(forLanguageCode: code)
                let english = Locale(identifier: "en").localizedString(forLanguageCode: code)
                guard let native, let english else { return nil }
                return (code, native.capitalized, english.capitalized)
            }
            .sorted { $0.2 < $1.2 } // sort by English name
    }

    private var commonLanguages: [(code: String, native: String, english: String)] {
        Self.commonCodes.compactMap { code in
            let native = Locale(identifier: code).localizedString(forLanguageCode: code)?.capitalized ?? code
            let english = Locale(identifier: "en").localizedString(forLanguageCode: code)?.capitalized ?? code
            return (code, native, english)
        }
    }

    private func matches(_ lang: (code: String, native: String, english: String)) -> Bool {
        if searchText.isEmpty { return true }
        let q = searchText.lowercased()
        return lang.english.lowercased().contains(q)
            || lang.native.lowercased().contains(q)
            || lang.code.lowercased().contains(q)
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                List {
                    let filteredCommon = commonLanguages.filter { matches($0) }
                    if !filteredCommon.isEmpty {
                        Section("Common") {
                            ForEach(filteredCommon, id: \.code) { lang in
                                languageRow(lang)
                            }
                        }
                        .listRowBackground(cardBackground)
                    }

                    let filteredAll = allOtherLanguages.filter { matches($0) }
                    if !filteredAll.isEmpty {
                        Section("All Languages") {
                            ForEach(filteredAll, id: \.code) { lang in
                                languageRow(lang)
                            }
                        }
                        .listRowBackground(cardBackground)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search languages")
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(amber)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func languageRow(_ lang: (code: String, native: String, english: String)) -> some View {
        Button(action: { selectedLanguageCode = lang.code }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.native)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text(lang.english)
                        .font(.system(size: 13))
                        .foregroundColor(labelText)
                }
                Spacer()
                if selectedLanguageCode == lang.code {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(amber)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#endif
