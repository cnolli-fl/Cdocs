import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DocumentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var document: KnowledgeDocument
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onRestore: () -> Void
    let onDeletePermanently: () -> Void

    @State private var showingHistory = false
    @State private var operationError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if document.isTrashed {
                    Label("Este documento está na Lixeira.", systemImage: "trash")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                }

                if !document.problemDescription.isEmpty {
                    DetailSection(title: "Problema", symbol: "exclamationmark.bubble") {
                        MarkdownBlockView(text: document.problemDescription)
                    }
                }

                if !document.symptoms.isEmpty || !document.errorMessages.isEmpty {
                    DetailSection(title: "Sinais observados", symbol: "waveform.path.ecg") {
                        if !document.symptoms.isEmpty {
                            LabeledBlock(label: "Sintomas", text: document.symptoms)
                        }
                        if !document.errorMessages.isEmpty {
                            LabeledBlock(label: "Mensagens e códigos de erro", text: document.errorMessages, monospaced: true)
                        }
                    }
                }

                if !document.cause.isEmpty {
                    DetailSection(title: "Causa identificada", symbol: "scope") {
                        MarkdownBlockView(text: document.cause)
                    }
                }

                DetailSection(title: "Solução", symbol: "checklist") {
                    MarkdownBlockView(text: document.solution)
                    Button {
                        copy(document.solution)
                    } label: {
                        Label("Copiar solução", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .disabled(document.solution.isEmpty)
                }

                if !document.validation.isEmpty {
                    DetailSection(title: "Como validar", symbol: "checkmark.seal") {
                        MarkdownBlockView(text: document.validation)
                    }
                }

                if !document.risks.isEmpty || !document.rollback.isEmpty {
                    DetailSection(title: "Segurança e reversão", symbol: "arrow.uturn.backward.circle") {
                        if !document.risks.isEmpty {
                            LabeledBlock(label: "Riscos e cuidados", text: document.risks)
                        }
                        if !document.rollback.isEmpty {
                            LabeledBlock(label: "Como desfazer", text: document.rollback)
                        }
                    }
                }

                if !document.notes.isEmpty {
                    DetailSection(title: "Observações", symbol: "note.text") {
                        MarkdownBlockView(text: document.notes)
                    }
                }

                if !document.links.isEmpty {
                    DetailSection(title: "Links úteis", symbol: "link") {
                        ForEach(document.links, id: \.self) { value in
                            if let url = URL(string: value), let scheme = url.scheme, ["http", "https"].contains(scheme) {
                                Link(destination: url) {
                                    Label(value, systemImage: "arrow.up.right.square")
                                }
                            } else {
                                Label(value, systemImage: "link.badge.plus")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !document.attachments.isEmpty {
                    DetailSection(title: "Anexos", symbol: "paperclip") {
                        ForEach(document.attachments.sorted { $0.originalName < $1.originalName }) { attachment in
                            AttachmentRow(attachment: attachment, document: document)
                        }
                    }
                }

                metadata
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(.horizontal, 34)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .toolbar {
            ToolbarItemGroup {
                if document.isTrashed {
                    Button("Restaurar", action: onRestore)
                    Button(role: .destructive, action: onDeletePermanently) {
                        Label("Excluir definitivamente", systemImage: "trash.slash")
                    }
                } else {
                    Button {
                        let previousValue = document.isFavorite
                        document.isFavorite.toggle()
                        document.markUpdated(document.isFavorite ? "Marcado como favorito" : "Removido dos favoritos")
                        do {
                            try modelContext.save()
                        } catch {
                            modelContext.rollback()
                            document.isFavorite = previousValue
                            operationError = "Não foi possível atualizar o favorito: \(error.localizedDescription)"
                        }
                    } label: {
                        Label(document.isFavorite ? "Remover dos favoritos" : "Adicionar aos favoritos", systemImage: document.isFavorite ? "star.fill" : "star")
                    }

                    Button(action: onEdit) {
                        Label("Editar", systemImage: "pencil")
                    }

                    Menu {
                        Button("Duplicar", action: onDuplicate)
                        Button("Exportar como Markdown…") { exportMarkdown() }
                        Button("Exportar como JSON…") { exportJSON() }
                        Button("Imprimir…") { PrintService.print(document: document) }
                        Button("Ver histórico") { showingHistory = true }
                        Divider()
                        Button("Mover para a Lixeira", role: .destructive, action: onDelete)
                    } label: {
                        Label("Mais ações", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(document: document)
        }
        .alert("Não foi possível concluir a ação", isPresented: Binding(
            get: { operationError != nil },
            set: { if !$0 { operationError = nil } }
        )) {
            Button("OK") { operationError = nil }
        } message: {
            Text(operationError ?? "")
        }
        .onAppear {
            if !document.isTrashed {
                document.viewCount += 1
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(document.title)
                        .font(.system(size: 28, weight: .bold))
                        .textSelection(.enabled)
                    Text(document.summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                Spacer(minLength: 12)
                StatusBadge(status: document.status)
            }

            HStack(spacing: 14) {
                Label(document.category, systemImage: "folder")
                if !document.affectedSystem.isEmpty {
                    Label(document.affectedSystem, systemImage: "desktopcomputer")
                }
                Label(document.difficulty.rawValue, systemImage: document.difficulty.symbol)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if !document.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(document.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary, in: Capsule())
                    }
                }
            }
        }
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            HStack {
                Text("Criado em \(document.createdAt.formatted(date: .abbreviated, time: .shortened))")
                Spacer()
                Text("Atualizado em \(document.updatedAt.formatted(date: .abbreviated, time: .shortened))")
            }
            HStack {
                if !document.responsible.isEmpty {
                    Label(document.responsible, systemImage: "person")
                }
                Spacer()
                Label("\(document.viewCount) consultas", systemImage: "eye")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private func exportMarkdown() {
        export(data: Data(DocumentExportService.markdown(for: document).utf8), extension: "md")
    }

    private func exportJSON() {
        do {
            export(data: try DocumentExportService.jsonData(for: document), extension: "json")
        } catch {
            operationError = error.localizedDescription
        }
    }

    private func export(data: Data, extension fileExtension: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(document.title.fileNameSafe).\(fileExtension)"
        panel.allowedContentTypes = fileExtension == "md"
            ? [UTType(filenameExtension: "md") ?? .plainText]
            : [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            operationError = error.localizedDescription
        }
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.title3.weight(.semibold))
            content
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LabeledBlock: View {
    let label: String
    let text: String
    var monospaced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(monospaced ? 12 : 0)
                .background(monospaced ? AnyShapeStyle(.quaternary.opacity(0.7)) : AnyShapeStyle(.clear), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct AttachmentRow: View {
    let attachment: DocumentAttachment
    let document: KnowledgeDocument

    var body: some View {
        Button {
            let url = AttachmentService.shared.url(for: attachment, documentID: document.id)
            NSWorkspace.shared.open(url)
        } label: {
            HStack {
                Image(systemName: "doc")
                VStack(alignment: .leading) {
                    Text(attachment.originalName)
                    Text(ByteCountFormatter.string(fromByteCount: attachment.size, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.forward.app")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .padding(10)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let document: KnowledgeDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Histórico")
                    .font(.title2.bold())
                Spacer()
                Button("Fechar") { dismiss() }
            }
            List(document.history.sorted { $0.changedAt > $1.changedAt }) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.changeDescription)
                    Text(entry.changedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .overlay {
                if document.history.isEmpty {
                    ContentUnavailableView("Sem alterações registradas", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .padding(20)
        .frame(width: 520, height: 420)
    }
}

private struct StatusBadge: View {
    let status: DocumentStatus

    var body: some View {
        Label(status.rawValue, systemImage: status.symbol)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.quaternary, in: Capsule())
    }
}

extension String {
    var fileNameSafe: String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        return components(separatedBy: invalid).joined(separator: "-")
    }
}
