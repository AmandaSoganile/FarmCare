import SwiftUI

struct VaccinationRow: View {
    let animal: Animal
    let isMissed: Bool

    var body: some View {
        FarmCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isMissed ? "exclamationmark.triangle" : "calendar")
                    .font(.title3).foregroundStyle(isMissed ? .red : FarmStyle.green)
                    .frame(width: 38, height: 38)
                    .background((isMissed ? Color.red : FarmStyle.green).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 6) {
                    Text(animal.name).font(.headline)
                    Text(animal.vaccinationType).font(.subheadline).foregroundStyle(.secondary)
                    Text(animal.nextVaccinationDate, format: .dateTime.day().month().year())
                        .font(.caption).foregroundStyle(isMissed ? .red : .secondary)
                    AnimalScheduleBadge(animal: animal)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview { VaccinationRow(animal: sampleAnimal, isMissed: false).padding() }
