import XCTest
@testable import Cdocs

final class DocumentSearchServiceTests: XCTestCase {
    func testSearchIgnoresCaseAndDiacritics() {
        let document = KnowledgeDocument(
            title: "Falha de conexão",
            summary: "Problema de rede",
            affectedSystem: "VPN",
            solution: "Reaplicar o perfil",
            status: .documented
        )

        var filters = DocumentFilters()
        filters.searchText = "CONEXAO"

        XCTAssertEqual(DocumentSearchService.filter([document], using: filters).map(\.id), [document.id])
    }

    func testSidebarAndAdvancedFiltersAreCombined() {
        let favorite = KnowledgeDocument(
            title: "VPN",
            summary: "Rede",
            affectedSystem: "VPN",
            solution: "Teste",
            difficulty: .advanced,
            status: .documented,
            isFavorite: true
        )
        let other = KnowledgeDocument(
            title: "Impressora",
            summary: "Fila",
            affectedSystem: "Impressão",
            solution: "Teste",
            difficulty: .easy,
            status: .draft
        )

        var filters = DocumentFilters()
        filters.sidebar = .favorites
        filters.difficulty = .advanced
        filters.status = .documented

        XCTAssertEqual(DocumentSearchService.filter([other, favorite], using: filters).map(\.id), [favorite.id])
    }

    func testTrashOnlyShowsDeletedDocuments() {
        let active = KnowledgeDocument(title: "Ativo")
        let deleted = KnowledgeDocument(title: "Excluído", isTrashed: true)
        var filters = DocumentFilters()
        filters.sidebar = .trash

        XCTAssertEqual(DocumentSearchService.filter([active, deleted], using: filters).map(\.id), [deleted.id])
    }

    func testSearchIncludesOperationalSafetyAndReferenceFields() {
        let document = KnowledgeDocument(
            title: "Procedimento",
            risks: "Confirmar janela de manutenção",
            rollback: "Restaurar configuração anterior",
            notes: "Chamado encerrado",
            linksText: "https://example.com/referencia",
            responsible: "Equipe Azul"
        )

        for query in ["manutencao", "anterior", "encerrado", "referencia", "equipe azul"] {
            var filters = DocumentFilters()
            filters.searchText = query
            XCTAssertEqual(DocumentSearchService.filter([document], using: filters).count, 1, "Falhou para: \(query)")
        }
    }
}
