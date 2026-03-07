//
// SetupView.swift
// bitchat
//
// First-launch setup screen for SiteTalkie.
// Shows once before the main chat interface.
//

import SwiftUI

struct SetupView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Binding var hasCompletedSetup: Bool

    @State private var displayName: String = ""
    @State private var showLanguagePicker = false
    @State private var preferredLanguage: String = TranslationService.shared.preferredLanguage
    @FocusState private var isNameFieldFocused: Bool

    // MARK: - Theme

    private let bgColor = Color(red: 0.059, green: 0.059, blue: 0.059)       // #0F0F0F
    private let cardColor = Color(red: 0.102, green: 0.102, blue: 0.102)      // #1A1A1A
    private let accentAmber = Color(red: 0.961, green: 0.620, blue: 0.043)    // #F59E0B
    private let textPrimary = Color(red: 0.961, green: 0.961, blue: 0.941)    // #F5F5F0
    private let textSecondary = Color(red: 0.627, green: 0.627, blue: 0.604)  // #A0A09A
    private let textMuted = Color(red: 0.420, green: 0.420, blue: 0.396)      // #6B6B65

    private var canContinue: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App icon area
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(accentAmber)
                    .padding(.bottom, 24)

                // Title
                Text("SiteTalkie")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)
                    .padding(.bottom, 8)

                // Tagline
                Text("No signal? No problem.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(textSecondary)
                    .padding(.bottom, 48)

                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("What should people call you?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textSecondary)

                    TextField("", text: $displayName, prompt:
                        Text("Your name (e.g. Dave - Sparks)")
                            .foregroundColor(textMuted)
                    )
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(cardColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isNameFieldFocused ? accentAmber : textMuted.opacity(0.3),
                                lineWidth: isNameFieldFocused ? 2 : 1
                            )
                    )
                    .focused($isNameFieldFocused)
                    .textFieldStyle(.plain)
                    .submitLabel(.go)
                    .onSubmit { completeSetup() }
                    #if os(iOS)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.words)
                    #endif
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)

                // Language preference
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your language")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96

                    Button(action: { showLanguagePicker = true }) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.system(size: 18))
                                .foregroundColor(accentAmber)

                            Text(TranslationService.nativeDisplayName(for: preferredLanguage))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(textMuted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(cardColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(textMuted.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)

                // Start button
                Button(action: completeSetup) {
                    Text("Start talking")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(canContinue ? bgColor : textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(canContinue ? accentAmber : cardColor)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canContinue)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)

                // Subtitle
                Text("Works without internet. Messages hop phone-to-phone via Bluetooth.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerView(selectedLanguageCode: $preferredLanguage)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFieldFocused = true
            }
        }
    }

    private func completeSetup() {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.nickname = trimmed
        viewModel.validateAndSaveNickname()
        TranslationService.shared.preferredLanguage = preferredLanguage
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedSetup = true
        }
    }
}
