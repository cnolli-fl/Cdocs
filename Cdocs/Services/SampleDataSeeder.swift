import Foundation
import SwiftData

@MainActor
enum SampleDataSeeder {
    private static let seedKey = "Cdocs.didSeedSamples.v1"

    static func seedIfNeeded(context: ModelContext) throws {
        guard !UserDefaults.standard.bool(forKey: seedKey) else { return }
        var descriptor = FetchDescriptor<KnowledgeDocument>()
        descriptor.fetchLimit = 1
        guard try context.fetch(descriptor).isEmpty else {
            UserDefaults.standard.set(true, forKey: seedKey)
            return
        }

        let samples = [
            KnowledgeDocument(
                title: "Impressora de rede não imprime",
                summary: "A fila aceita trabalhos, mas nenhum documento sai da impressora.",
                problemDescription: "Uma impressora fictícia aparece disponível, porém os trabalhos permanecem na fila.",
                symptoms: "Fila parada\nStatus alternando entre disponível e pausado",
                affectedSystem: "Impressão / macOS",
                errorMessages: "A impressora não está respondendo.",
                environment: "Rede de laboratório fictícia",
                cause: "Fila local corrompida após uma alteração simulada de endereço IP.",
                solution: "1. Confirme o endereço IP com a equipe responsável.\n2. Abra Ajustes do Sistema > Impressoras e Scanners.\n3. Remova apenas a fila afetada.\n4. Adicione a impressora novamente pelo protocolo IPP.\n5. Envie uma página de teste.",
                validation: "A página de teste sai e a fila fica vazia.",
                risks: "Não remova outras filas compartilhadas.",
                rollback: "Adicione novamente a configuração anterior registrada no inventário fictício.",
                notes: "Exemplo demonstrativo. Endereços e nomes reais não foram incluídos.",
                category: "Impressão", tagsText: "impressora, rede, fila",
                responsible: "Equipe de TI", difficulty: .medium, status: .documented,
                isFavorite: true, viewCount: 8
            ),
            KnowledgeDocument(
                title: "Usuário não acessa pasta compartilhada",
                summary: "O compartilhamento existe, mas a montagem falha para um usuário.",
                problemDescription: "Falha fictícia ao abrir uma pasta SMB já utilizada anteriormente.",
                symptoms: "Solicitação repetida de credenciais\nVolume não aparece no Finder",
                affectedSystem: "Arquivos / SMB",
                errorMessages: "Houve um problema ao conectar ao servidor.",
                environment: "Ambiente de demonstração",
                cause: "Credencial antiga armazenada no Chaves do iCloud.",
                solution: "1. Feche conexões abertas ao servidor.\n2. Abra o app Acesso às Chaves.\n3. Localize somente a entrada fictícia correspondente ao servidor.\n4. Remova a entrada após confirmar o alvo.\n5. Conecte novamente pelo Finder e informe a credencial atual.",
                validation: "O volume é montado e um arquivo de teste pode ser lido.",
                risks: "Nunca registre a senha neste documento.",
                category: "Acesso", tagsText: "smb, pasta compartilhada, credencial",
                responsible: "Equipe de TI", difficulty: .medium, status: .documented,
                viewCount: 5
            ),
            KnowledgeDocument(
                title: "VPN conecta, mas não acessa sistemas internos",
                summary: "O túnel aparece conectado, mas os destinos internos não respondem.",
                problemDescription: "Cenário fictício para investigar conectividade após a autenticação da VPN.",
                symptoms: "Sites públicos funcionam\nNomes internos não resolvem",
                affectedSystem: "VPN / DNS",
                errorMessages: "Host não encontrado.",
                environment: "Cliente VPN de demonstração",
                cause: "DNS interno não aplicado ao adaptador virtual.",
                solution: "1. Desconecte e reconecte a VPN.\n2. Verifique se o perfil correto está selecionado.\n3. Consulte a configuração DNS sem registrar endereços confidenciais.\n4. Reaplique o perfil aprovado pela empresa.\n5. Teste um nome interno autorizado.",
                validation: "O nome interno resolve e o serviço autorizado responde.",
                risks: "Não altere rotas ou DNS sem seguir a política da empresa.",
                category: "Rede", tagsText: "vpn, dns, rede",
                responsible: "Equipe de TI", difficulty: .advanced, status: .review,
                viewCount: 3
            ),
            KnowledgeDocument(
                title: "Outlook não sincroniza mensagens",
                summary: "Novas mensagens não aparecem, embora a conta permaneça conectada.",
                symptoms: "Caixa de entrada desatualizada\nEnvio pendente",
                affectedSystem: "Microsoft Outlook",
                environment: "Conta de demonstração",
                cause: "Cache local inconsistente.",
                solution: "1. Confirme a conectividade.\n2. Verifique o status do serviço pelos canais oficiais.\n3. Feche e abra o Outlook.\n4. Se permitido pela política, recrie o cache local da conta.\n5. Aguarde a sincronização inicial.",
                validation: "Uma mensagem de teste aparece em outro cliente e no Outlook.",
                category: "E-mail", tagsText: "outlook, sincronização, cache",
                responsible: "Equipe de TI", difficulty: .medium, status: .draft,
                viewCount: 1
            ),
            KnowledgeDocument(
                title: "Computador sem acesso à internet",
                summary: "O Mac está conectado à rede, porém páginas não carregam.",
                symptoms: "Wi‑Fi conectado\nNavegador sem resposta de sites",
                affectedSystem: "macOS / Rede",
                environment: "Rede fictícia",
                cause: "A investigação ainda não foi concluída.",
                solution: "1. Compare com outro dispositivo autorizado.\n2. Desative e reative o Wi‑Fi.\n3. Verifique data e hora.\n4. Teste a resolução DNS.\n5. Registre o resultado antes de alterações adicionais.",
                validation: "Abrir um site público autorizado e executar o teste corporativo de conectividade.",
                category: "Rede", tagsText: "internet, wifi, dns",
                responsible: "Equipe de TI", difficulty: .easy, status: .draft
            )
        ]

        for sample in samples {
            sample.history.append(DocumentHistory(changeDescription: "Documento de demonstração criado", document: sample))
            context.insert(sample)
        }
        try context.save()
        UserDefaults.standard.set(true, forKey: seedKey)
    }
}
