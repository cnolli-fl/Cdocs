import XCTest
@testable import Cdocs

final class DocumentExportServiceTests: XCTestCase {
    func testJSONRoundTripPreservesImportantFields() throws {
        let original = KnowledgeDocument(
            title: "VPN sem DNS",
            summary: "Túnel conecta sem resolução interna",
            affectedSystem: "VPN",
            cause: "Perfil incompleto",
            solution: "Reaplicar perfil aprovado",
            category: "Rede",
            tagsText: "vpn, dns",
            linksText: "https://example.com/runbook",
            difficulty: .advanced,
            status: .review,
            isFavorite: true,
            viewCount: 12
        )

        let data = try DocumentExportService.jsonData(for: original)
        let decoded = try DocumentExportService.decoder.decode(ExportedDocument.self, from: data)
        let restored = decoded.makeDocument()

        XCTAssertEqual(restored.id, original.id)
        XCTAssertEqual(restored.title, original.title)
        XCTAssertEqual(restored.tags, ["vpn", "dns"])
        XCTAssertEqual(restored.difficulty, .advanced)
        XCTAssertEqual(restored.status, .review)
        XCTAssertEqual(restored.viewCount, 12)
    }

    func testMarkdownContainsOperationalSections() {
        let document = KnowledgeDocument(
            title: "Falha de impressão",
            summary: "Fila parada",
            cause: "Fila corrompida",
            solution: "Recriar a fila",
            validation: "Imprimir página de teste"
        )
        let markdown = DocumentExportService.markdown(for: document)

        XCTAssertTrue(markdown.contains("# Falha de impressão"))
        XCTAssertTrue(markdown.contains("## Solução"))
        XCTAssertTrue(markdown.contains("## Validação"))
    }
}
