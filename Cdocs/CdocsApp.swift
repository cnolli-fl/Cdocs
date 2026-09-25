import SwiftData
import SwiftUI

@main
struct CdocsApp: App {
    private let container: ModelContainer = {
        let schema = Schema([
            KnowledgeDocument.self,
            DocumentAttachment.self,
            DocumentHistory.self
        ])
        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let configuration = ModelConfiguration(
            "Cdocs",
            schema: schema,
            isStoredInMemoryOnly: isTesting
        )
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Não foi possível iniciar a base local: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .frame(minWidth: 980, minHeight: 640)
        }
        .modelContainer(container)
        .defaultSize(width: 1280, height: 780)
        .commands {
            CdocsCommands()
        }

        Settings {
            SettingsView()
        }
    }
}

private struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var startupError: String?

    var body: some View {
        ContentView()
            .task {
                do {
                    try SampleDataSeeder.seedIfNeeded(context: modelContext)
                } catch {
                    startupError = "Não foi possível preparar os dados de demonstração: \(error.localizedDescription)"
                }
            }
            .alert("Falha ao iniciar os exemplos", isPresented: Binding(
                get: { startupError != nil },
                set: { if !$0 { startupError = nil } }
            )) {
                Button("OK") { startupError = nil }
            } message: {
                Text(startupError ?? "")
            }
    }
}

extension Notification.Name {
    static let newDocument = Notification.Name("Cdocs.newDocument")
    static let editDocument = Notification.Name("Cdocs.editDocument")
    static let duplicateDocument = Notification.Name("Cdocs.duplicateDocument")
    static let deleteDocument = Notification.Name("Cdocs.deleteDocument")
    static let focusSearch = Notification.Name("Cdocs.focusSearch")
    static let printDocument = Notification.Name("Cdocs.printDocument")
    static let exportBackup = Notification.Name("Cdocs.exportBackup")
    static let importBackup = Notification.Name("Cdocs.importBackup")
}

struct CdocsCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Nova documentação") {
                NotificationCenter.default.post(name: .newDocument, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandGroup(after: .textEditing) {
            Button("Buscar na documentação") {
                NotificationCenter.default.post(name: .focusSearch, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)
        }

        CommandMenu("Documentação") {
            Button("Editar") {
                NotificationCenter.default.post(name: .editDocument, object: nil)
            }
            .keyboardShortcut("e", modifiers: .command)

            Button("Duplicar") {
                NotificationCenter.default.post(name: .duplicateDocument, object: nil)
            }
            .keyboardShortcut("d", modifiers: .command)

            Divider()

            Button("Mover para a Lixeira") {
                NotificationCenter.default.post(name: .deleteDocument, object: nil)
            }
            .keyboardShortcut(.delete, modifiers: .command)
        }

        CommandGroup(replacing: .printItem) {
            Button("Imprimir documentação…") {
                NotificationCenter.default.post(name: .printDocument, object: nil)
            }
            .keyboardShortcut("p", modifiers: .command)
        }

        CommandGroup(after: .saveItem) {
            Divider()
            Button("Criar backup…") {
                NotificationCenter.default.post(name: .exportBackup, object: nil)
            }
            Button("Restaurar backup…") {
                NotificationCenter.default.post(name: .importBackup, object: nil)
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Armazenamento") {
                LabeledContent("Banco de dados", value: "Local neste Mac")
                Text("Use Arquivo > Criar backup para manter uma cópia portátil da sua base.")
                    .foregroundStyle(.secondary)
            }
            Section("Privacidade") {
                Label("Não registre senhas, tokens ou chaves nos documentos.", systemImage: "hand.raised")
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 260)
        .padding()
    }
}
