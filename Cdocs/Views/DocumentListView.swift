import SwiftUI

struct DocumentListView: View {
    let documents: [KnowledgeDocument]
    @Binding var selection: KnowledgeDocument?
    @Binding var searchText: String
    @Binding var sort: DocumentSort
    @Binding var statusFilter: DocumentStatus?
    @Binding var difficultyFilter: Difficulty?
    @Binding var systemFilter: String
    let systems: [String]
    var searchFocused: FocusState<Bool>.Binding
    let onNew: () -> Void
    let onClearFilters: () -> Void

    private var hasFilters: Bool {
        !searchText.isEmpty || statusFilter != nil || difficultyFilter != nil || !systemFilter.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            searchAndFilters
            Divider()

            if documents.isEmpty {
                ContentUnavailableView {
                    Label(hasFilters ? "Nenhum resultado" : "Nenhuma documentação", systemImage: hasFilters ? "magnifyingglass" : "doc.text")
                } description: {
                    Text(hasFilters ? "Tente outra busca ou remova os filtros aplicados." : "Registre a primeira solução para encontrá-la quando precisar.")
                } actions: {
                    if hasFilters {
                        Button("Limpar filtros", action: onClearFilters)
                    } else {
                        Button("Nova documentação", action: onNew)
                            .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(documents, selection: $selection) { document in
                    DocumentRow(document: document)
                        .tag(document)
                        .contextMenu {
                            Button("Copiar solução") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(document.solution, forType: .string)
                            }
                        }
                }
                .listStyle(.inset)
            }
        }
    }

    private var searchAndFilters: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Buscar em toda a documentação", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused(searchFocused)
                    .accessibilityLabel("Pesquisar documentação")
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Limpar busca")
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(.quaternary.opacity(0.7), in: RoundedRectangle(cornerRadius: 7))

            HStack {
                Menu {
                    Button("Todos os status") { statusFilter = nil }
                    Divider()
                    ForEach(DocumentStatus.allCases) { status in
                        Button(status.rawValue) { statusFilter = status }
                    }
                } label: {
                    Label(statusFilter?.rawValue ?? "Status", systemImage: "line.3.horizontal.decrease.circle")
                }

                Menu {
                    Button("Todas as dificuldades") { difficultyFilter = nil }
                    Divider()
                    ForEach(Difficulty.allCases) { difficulty in
                        Button(difficulty.rawValue) { difficultyFilter = difficulty }
                    }
                } label: {
                    Text(difficultyFilter?.rawValue ?? "Dificuldade")
                }

                Menu {
                    Button("Todos os sistemas") { systemFilter = "" }
                    if !systems.isEmpty { Divider() }
                    ForEach(systems, id: \.self) { system in
                        Button(system) { systemFilter = system }
                    }
                } label: {
                    Image(systemName: systemFilter.isEmpty ? "desktopcomputer" : "desktopcomputer.and.macbook")
                }
                .help(systemFilter.isEmpty ? "Filtrar por sistema" : "Sistema: \(systemFilter)")

                Spacer()

                Menu {
                    Picker("Ordenar por", selection: $sort) {
                        ForEach(DocumentSort.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .help("Ordenação: \(sort.rawValue)")
            }
            .controlSize(.small)
        }
        .padding(12)
        .background(.background)
    }
}

private struct DocumentRow: View {
    let document: KnowledgeDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(document.title.isEmpty ? "Sem título" : document.title)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 6)
                if document.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Favorito")
                }
            }

            if !document.summary.isEmpty {
                Text(document.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 10) {
                Label(document.category, systemImage: "folder")
                if !document.affectedSystem.isEmpty {
                    Text(document.affectedSystem)
                        .lineLimit(1)
                }
                Spacer()
                Label(document.status.rawValue, systemImage: document.status.symbol)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("Atualizado \(document.updatedAt.formatted(.relative(presentation: .named)))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
    }
}
