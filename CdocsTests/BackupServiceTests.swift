import SwiftData
import XCTest
@testable import Cdocs

@MainActor
final class BackupServiceTests: XCTestCase {
    func testBackupPreservesDeletedStateAndHistory() throws {
        let sourceContainer = try makeContainer()
        let document = KnowledgeDocument(
            title: "Documento na lixeira",
            summary: "Resumo",
            solution: "Solução",
            status: .documented,
            isTrashed: true,
            deletedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        document.history.append(DocumentHistory(
            changedAt: Date(timeIntervalSince1970: 1_600_000_000),
            changeDescription: "Alteração original",
            document: document
        ))
        sourceContainer.mainContext.insert(document)
        try sourceContainer.mainContext.save()

        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let backup = root.appending(path: "Teste.cdocsbackup", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }

        try BackupService.export(documents: [document], to: backup)

        let destinationContainer = try makeContainer()
        XCTAssertEqual(try BackupService.importDocuments(from: backup, context: destinationContainer.mainContext), 1)
        let restored = try XCTUnwrap(destinationContainer.mainContext.fetch(FetchDescriptor<KnowledgeDocument>()).first)

        XCTAssertEqual(restored.id, document.id)
        XCTAssertTrue(restored.isTrashed)
        XCTAssertEqual(restored.deletedAt, document.deletedAt)
        XCTAssertTrue(restored.history.contains { $0.changeDescription == "Alteração original" })
        XCTAssertTrue(restored.history.contains { $0.changeDescription == "Restaurado de backup" })
    }

    func testAttachmentStoredNameRejectsTraversalAndUnknownTypes() {
        XCTAssertFalse(AttachmentService.shared.isSafeStoredName("../segredo.pdf"))
        XCTAssertFalse(AttachmentService.shared.isSafeStoredName("script.command"))
        XCTAssertTrue(AttachmentService.shared.isSafeStoredName("550E8400-E29B-41D4-A716-446655440000.pdf"))
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([KnowledgeDocument.self, DocumentAttachment.self, DocumentHistory.self])
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
    }
}
