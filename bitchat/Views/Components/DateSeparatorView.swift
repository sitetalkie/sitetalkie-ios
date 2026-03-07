//
// DateSeparatorView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

struct DateSeparatorView: View {
    let date: Date

    private var displayText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "E dd MMM"  // e.g., "Mon 16 Feb"
            return formatter.string(from: date)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(red: 0.353, green: 0.369, blue: 0.400)) // #5A5E66

            Text(displayText)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.353, green: 0.369, blue: 0.400))

            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(red: 0.353, green: 0.369, blue: 0.400))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

extension Date {
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

#Preview {
    VStack(spacing: 0) {
        DateSeparatorView(date: Date())
        DateSeparatorView(date: Date().addingTimeInterval(-86400))  // Yesterday
        DateSeparatorView(date: Date().addingTimeInterval(-86400 * 7))  // Week ago
    }
    .preferredColorScheme(.dark)
}
