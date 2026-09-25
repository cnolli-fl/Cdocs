import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSelection?
    let documents: [KnowledgeDocument]
    let categories: [String]
    let tags: [String]

    var body: some View {
        List(selection: $selection) {
            Section("Biblioteca") {
                sidebarItem("Todos os documentos", symbol: "books.vertical", value: .all, count: count { !$0.isTrashed })
                sidebarItem("Recentes", symbol: "clock", value: .recent)
                sidebarItem("Favoritos", symbol: "star", value: .favorites, count: count { !$0.isTrashed && $0.isFavorite })
            }

            Section("Situação") {
                sidebarItem("Rascunhos", symbol: "pencil.circle", value: .drafts, count: count { !$0.isTrashed && $0.status == .draft })
                sidebarItem("Em revisão", symbol: "eye.circle", value: .review, count: count { !$0.isTrashed && $0.status == .review })
                sidebarItem("Obsoletos", symbol: "archivebox", value: .obsolete, count: count { !$0.isTrashed && $0.status == .obsolete })
            }

            if !categories.isEmpty {
                Section("Categorias") {
                    ForEach(categories, id: \.self) { category in
                        sidebarItem(category, symbol: "folder", value: .category(category))
                    }
                }
            }

            if !tags.isEmpty {
                Section("Tags") {
                    ForEach(tags.prefix(12), id: \.self) { tag in
                        sidebarItem(tag, symbol: "tag", value: .tag(tag))
                    }
                }
            }

            Section {
                sidebarItem("Lixeira", symbol: "trash", value: .trash, count: count { $0.isTrashed })
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 8) {
                Image(systemName: "lock.laptopcomputer")
                Text("Dados somente neste Mac")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(.bar)
        }
    }

    @ViewBuilder
    private func sidebarItem(_ title: String, symbol: String, value: SidebarSelection, count: Int? = nil) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            if let count, count > 0 {
                Text(count, format: .number)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .tag(value)
        .accessibilityLabel(count.map { "\(title), \($0) itens" } ?? title)
    }

    private func count(where predicate: (KnowledgeDocument) -> Bool) -> Int {
        documents.filter(predicate).count
    }
}
