import AppKit
import SwiftUI

@MainActor
enum PrintService {
    static func print(document: KnowledgeDocument) {
        let rootView = PrintableDocumentView(document: document)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = CGRect(x: 0, y: 0, width: 612, height: max(hostingView.fittingSize.height, 792))

        let info = NSPrintInfo.shared.copy() as! NSPrintInfo
        info.orientation = .portrait
        info.topMargin = 36
        info.bottomMargin = 36
        info.leftMargin = 42
        info.rightMargin = 42
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic

        let operation = NSPrintOperation(view: hostingView, printInfo: info)
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        operation.run()
    }
}

private struct PrintableDocumentView: View {
    let document: KnowledgeDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(document.title)
                .font(.system(size: 24, weight: .bold))
            Text(document.summary)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Divider()

            printSection("Problema", document.problemDescription)
            printSection("Sintomas", document.symptoms)
            printSection("Causa identificada", document.cause)
            printSection("Solução", document.solution)
            printSection("Como validar", document.validation)
            printSection("Riscos e cuidados", document.risks)
            printSection("Como desfazer", document.rollback)
            printSection("Observações", document.notes)

            Divider()
            Text("Categoria: \(document.category) • Sistema: \(document.affectedSystem) • Atualizado em \(document.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 612, alignment: .topLeading)
        .background(.white)
        .foregroundStyle(.black)
    }

    @ViewBuilder
    private func printSection(_ title: String, _ content: String) -> some View {
        if !content.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(content).font(.system(size: 12))
            }
        }
    }
}
