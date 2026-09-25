import AppKit
import Foundation
import SwiftData
import UniformTypeIdentifiers

struct DocumentFilters {
    var searchText = ""
    var sidebar: SidebarSelection = .all
    var status: DocumentStatus?
    var difficulty: Difficulty?
    var affectedSystem = ""
    var sort: DocumentSort = .updated
}

enum DocumentSearchService {
    static func filter(_ documents: [KnowledgeDocument], using filters: DocumentFilters, now: Date = .now) -> [KnowledgeDocument] {
        let query = filters.searchText
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let recentLimit = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now

        return documents.filter { document in
            let sidebarMatches: Bool = switch filters.sidebar {
            case .all: !document.isTrashed
            case .recent: !document.isTrashed && document.updatedAt >= recentLimit
            case .favorites: !document.isTrashed && document.isFavorite
            case .drafts: !document.isTrashed && document.status == .draft
            case .review: !document.isTrashed && document.status == .review
            case .obsolete: !document.isTrashed && document.status == .obsolete
            case .trash: document.isTrashed
            case .category(let category): !document.isTrashed && document.category == category
            case .tag(let tag): !document.isTrashed && document.tags.contains { $0.localizedCaseInsensitiveCompare(tag) == .orderedSame }
            }
            let queryMatches = query.isEmpty || document.searchableText.contains(query)
            let statusMatches = filters.status == nil || document.status == filters.status
            let difficultyMatches = filters.difficulty == nil || document.difficulty == filters.difficulty
            let systemMatches = filters.affectedSystem.isEmpty || document.affectedSystem.localizedCaseInsensitiveContains(filters.affectedSystem)
            return sidebarMatches && queryMatches && statusMatches && difficultyMatches && systemMatches
        }
        .sorted { lhs, rhs in
            switch filters.sort {
            case .updated: lhs.updatedAt > rhs.updatedAt
            case .created: lhs.createdAt > rhs.createdAt
            case .title: lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            case .views: lhs.viewCount > rhs.viewCount
            }
        }
    }
}

enum DocumentValidationService {
    static func errors(for draft: DocumentDraft) -> [String] {
        var errors: [String] = []
        if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Informe um título para o problema.")
        }
        if draft.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Escreva um resumo curto.")
        }
        if draft.solution.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Descreva a solução ou salve como rascunho.")
        }
        return errors
    }
}

enum AttachmentError: LocalizedError {
    case fileTooLarge
    case unsupportedType
    case cannotRead

    var errorDescription: String? {
        switch self {
        case .fileTooLarge: "O arquivo excede o limite de 25 MB."
        case .unsupportedType: "Este tipo de arquivo não é permitido."
        case .cannotRead: "Não foi possível ler ou copiar o arquivo."
        }
    }
}

@MainActor
final class AttachmentService {
    static let shared = AttachmentService()
    static let maximumSize: Int64 = 25 * 1_024 * 1_024

    private let allowedExtensions = Set(["png", "jpg", "jpeg", "heic", "gif", "pdf", "txt", "md", "log", "json", "csv", "zip"])

