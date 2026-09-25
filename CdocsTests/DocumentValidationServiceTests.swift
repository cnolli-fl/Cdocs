import XCTest
@testable import Cdocs

final class DocumentValidationServiceTests: XCTestCase {
    func testRequiredFieldsReturnHelpfulErrors() {
        let errors = DocumentValidationService.errors(for: DocumentDraft())

        XCTAssertEqual(errors.count, 3)
        XCTAssertTrue(errors.contains { $0.contains("título") })
        XCTAssertTrue(errors.contains { $0.contains("resumo") })
        XCTAssertTrue(errors.contains { $0.contains("solução") })
    }

    func testCompleteDraftIsValid() {
        var draft = DocumentDraft()
        draft.title = "Problema"
        draft.summary = "Resumo"
        draft.solution = "1. Resolver"

        XCTAssertTrue(DocumentValidationService.errors(for: draft).isEmpty)
    }
}
