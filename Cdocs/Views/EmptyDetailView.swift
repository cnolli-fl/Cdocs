import SwiftUI

struct EmptyDetailView: View {
    let onNew: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Sua solução, quando precisar", systemImage: "wrench.and.screwdriver")
        } description: {
            Text("Selecione uma documentação na lista ou registre um novo procedimento.")
        } actions: {
            Button("Nova documentação", action: onNew)
                .buttonStyle(.borderedProminent)
        }
    }
}
