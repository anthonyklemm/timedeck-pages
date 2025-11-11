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

// MARK: - Color Extensions

extension Color {
    static let appPrimary = Color(red: 0.0, green: 0.5, blue: 1.0)
    static let appSecondary = Color(red: 1.0, green: 0.2, blue: 0.35)
    static let appBackground = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.1, alpha: 1) : UIColor(white: 0.95, alpha: 1) })
    static let appText = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor.white : UIColor.black })
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.systemGray6))
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
