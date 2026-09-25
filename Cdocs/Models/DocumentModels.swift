import Foundation
import SwiftData

enum DocumentStatus: String, CaseIterable, Codable, Identifiable {
    case draft = "Rascunho"
    case documented = "Documentado"
    case review = "Em revisão"
    case obsolete = "Obsoleto"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .draft: "pencil.circle"
        case .documented: "checkmark.seal"
        case .review: "eye.circle"
        case .obsolete: "archivebox"
        }
    }
}

enum Difficulty: String, CaseIterable, Codable, Identifiable {
    case easy = "Fácil"
    case medium = "Médio"
    case advanced = "Avançado"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .easy: "1.circle"
        case .medium: "2.circle"
        case .advanced: "3.circle"
        }
    }
}

@Model
final class KnowledgeDocument {
    @Attribute(.unique) var id: UUID
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
    var tagsText: String
    var linksText: String
    var occurrenceDate: Date
    var createdAt: Date
    var updatedAt: Date
    var responsible: String
    var difficultyRaw: String
    var statusRaw: String
    var isFavorite: Bool
    var viewCount: Int
    // O valor no próprio modelo permite que o SwiftData faça a migração leve
    // de bases criadas antes da implementação da lixeira.
    var isTrashed: Bool = false
    var deletedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \DocumentAttachment.document)
    var attachments: [DocumentAttachment] = []

    @Relationship(deleteRule: .cascade, inverse: \DocumentHistory.document)
    var history: [DocumentHistory] = []

    init(
        id: UUID = UUID(),
        title: String = "",
        summary: String = "",
        problemDescription: String = "",
        symptoms: String = "",
        affectedSystem: String = "",
        errorMessages: String = "",
        environment: String = "",
        cause: String = "",
        solution: String = "",
        validation: String = "",
        risks: String = "",
        rollback: String = "",
        notes: String = "",
        category: String = "Geral",
        tagsText: String = "",
        linksText: String = "",
        occurrenceDate: Date = .now,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        responsible: String = "",
        difficulty: Difficulty = .easy,
        status: DocumentStatus = .draft,
        isFavorite: Bool = false,
        viewCount: Int = 0,
        isTrashed: Bool = false,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.problemDescription = problemDescription
        self.symptoms = symptoms
        self.affectedSystem = affectedSystem
        self.errorMessages = errorMessages
        self.environment = environment
        self.cause = cause
        self.solution = solution
        self.validation = validation
        self.risks = risks
        self.rollback = rollback
        self.notes = notes
        self.category = category
        self.tagsText = tagsText
        self.linksText = linksText
        self.occurrenceDate = occurrenceDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.responsible = responsible
        self.difficultyRaw = difficulty.rawValue
        self.statusRaw = status.rawValue
        self.isFavorite = isFavorite
        self.viewCount = viewCount
        self.isTrashed = isTrashed
        self.deletedAt = deletedAt
    }

    var status: DocumentStatus {
        get { DocumentStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .easy }
        set { difficultyRaw = newValue.rawValue }
    }

    var tags: [String] {
        get { Self.split(tagsText) }
        set { tagsText = newValue.joined(separator: ", ") }
    }

    var links: [String] {
        get { Self.split(linksText) }
        set { linksText = newValue.joined(separator: "\n") }
    }

    var searchableText: String {
        [title, summary, problemDescription, symptoms, affectedSystem, errorMessages,
         environment, cause, solution, validation, risks, rollback, notes,
         category, tagsText, linksText, responsible]
            .joined(separator: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    func markUpdated(_ description: String) {
        updatedAt = .now
        history.append(DocumentHistory(changeDescription: description, document: self))
    }

    func makeCopy() -> KnowledgeDocument {
        KnowledgeDocument(
            title: "Cópia de \(title)", summary: summary,
            problemDescription: problemDescription, symptoms: symptoms,
            affectedSystem: affectedSystem, errorMessages: errorMessages,
            environment: environment, cause: cause, solution: solution,
            validation: validation, risks: risks, rollback: rollback, notes: notes,
            category: category, tagsText: tagsText, linksText: linksText,
            occurrenceDate: occurrenceDate, responsible: responsible,
            difficulty: difficulty, status: .draft
        )
    }

    private static func split(_ value: String) -> [String] {
        value.components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

@Model
final class DocumentAttachment {
    @Attribute(.unique) var id: UUID
    var originalName: String
    var storedName: String
    var fileExtension: String
    var size: Int64
    var createdAt: Date
    var document: KnowledgeDocument?

    init(
        id: UUID = UUID(),
        originalName: String,
        storedName: String,
        fileExtension: String,
        size: Int64,
        createdAt: Date = .now,
        document: KnowledgeDocument? = nil
    ) {
        self.id = id
        self.originalName = originalName
        self.storedName = storedName
        self.fileExtension = fileExtension
        self.size = size
        self.createdAt = createdAt
        self.document = document
    }
}

@Model
final class DocumentHistory {
    @Attribute(.unique) var id: UUID
    var changedAt: Date
    var changeDescription: String
    var document: KnowledgeDocument?

    init(
        id: UUID = UUID(),
        changedAt: Date = .now,
        changeDescription: String,
        document: KnowledgeDocument? = nil
    ) {
        self.id = id
        self.changedAt = changedAt
        self.changeDescription = changeDescription
        self.document = document
    }
}

enum SidebarSelection: Hashable {
    case all
    case recent
    case favorites
    case drafts
    case review
    case obsolete
    case trash
    case category(String)
    case tag(String)
}

enum DocumentSort: String, CaseIterable, Identifiable {
    case updated = "Atualização"
    case created = "Criação"
    case title = "Título"
    case views = "Mais consultados"

    var id: String { rawValue }
}
