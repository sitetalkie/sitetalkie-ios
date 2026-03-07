//
// PinGeofenceBannerView.swift
// bitchat
//
// Banner shown at the top of the screen when the user enters a pin's geofence area.
//

import SwiftUI

#if os(iOS)

struct PinGeofenceBannerView: View {
    let pin: SitePin
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: pin.type.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pin.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("Tap to view")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(pin.type.color)
            )
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#endif
