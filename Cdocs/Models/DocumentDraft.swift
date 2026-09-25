import Foundation

struct DocumentDraft: Equatable {
    var title = ""
    var summary = ""
    var problemDescription = ""
    var symptoms = ""
    var affectedSystem = ""
    var errorMessages = ""
    var environment = ""
    var cause = ""
    var solution = ""
    var validation = ""
    var risks = ""
    var rollback = ""
    var notes = ""
    var category = "Geral"
    var tagsText = ""
    var linksText = ""
    var occurrenceDate = Date.now
    var responsible = ""
    var difficulty = Difficulty.easy
    var status = DocumentStatus.draft
    var isFavorite = false

    init() {}

    init(document: KnowledgeDocument) {
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
        tagsText = document.tagsText
        linksText = document.linksText
        occurrenceDate = document.occurrenceDate
        responsible = document.responsible
        difficulty = document.difficulty
        status = document.status
        isFavorite = document.isFavorite
    }

    func applying(to document: KnowledgeDocument) {
        document.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        document.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        document.problemDescription = problemDescription
        document.symptoms = symptoms
        document.affectedSystem = affectedSystem.trimmingCharacters(in: .whitespacesAndNewlines)
        document.errorMessages = errorMessages
        document.environment = environment
        document.cause = cause
        document.solution = solution
        document.validation = validation
        document.risks = risks
        document.rollback = rollback
        document.notes = notes
        document.category = category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Geral" : category.trimmingCharacters(in: .whitespacesAndNewlines)
        document.tagsText = tagsText
        document.linksText = linksText
        document.occurrenceDate = occurrenceDate
        document.responsible = responsible
        document.difficulty = difficulty
        document.status = status
        document.isFavorite = isFavorite
    }
}
