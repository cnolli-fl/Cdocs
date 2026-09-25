import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct DocumentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let document: KnowledgeDocument?
    let onSave: (KnowledgeDocument) -> Void

    @State private var draft: DocumentDraft
    @State private var initialDraft: DocumentDraft
    @State private var validationErrors: [String] = []
    @State private var showingValidation = false
    @State private var showingCancelConfirmation = false
    @State private var showingFileImporter = false
    @State private var attachmentError: String?

    init(document: KnowledgeDocument?, onSave: @escaping (KnowledgeDocument) -> Void) {
        self.document = document
        self.onSave = onSave
        let value = document.map(DocumentDraft.init(document:)) ?? DocumentDraft()
        _draft = State(initialValue: value)
        _initialDraft = State(initialValue: value)
    }

    private var isDirty: Bool { draft != initialDraft }

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            Divider()

            ScrollView {
                VStack(spacing: 18) {
                    privacyNotice
                    identificationSection
                    diagnosisSection
                    solutionSection
                    contextSection
                    referencesSection
                    attachmentsSection
                }
                .frame(maxWidth: 880)
                .padding(24)
                .frame(maxWidth: .infinity)
            }

            Divider()
            editorFooter
        }
        .frame(minWidth: 820, idealWidth: 940, minHeight: 660, idealHeight: 780)
        .interactiveDismissDisabled(isDirty)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.image, .pdf, .plainText, .json, .commaSeparatedText, .zip],
            allowsMultipleSelection: true,
            onCompletion: importAttachments
        )
        .alert("Revise a documentação", isPresented: $showingValidation) {
            Button("OK") { showingValidation = false }
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
        .alert("Descartar alterações?", isPresented: $showingCancelConfirmation) {
            Button("Descartar", role: .destructive) { dismiss() }
            Button("Continuar editando", role: .cancel) {}
        } message: {
            Text("As alterações feitas nesta documentação não serão salvas.")
        }
        .alert("Não foi possível adicionar o anexo", isPresented: Binding(
            get: { attachmentError != nil },
            set: { if !$0 { attachmentError = nil } }
        )) {
            Button("OK") { attachmentError = nil }
        } message: {
            Text(attachmentError ?? "")
        }
    }

    private var editorHeader: some View {
        HStack(spacing: 14) {
            Image(systemName: document == nil ? "doc.badge.plus" : "pencil.and.outline")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(document == nil ? "Nova documentação" : "Editar documentação")
                    .font(.title2.bold())
                Text("Registre o diagnóstico de forma que outra pessoa consiga repetir a solução.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var privacyNotice: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(.orange)
            Text("Não inclua senhas, tokens, chaves, dados pessoais ou endereços internos confidenciais.")
                .foregroundStyle(.primary)
        }
        .font(.subheadline)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 9))
    }

    private var identificationSection: some View {
        EditorSection(title: "Identificação", symbol: "doc.text") {
            VStack(alignment: .leading, spacing: 14) {
                EditorField("Título do problema", required: true) {
                    TextField("Ex.: VPN conecta, mas sistemas internos não abrem", text: $draft.title)
                }
                EditorField("Resumo", required: true) {
                    TextField("Explique o problema em uma frase", text: $draft.summary, axis: .vertical)
                        .lineLimit(2...4)
                }
                HStack(alignment: .top, spacing: 14) {
                    EditorField("Categoria") {
                        TextField("Ex.: Rede", text: $draft.category)
                    }
                    EditorField("Sistema ou serviço afetado") {
                        TextField("Ex.: macOS / VPN", text: $draft.affectedSystem)
                    }
                }
                HStack(alignment: .top, spacing: 14) {
                    EditorField("Status") {
                        Picker("Status", selection: $draft.status) {
                            ForEach(DocumentStatus.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden()
                    }
                    EditorField("Dificuldade") {
                        Picker("Dificuldade", selection: $draft.difficulty) {
                            ForEach(Difficulty.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden()
                    }
                    EditorField("Data da ocorrência") {
                        DatePicker("Data da ocorrência", selection: $draft.occurrenceDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
            }
        }
    }

    private var diagnosisSection: some View {
        EditorSection(title: "Problema e diagnóstico", symbol: "stethoscope") {
            VStack(alignment: .leading, spacing: 14) {
                EditorTextArea(title: "Descrição detalhada", placeholder: "O que aconteceu? Em que momento?", text: $draft.problemDescription, minHeight: 100)
                EditorTextArea(title: "Sintomas", placeholder: "Liste os sinais observados, um por linha.", text: $draft.symptoms, minHeight: 90)
                EditorTextArea(title: "Mensagens ou códigos de erro", placeholder: "Cole apenas mensagens que não contenham dados confidenciais.", text: $draft.errorMessages, minHeight: 76, monospaced: true)
                EditorTextArea(title: "Causa identificada", placeholder: "Explique a origem confirmada ou a hipótese atual.", text: $draft.cause, minHeight: 90)
            }
        }
    }

    private var solutionSection: some View {
        EditorSection(title: "Resolução", symbol: "checklist") {
            VStack(alignment: .leading, spacing: 14) {
                EditorTextArea(
                    title: "Solução passo a passo",
                    placeholder: "1. Confirme…\n2. Abra…\n3. Execute…\n\nUse ``` para blocos de comandos.",
                    text: $draft.solution,
                    minHeight: 210,
                    monospaced: false
                )
                Text("Aceita Markdown: títulos, listas, negrito e blocos de código.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                EditorTextArea(title: "Como validar", placeholder: "Descreva o teste que confirma a resolução.", text: $draft.validation, minHeight: 90)
                EditorTextArea(title: "Riscos ou cuidados", placeholder: "O que deve ser confirmado antes de executar?", text: $draft.risks, minHeight: 76)
                EditorTextArea(title: "Como desfazer", placeholder: "Descreva o rollback, quando aplicável.", text: $draft.rollback, minHeight: 76)
            }
        }
    }

    private var contextSection: some View {
        EditorSection(title: "Contexto", symbol: "info.circle") {
            VStack(alignment: .leading, spacing: 14) {
                EditorTextArea(title: "Ambiente", placeholder: "Versão, equipamento ou contexto relevante — sem dados confidenciais.", text: $draft.environment, minHeight: 70)
                EditorTextArea(title: "Observações", placeholder: "Decisões, exceções ou informações adicionais.", text: $draft.notes, minHeight: 90)
                HStack(alignment: .top, spacing: 14) {
                    EditorField("Responsável") {
                        TextField("Nome ou equipe", text: $draft.responsible)
                    }
                    EditorField("Tags") {
                        TextField("vpn, rede, dns", text: $draft.tagsText)
                    }
                }
                Toggle("Adicionar aos favoritos", isOn: $draft.isFavorite)
            }
        }
    }

    private var referencesSection: some View {
        EditorSection(title: "Referências", symbol: "link") {
            EditorTextArea(title: "Links úteis", placeholder: "Um endereço por linha, começando com https://", text: $draft.linksText, minHeight: 80)
        }
    }

    private var attachmentsSection: some View {
        EditorSection(title: "Anexos", symbol: "paperclip") {
            VStack(alignment: .leading, spacing: 10) {
                if let document {
                    if document.attachments.isEmpty {
                        Text("Nenhum anexo. Imagens, PDFs, textos, logs, JSON, CSV e ZIP de até 25 MB são aceitos.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(document.attachments) { attachment in
                            HStack {
                                Label(attachment.originalName, systemImage: "doc")
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: attachment.size, countStyle: .file))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button(role: .destructive) { removeAttachment(attachment) } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .help("Remover anexo")
                            }
                        }
                    }
                    Button("Adicionar arquivos…") { showingFileImporter = true }
                        .dropDestination(for: URL.self) { urls, _ in
                            importAttachmentURLs(urls)
                        }
                } else {
                    Label("Salve a documentação antes de adicionar anexos.", systemImage: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var editorFooter: some View {
        HStack {
            Text(isDirty ? "Alterações não salvas" : "Nenhuma alteração pendente")
                .font(.caption)
                .foregroundStyle(isDirty ? .orange : .secondary)
            Spacer()
            Button("Cancelar") {
                if isDirty { showingCancelConfirmation = true } else { dismiss() }
            }
            Button("Salvar como rascunho") {
                draft.status = .draft
                save(allowIncomplete: true)
            }
            Button("Salvar") { save(allowIncomplete: false) }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("s", modifiers: .command)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private func save(allowIncomplete: Bool) {
        validationErrors = DocumentValidationService.errors(for: draft)
        if allowIncomplete {
            validationErrors.removeAll { $0.contains("solução") }
        }
        guard validationErrors.isEmpty else {
            showingValidation = true
            return
        }

        let target: KnowledgeDocument
        if let document {
            target = document
            draft.applying(to: target)
            target.markUpdated("Conteúdo atualizado")
        } else {
            target = KnowledgeDocument()
            draft.applying(to: target)
            target.history.append(DocumentHistory(changeDescription: "Documentação criada", document: target))
            modelContext.insert(target)
        }

        do {
            try modelContext.save()
            initialDraft = draft
            onSave(target)
        } catch {
            validationErrors = ["Não foi possível salvar no banco local: \(error.localizedDescription)"]
            showingValidation = true
        }
    }

    private func importAttachments(_ result: Result<[URL], Error>) {
        do {
            _ = importAttachmentURLs(try result.get())
        } catch {
            attachmentError = error.localizedDescription
        }
    }

    @discardableResult
    private func importAttachmentURLs(_ urls: [URL]) -> Bool {
        guard let document else { return false }
        var importedAttachments: [DocumentAttachment] = []
        do {
            for url in urls {
                let attachment = try AttachmentService.shared.importFile(at: url, for: document)
                document.attachments.append(attachment)
                importedAttachments.append(attachment)
            }
            document.markUpdated(urls.count == 1 ? "Anexo adicionado" : "\(urls.count) anexos adicionados")
            try modelContext.save()
            return true
        } catch {
            modelContext.rollback()
            for attachment in importedAttachments {
                try? AttachmentService.shared.remove(attachment, documentID: document.id)
            }
            attachmentError = error.localizedDescription
            return false
        }
    }

    private func removeAttachment(_ attachment: DocumentAttachment) {
        guard let document else { return }
        let fileURL = AttachmentService.shared.url(for: attachment, documentID: document.id)
        do {
            modelContext.delete(attachment)
            document.markUpdated("Anexo removido")
            try modelContext.save()
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    attachmentError = "O registro do anexo foi removido, mas o arquivo não pôde ser apagado: \(error.localizedDescription)"
                }
            }
        } catch {
            modelContext.rollback()
            attachmentError = error.localizedDescription
        }
    }
}

private struct EditorSection<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        GroupBox {
            content
                .padding(.top, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(title, systemImage: symbol)
                .font(.headline)
        }
    }
}

private struct EditorField<Content: View>: View {
    let title: String
    var required = false
    @ViewBuilder let content: Content

    init(_ title: String, required: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.required = required
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                Text(title).font(.subheadline.weight(.medium))
                if required { Text("*").foregroundStyle(.red) }
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EditorTextArea: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat
    var monospaced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(monospaced ? .system(.body, design: .monospaced) : .body)
                    .scrollContentBackground(.hidden)
                    .padding(2)
            }
            .frame(minHeight: minHeight)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6).stroke(.separator, lineWidth: 1)
            }
        }
    }
}
