import AppKit
import Foundation
import SwiftData

private struct BackupAttachment: Codable {
    let originalName: String
    let storedName: String
    let size: Int64
}

private struct BackupHistory: Codable {
    let id: UUID
    let changedAt: Date
    let changeDescription: String

    init(_ history: DocumentHistory) {
        id = history.id
        changedAt = history.changedAt
        changeDescription = history.changeDescription
    }
}

private struct BackupDocument: Codable {
    let document: ExportedDocument
    let attachments: [BackupAttachment]
    let history: [BackupHistory]
}

private struct BackupPayload: Codable {
    let version: Int
    let exportedAt: Date
    let documents: [BackupDocument]
}

enum BackupError: LocalizedError {
    case invalidBackup

    var errorDescription: String? {
        "A pasta selecionada não contém um backup válido do Cdocs."
    }
}

@MainActor
enum BackupService {
    static func chooseExportDestination() throws -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Escolha onde criar o backup"
        panel.prompt = "Criar backup aqui"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let parent = panel.url else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return parent.appending(path: "Cdocs-Backup-\(formatter.string(from: .now)).cdocsbackup", directoryHint: .isDirectory)
    }

    static func chooseImportSource() throws -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Selecione um backup do Cdocs"
        panel.prompt = "Restaurar"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    static func export(documents: [KnowledgeDocument], to destination: URL) throws {
        guard !FileManager.default.fileExists(atPath: destination.path) else {
            throw CocoaError(.fileWriteFileExists)
        }
        do {
            let attachmentsFolder = destination.appending(path: "Attachments", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: attachmentsFolder, withIntermediateDirectories: true)

            let backupDocuments = try documents.map { document in
                let destinationFolder = attachmentsFolder.appending(path: document.id.uuidString, directoryHint: .isDirectory)
                if !document.attachments.isEmpty {
                    try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
                }

                let metadata = try document.attachments.map { attachment in
                    guard AttachmentService.shared.isSafeStoredName(attachment.storedName) else {
                        throw BackupError.invalidBackup
                    }
                    let source = AttachmentService.shared.url(for: attachment, documentID: document.id)
                    guard FileManager.default.fileExists(atPath: source.path) else {
                        throw CocoaError(.fileNoSuchFile)
                    }
                    let target = destinationFolder.appending(path: attachment.storedName)
                    try FileManager.default.copyItem(at: source, to: target)
                    return BackupAttachment(
                        originalName: attachment.originalName,
                        storedName: attachment.storedName,
                        size: attachment.size
                    )
                }
                return BackupDocument(
                    document: ExportedDocument(document: document),
                    attachments: metadata,
                    history: document.history.map(BackupHistory.init)
                )
            }

            let payload = BackupPayload(version: 2, exportedAt: .now, documents: backupDocuments)
            let data = try DocumentExportService.encoder.encode(payload)
            try data.write(to: destination.appending(path: "documents.json"), options: .atomic)
        } catch {
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
    }

    static func importDocuments(from source: URL, context: ModelContext) throws -> Int {
        let manifest = source.appending(path: "documents.json")
        guard FileManager.default.fileExists(atPath: manifest.path) else { throw BackupError.invalidBackup }
        let payload = try DocumentExportService.decoder.decode(BackupPayload.self, from: Data(contentsOf: manifest))
        guard payload.version == 2 else { throw BackupError.invalidBackup }

        let payloadIDs = payload.documents.map(\.document.id)
        guard Set(payloadIDs).count == payloadIDs.count else { throw BackupError.invalidBackup }

        let existing = try context.fetch(FetchDescriptor<KnowledgeDocument>())
        let existingIDs = Set(existing.map(\.id))
        var importedCount = 0
        var createdDocumentIDs: [UUID] = []

        do {
            for item in payload.documents where !existingIDs.contains(item.document.id) {
                let document = item.document.makeDocument()
                for entry in item.history {
                    document.history.append(DocumentHistory(
                        id: entry.id,
                        changedAt: entry.changedAt,
                        changeDescription: entry.changeDescription,
                        document: document
                    ))
                }
                document.history.append(DocumentHistory(changeDescription: "Restaurado de backup", document: document))
                context.insert(document)
                createdDocumentIDs.append(document.id)

                for metadata in item.attachments {
                    guard AttachmentService.shared.isSafeStoredName(metadata.storedName),
                          metadata.size >= 0,
                          metadata.size <= AttachmentService.maximumSize else {
                        throw BackupError.invalidBackup
                    }
                    let attachmentsRoot = source.appending(path: "Attachments", directoryHint: .isDirectory)
                    let documentFolder = attachmentsRoot.appending(path: item.document.id.uuidString, directoryHint: .isDirectory)
                    let file = documentFolder.appending(path: metadata.storedName).standardizedFileURL
                    let safePrefix = documentFolder.standardizedFileURL.path + "/"
                    guard file.path.hasPrefix(safePrefix), FileManager.default.fileExists(atPath: file.path) else {
                        throw BackupError.invalidBackup
                    }
                    let attachment = try AttachmentService.shared.restoreFile(
                        from: file,
                        originalName: metadata.originalName,
                        storedName: metadata.storedName,
                        size: metadata.size,
                        for: document
                    )
                    document.attachments.append(attachment)
                }
                importedCount += 1
            }
            try context.save()
            return importedCount
        } catch {
            context.rollback()
            for id in createdDocumentIDs {
                try? AttachmentService.shared.removeFolder(for: id)
            }
            throw error
        }
    }
}
