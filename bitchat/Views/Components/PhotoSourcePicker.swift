//
// PhotoSourcePicker.swift
// bitchat
//
// Custom action-sheet-style overlay for choosing photo source.
// Used instead of .confirmationDialog inside sheets (which is unreliable on iOS).
//

import SwiftUI

#if os(iOS)
struct PhotoSourcePicker: View {
    let onTakePhoto: () -> Void
    let onChooseFromLibrary: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var pickerBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.15, green: 0.15, blue: 0.16)
            : Color(UIColor.secondarySystemGroupedBackground)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 8) {
                VStack(spacing: 0) {
                    Text("Choose Photo Source")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)

                    Divider()

                    Button(action: onTakePhoto) {
                        Text("Take Photo")
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }

                    Divider()

                    Button(action: onChooseFromLibrary) {
                        Text("Choose from Library")
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(pickerBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(pickerBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
}
#endif
