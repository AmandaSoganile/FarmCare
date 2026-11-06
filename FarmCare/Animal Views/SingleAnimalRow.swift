import SwiftUI

struct SingleAnimalRow: View {
    let animal: Animal
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(animal.species.imageResource).resizable().scaledToFit()
                .frame(width: 50, height: 50).padding(8)
                .background(FarmStyle.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 6) {
                Text(animal.name).font(.headline)
                Text(animal.breed).font(.subheadline).foregroundStyle(.secondary)
                AnimalScheduleBadge(animal: animal)
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview { SingleAnimalRow(animal: sampleAnimal).padding() }