    var rootURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appending(path: "Cdocs/Attachments", directoryHint: .isDirectory)
    }

    func importFile(at source: URL, for document: KnowledgeDocument) throws -> DocumentAttachment {
        let didAccess = source.startAccessingSecurityScopedResource()
        defer { if didAccess { source.stopAccessingSecurityScopedResource() } }

        let values = try source.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true else { throw AttachmentError.cannotRead }
        let size = Int64(values.fileSize ?? 0)
        guard size <= Self.maximumSize else { throw AttachmentError.fileTooLarge }

        let ext = source.pathExtension.lowercased()
        guard allowedExtensions.contains(ext) else { throw AttachmentError.unsupportedType }

        let folder = rootURL.appending(path: document.id.uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let storedName = "\(UUID().uuidString).\(ext)"
        let destination = folder.appending(path: storedName)
        do {
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            throw AttachmentError.cannotRead
        }
        return DocumentAttachment(
            originalName: source.lastPathComponent,
            storedName: storedName,
            fileExtension: ext,
            size: size,
            document: document
        )
    }

    func url(for attachment: DocumentAttachment, documentID: UUID) -> URL {
        rootURL.appending(path: documentID.uuidString, directoryHint: .isDirectory)
            .appending(path: attachment.storedName)
    }

    func remove(_ attachment: DocumentAttachment, documentID: UUID) throws {
        let url = url(for: attachment, documentID: documentID)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    func removeFolder(for documentID: UUID) throws {
        let folder = rootURL.appending(path: documentID.uuidString, directoryHint: .isDirectory)
        if FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.removeItem(at: folder)
        }
    }

    func restoreFile(
        from source: URL,
        originalName: String,
        storedName: String,
        size: Int64,
        for document: KnowledgeDocument
    ) throws -> DocumentAttachment {
        guard isSafeStoredName(storedName) else { throw AttachmentError.unsupportedType }
        guard size >= 0, size <= Self.maximumSize else { throw AttachmentError.fileTooLarge }
        let values = try source.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true else { throw AttachmentError.cannotRead }
        let actualSize = Int64(values.fileSize ?? 0)
        guard actualSize <= Self.maximumSize, actualSize == size else { throw AttachmentError.cannotRead }

        let folder = rootURL.appending(path: document.id.uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = folder.appending(path: storedName)
        guard !FileManager.default.fileExists(atPath: destination.path) else {
            return DocumentAttachment(
                originalName: originalName,
                storedName: storedName,
                fileExtension: destination.pathExtension,
                size: size,
                document: document
            )
        }
        try FileManager.default.copyItem(at: source, to: destination)
        return DocumentAttachment(
            originalName: originalName,
            storedName: storedName,
            fileExtension: destination.pathExtension,
            size: size,
            document: document
        )
    }

    func isSafeStoredName(_ value: String) -> Bool {
        let ext = URL(fileURLWithPath: value).pathExtension.lowercased()
        return !value.isEmpty
            && value == (value as NSString).lastPathComponent
            && !value.contains("..")
            && allowedExtensions.contains(ext)
    }
}

struct ExportedDocument: Codable, Equatable {
    var id: UUID
    var title: String
    var summary: String
    var problemDescription: String
    var symptoms: String
    var affectedSystem: String
    var errorMessages: String
    var environment: String
    var cause: String
    var solution: String
    var validation: String
    var risks: String
    var rollback: String
    var notes: String
    var category: String
    var tags: [String]
    var links: [String]
    var occurrenceDate: Date
    var createdAt: Date
    var updatedAt: Date
    var responsible: String
    var difficulty: Difficulty
    var status: DocumentStatus
    var isFavorite: Bool
    var viewCount: Int
    var isDeleted: Bool
    var deletedAt: Date?

    init(document: KnowledgeDocument) {
        id = document.id
        title = document.title
        summary = document.summary
        problemDescription = document.problemDescription
        symptoms = document.symptoms
        affectedSystem = document.affectedSystem
        errorMessages = document.errorMessages
        environment = document.environment
        cause = document.cause
        solution = document.solution
        validation = document.validation
        risks = document.risks
        rollback = document.rollback
        notes = document.notes
        category = document.category
        tags = document.tags
        links = document.links
        occurrenceDate = document.occurrenceDate
        createdAt = document.createdAt
        updatedAt = document.updatedAt
        responsible = document.responsible
        difficulty = document.difficulty
        status = document.status
        isFavorite = document.isFavorite
        viewCount = document.viewCount
        isDeleted = document.isTrashed
        deletedAt = document.deletedAt
    }

    func makeDocument() -> KnowledgeDocument {
        KnowledgeDocument(
            id: id, title: title, summary: summary, problemDescription: problemDescription,
            symptoms: symptoms, affectedSystem: affectedSystem, errorMessages: errorMessages,
            environment: environment, cause: cause, solution: solution, validation: validation,
            risks: risks, rollback: rollback, notes: notes, category: category,
            tagsText: tags.joined(separator: ", "), linksText: links.joined(separator: "\n"),
            occurrenceDate: occurrenceDate, createdAt: createdAt, updatedAt: updatedAt,
            responsible: responsible, difficulty: difficulty, status: status,
            isFavorite: isFavorite, viewCount: viewCount,
            isTrashed: isDeleted, deletedAt: deletedAt
        )
    }
}

enum DocumentExportService {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func jsonData(for document: KnowledgeDocument) throws -> Data {
        try encoder.encode(ExportedDocument(document: document))
    }

    static func markdown(for document: KnowledgeDocument) -> String {
        let tags = document.tags.map { "#\($0.replacingOccurrences(of: " ", with: "-"))" }.joined(separator: " ")
        return """
        # \(document.title)

        > \(document.summary)

        **Categoria:** \(document.category)  
        **Sistema:** \(document.affectedSystem)  
        **Status:** \(document.status.rawValue)  
        **Dificuldade:** \(document.difficulty.rawValue)  
        **Tags:** \(tags)

        ## Problema
        \(document.problemDescription)

        ## Sintomas
        \(document.symptoms)

        ## Mensagens de erro
        \(document.errorMessages)

        ## Causa
        \(document.cause)

        ## Solução
        \(document.solution)

        ## Validação
        \(document.validation)

        ## Riscos e cuidados
        \(document.risks)

        ## Reversão
        \(document.rollback)

        ## Observações
        \(document.notes)
        """
    }
}
