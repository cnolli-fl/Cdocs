import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

private struct EditorRoute: Identifiable {
    let id = UUID()
    let document: KnowledgeDocument?
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KnowledgeDocument.updatedAt, order: .reverse) private var documents: [KnowledgeDocument]

    @State private var sidebarSelection: SidebarSelection? = .all
    @State private var selectedDocument: KnowledgeDocument?
    @State private var searchText = ""
    @State private var sort: DocumentSort = .updated
    @State private var statusFilter: DocumentStatus?
    @State private var difficultyFilter: Difficulty?
    @State private var systemFilter = ""
    @State private var editorRoute: EditorRoute?
    @State private var deleteCandidate: KnowledgeDocument?
    @State private var alertMessage: String?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @FocusState private var searchFocused: Bool

    private var filters: DocumentFilters {
        DocumentFilters(
            searchText: searchText,
            sidebar: sidebarSelection ?? .all,
            status: statusFilter,
            difficulty: difficultyFilter,
            affectedSystem: systemFilter,
            sort: sort
        )
    }

    private var filteredDocuments: [KnowledgeDocument] {
        DocumentSearchService.filter(documents, using: filters)
    }

    private var visibleDocumentIDs: [UUID] {
        filteredDocuments.map(\.id)
    }

    private var isShowingMessage: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { newValue in
                if !newValue { alertMessage = nil }
            }
        )
    }

    private var categories: [String] {
        Array(Set(documents.filter { !$0.isTrashed }.map(\.category))).sorted()
    }

    private var tags: [String] {
        Array(Set(documents.filter { !$0.isTrashed }.flatMap(\.tags))).sorted()
    }

    private var systems: [String] {
        Array(Set(documents.filter { !$0.isTrashed && !$0.affectedSystem.isEmpty }.map(\.affectedSystem))).sorted()
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                selection: $sidebarSelection,
                documents: documents,
                categories: categories,
                tags: tags
            )
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
        } content: {
            DocumentListView(
                documents: filteredDocuments,
                selection: $selectedDocument,
                searchText: $searchText,
                sort: $sort,
                statusFilter: $statusFilter,
                difficultyFilter: $difficultyFilter,
                systemFilter: $systemFilter,
                systems: systems,
                searchFocused: $searchFocused,
                onNew: { editorRoute = EditorRoute(document: nil) },
                onClearFilters: clearFilters
            )
            .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 470)
        } detail: {
            if let selectedDocument {
                DocumentDetailView(
                    document: selectedDocument,
                    onEdit: { editorRoute = EditorRoute(document: selectedDocument) },
                    onDuplicate: duplicateSelected,
                    onDelete: { deleteCandidate = selectedDocument },
                    onRestore: restoreSelected,
                    onDeletePermanently: { deleteCandidate = selectedDocument }
                )
                .id(selectedDocument.id)
            } else {
                EmptyDetailView(onNew: { editorRoute = EditorRoute(document: nil) })
            }
        }
        .navigationTitle(navigationTitle)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    editorRoute = EditorRoute(document: nil)
                } label: {
                    Label("Nova documentação", systemImage: "square.and.pencil")
                }
                .help("Nova documentação (⌘N)")

                Menu {
                    Button("Importar documentação JSON…") { importDocument() }
                    Divider()
                    Button("Criar backup…") { exportBackup() }
                    Button("Restaurar backup…") { importBackup() }
                } label: {
                    Label("Dados", systemImage: "externaldrive")
                }
                .help("Backup e restauração")
            }
        }
        .sheet(item: $editorRoute) { route in
            DocumentEditorView(document: route.document) { saved in
                selectedDocument = saved
                editorRoute = nil
            }
        }
        .alert("Confirmar ação", isPresented: Binding(
            get: { deleteCandidate != nil },
            set: { if !$0 { deleteCandidate = nil } }
        ), presenting: deleteCandidate) { document in
            if document.isTrashed {
                Button("Excluir definitivamente", role: .destructive) { permanentlyDelete(document) }
            } else {
                Button("Mover para a Lixeira", role: .destructive) { moveToTrash(document) }
            }
            Button("Cancelar", role: .cancel) { deleteCandidate = nil }
        } message: { document in
            Text(document.isTrashed
                 ? "“\(document.title)” e seus anexos serão apagados e não poderão ser recuperados."
                 : "“\(document.title)” poderá ser restaurado pela Lixeira.")
        }
        .alert("Cdocs", isPresented: isShowingMessage) {
            Button("OK") { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .onChange(of: sidebarSelection) { _, _ in
            selectedDocument = nil
            statusFilter = nil
            difficultyFilter = nil
        }
        .onChange(of: visibleDocumentIDs) { _, visibleIDs in
            if let selectedDocument, !visibleIDs.contains(selectedDocument.id) {
                self.selectedDocument = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newDocument)) { _ in editorRoute = EditorRoute(document: nil) }
        .onReceive(NotificationCenter.default.publisher(for: .editDocument)) { _ in
            if let selectedDocument { editorRoute = EditorRoute(document: selectedDocument) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .duplicateDocument)) { _ in duplicateSelected() }
        .onReceive(NotificationCenter.default.publisher(for: .deleteDocument)) { _ in deleteCandidate = selectedDocument }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in searchFocused = true }
        .onReceive(NotificationCenter.default.publisher(for: .printDocument)) { _ in printSelected() }
        .onReceive(NotificationCenter.default.publisher(for: .exportBackup)) { _ in exportBackup() }
        .onReceive(NotificationCenter.default.publisher(for: .importBackup)) { _ in importBackup() }
    }

    private var navigationTitle: String {
        switch sidebarSelection ?? .all {
        case .all: "Todos os documentos"
        case .recent: "Recentes"
        case .favorites: "Favoritos"
        case .drafts: "Rascunhos"
        case .review: "Em revisão"
        case .obsolete: "Obsoletos"
        case .trash: "Lixeira"
        case .category(let value), .tag(let value): value
        }
    }

    private func clearFilters() {
        searchText = ""
        statusFilter = nil
        difficultyFilter = nil
        systemFilter = ""
    }

    private func duplicateSelected() {
        guard let selectedDocument, !selectedDocument.isTrashed else { return }
        let copy = selectedDocument.makeCopy()
        copy.history.append(DocumentHistory(changeDescription: "Duplicado de “\(selectedDocument.title)”", document: copy))
        modelContext.insert(copy)
        do {
            try modelContext.save()
            self.selectedDocument = copy
        } catch {
            modelContext.rollback()
            alertMessage = "Não foi possível duplicar: \(error.localizedDescription)"
        }
    }

    private func moveToTrash(_ document: KnowledgeDocument) {
        document.isTrashed = true
        document.deletedAt = .now
        document.markUpdated("Movido para a Lixeira")
        do {
            try modelContext.save()
            selectedDocument = nil
        } catch {
            modelContext.rollback()
            alertMessage = "Não foi possível mover para a Lixeira: \(error.localizedDescription)"
        }
        deleteCandidate = nil
    }

    private func restoreSelected() {
        guard let selectedDocument else { return }
        selectedDocument.isTrashed = false
        selectedDocument.deletedAt = nil
        selectedDocument.markUpdated("Restaurado da Lixeira")
        do {
            try modelContext.save()
            sidebarSelection = .all
        } catch {
            modelContext.rollback()
            alertMessage = "Não foi possível restaurar: \(error.localizedDescription)"
        }
    }

    private func permanentlyDelete(_ document: KnowledgeDocument) {
        let documentID = document.id
        do {
            modelContext.delete(document)
            try modelContext.save()
            selectedDocument = nil
            do {
                try AttachmentService.shared.removeFolder(for: documentID)
            } catch {
                alertMessage = "O registro foi excluído, mas alguns anexos não puderam ser removidos: \(error.localizedDescription)"
            }
        } catch {
            modelContext.rollback()
            alertMessage = "Não foi possível excluir: \(error.localizedDescription)"
        }
        deleteCandidate = nil
    }

    private func printSelected() {
        guard let selectedDocument else { return }
        PrintService.print(document: selectedDocument)
    }

    private func exportBackup() {
        do {
            let destination = try BackupService.chooseExportDestination()
            guard let destination else { return }
            try BackupService.export(documents: documents, to: destination)
            alertMessage = "Backup criado em \(destination.lastPathComponent)."
        } catch {
            alertMessage = "Não foi possível criar o backup: \(error.localizedDescription)"
        }
    }

    private func importDocument() {
        let panel = NSOpenPanel()
        panel.title = "Importar documentação"
        panel.prompt = "Importar"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let exported = try DocumentExportService.decoder.decode(ExportedDocument.self, from: Data(contentsOf: url))
            if documents.contains(where: { $0.id == exported.id }) {
                alertMessage = "Esta documentação já existe e não foi substituída."
                return
            }
            let imported = exported.makeDocument()
            imported.history.append(DocumentHistory(changeDescription: "Importado de arquivo JSON", document: imported))
            modelContext.insert(imported)
            try modelContext.save()
            selectedDocument = imported
            sidebarSelection = .all
            alertMessage = "Documentação importada com sucesso."
        } catch {
            alertMessage = "Não foi possível importar o arquivo: \(error.localizedDescription)"
        }
    }

    private func importBackup() {
        do {
            let source = try BackupService.chooseImportSource()
            guard let source else { return }
            let imported = try BackupService.importDocuments(from: source, context: modelContext)
            alertMessage = "\(imported) documentação(ões) importada(s). Registros existentes foram preservados."
        } catch {
            alertMessage = "Não foi possível restaurar o backup: \(error.localizedDescription)"
        }
    }
}
