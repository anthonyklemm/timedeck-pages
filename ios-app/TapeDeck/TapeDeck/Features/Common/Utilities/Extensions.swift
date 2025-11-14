import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: self)
    }

    func formattedForPlaylist() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions

extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: self)
    }
}

// MARK: - Number Extensions

extension Double {
    func formatDuration() -> String {
        if self == Int(self) {
            return String(Int(self))
        } else {
            return String(format: "%.1f", self)
        }
    }
}

// MARK: - Color Extensions (Matching TapeDeck Website)

extension Color {
    // Website color scheme
    static let tdBackground = Color(red: 0.04, green: 0.06, blue: 0.09) // #0a0f17
    static let tdCard = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    static let tdPurple = Color(red: 0.55, green: 0.36, blue: 0.96) // #8b5cf6
    static let tdCyan = Color(red: 0.13, green: 0.83, blue: 0.93) // #22d3ee
    static let tdTextPrimary = Color(red: 0.90, green: 0.91, blue: 0.93) // #e5e7eb
    static let tdTextSecondary = Color(red: 0.58, green: 0.64, blue: 0.71) // #94a3b8
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.tdCard)
            .cornerRadius(12)
    }

    func errorBanner(_ message: String?) -> some View {
        VStack {
            if let message = message {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Error")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(message)
                            .font(.caption)
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.systemRed).opacity(0.1))
                .cornerRadius(8)
            }

            self
        }
    }
}

// MARK: - Binding Extensions

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}
