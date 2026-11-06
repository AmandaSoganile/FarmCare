import SwiftUI
import UIKit

// Shared, system-adaptive styling keeps the original green FarmCare identity.
enum FarmStyle {
    static let green = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.49, green: 0.81, blue: 0.63, alpha: 1)
            : UIColor(red: 0.09, green: 0.35, blue: 0.24, alpha: 1)
    })
    static let buttonFill = Color(red: 0.09, green: 0.35, blue: 0.24)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
}

struct FarmCard<Content: View>: View {
    private let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FarmStyle.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct FarmPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 12)
            .foregroundStyle(.white)
            .background(FarmStyle.buttonFill, in: RoundedRectangle(cornerRadius: 14))
            .opacity(!isEnabled ? 0.45 : (configuration.isPressed ? 0.8 : 1))
    }
}

struct AnimalScheduleBadge: View {
    let animal: Animal
    private var title: String {
        animal.isVaccinationMissed ? "Overdue" : (animal.isVaccinationDueSoon ? "Due soon" : "Scheduled")
    }
    private var color: Color {
        animal.isVaccinationMissed ? .red : (animal.isVaccinationDueSoon ? .orange : FarmStyle.green)
    }
    var body: some View {
        Label(title, systemImage: animal.isVaccinationMissed ? "exclamationmark.circle" : "calendar")
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(color.opacity(0.1), in: Capsule())
            .accessibilityLabel("Vaccination schedule: \(title)")
    }
}
