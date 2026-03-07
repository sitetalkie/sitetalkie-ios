//
// SearchBarView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

/// A search bar component for filtering messages in the chat view
struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.353, green: 0.369, blue: 0.400)) // #5A5E66

            TextField("Search messages...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .focused($isFocused)
                .autocorrectionDisabled(true)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.353, green: 0.369, blue: 0.400)) // #5A5E66
                }
                .buttonStyle(.plain)
            }

            Button(action: {
                searchText = ""
                isSearching = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.353, green: 0.369, blue: 0.400)) // #5A5E66
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(red: 0.102, green: 0.110, blue: 0.125)) // #1A1C20
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.165, green: 0.173, blue: 0.188), lineWidth: 1) // #2A2C30
        )
        .cornerRadius(10)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// A view displaying the search result count
struct SearchResultCountView: View {
    let count: Int

    var body: some View {
        Text("\(count) \(count == 1 ? "result" : "results")")
            .font(.system(size: 13))
            .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
    }
}
