# Cdocs

Cdocs é um aplicativo nativo para macOS destinado a registrar, localizar e reutilizar soluções de suporte de TI. Os dados ficam armazenados localmente no Mac e o aplicativo não depende de internet ou serviços externos.

## Funcionalidades

- Cadastro completo de problemas, diagnóstico, solução, validação, riscos e reversão.
- Pesquisa instantânea em todo o conteúdo e filtros por coleção, status e dificuldade.
- Organização por categorias, tags, favoritos, recentes e estados do documento.
- Editor de procedimentos com Markdown e blocos de código copiáveis.
- Persistência local com SwiftData.
- Histórico básico de alterações e contador de consultas.
- Anexos locais de até 25 MB, com seleção pelo Finder e arrastar/soltar.
- Lixeira com restauração e exclusão definitiva.
- Exportação individual em Markdown ou JSON e importação de JSON.
- Backup completo em pasta `.cdocsbackup`, incluindo anexos, sem substituir registros existentes durante a restauração.
- Impressão e exportação em PDF pelo painel de impressão do macOS.
- Atalhos de teclado e suporte aos temas claro e escuro.
- Cinco registros fictícios para demonstrar o uso.

## Requisitos

- macOS 14 ou posterior.
- Xcode 15 ou posterior. O projeto foi verificado com Xcode 26.6.
- Nenhuma dependência externa.

## Abrir e executar

1. Abra [Cdocs.xcodeproj](Cdocs.xcodeproj) no Xcode.
2. Selecione o esquema `Cdocs` e o destino `My Mac`.
3. Pressione `Command + R`.

Na primeira execução, o aplicativo cria cinco documentações fictícias. Elas podem ser editadas ou excluídas normalmente.

Também é possível compilar pela linha de comando:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Cdocs.xcodeproj \
  -scheme Cdocs \
  -configuration Debug \
  -derivedDataPath /tmp/CdocsDerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

## Testes

No Xcode, pressione `Command + U`. Pela linha de comando:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Cdocs.xcodeproj \
  -scheme Cdocs \
  -configuration Debug \
  -derivedDataPath /tmp/CdocsDerivedData \
  CODE_SIGNING_ALLOWED=NO test
```

Os testes cobrem pesquisa, filtros, lixeira, validação, serialização JSON, importação por modelo e exportação Markdown.

## Onde os dados ficam armazenados

O banco SwiftData é criado pelo contêiner padrão do aplicativo, dentro da área de Application Support administrada pelo macOS para o identificador `com.local.Cdocs`.

Os anexos ficam em:

```text
~/Library/Application Support/Cdocs/Attachments/
```

Não edite manualmente o banco ou a pasta de anexos. Use o backup do próprio aplicativo.

## Backup e restauração

Para criar um backup:

1. Abra o menu de dados na barra de ferramentas ou use `Arquivo > Criar backup`.
2. Escolha uma pasta de destino.
3. O Cdocs cria uma pasta com extensão `.cdocsbackup`, contendo `documents.json` e a pasta `Attachments`.

Para restaurar:

1. Escolha `Arquivo > Restaurar backup`.
2. Selecione a pasta `.cdocsbackup`.
3. Documentos com o mesmo identificador são preservados e não são sobrescritos silenciosamente.

É recomendável guardar o backup em um local protegido e aprovado pela política da empresa. O backup pode conter informações internas presentes nas documentações.

## Exportação individual e PDF

- No menu de ações de uma documentação, escolha exportar como Markdown ou JSON.
- Para importar um JSON, use `Dados > Importar documentação JSON` na barra de ferramentas.
- Para gerar PDF, escolha `Imprimir` e depois `Salvar como PDF` no painel nativo do macOS.

## Estrutura do projeto

```text
Cdocs/
├── Models/       Modelos SwiftData e estado editável
├── Services/     Pesquisa, validação, anexos, backup, impressão e dados fictícios
├── Views/        Navegação, lista, detalhe, editor e renderização Markdown
├── Assets.xcassets
└── CdocsApp.swift

CdocsTests/       Testes unitários
Cdocs.xcodeproj/  Projeto do Xcode
```

## Gerar uma versão distribuível

1. No Xcode, selecione `Product > Archive`.
2. No Organizer, escolha `Distribute App`.
3. Para distribuição fora da App Store, configure uma equipe Apple Developer, assinatura Developer ID e notarização.
4. Para uso apenas no próprio Mac durante o desenvolvimento, execute diretamente pelo Xcode.

Antes de distribuir dentro da empresa, ajuste o identificador do bundle, a equipe de assinatura e as regras de sandbox conforme a política corporativa. O projeto já inclui o ícone oficial do Cdocs em todos os tamanhos exigidos pelo macOS.

## Privacidade e segurança

- Não registre senhas, tokens, chaves, dados pessoais ou segredos da empresa.
- Revise documentações e anexos antes de exportar ou compartilhar um backup.
- O aplicativo valida tamanho e extensão dos anexos, mas não faz análise antimalware.

## Melhorias futuras

- Pré-visualização lado a lado do Markdown durante a edição.
- Destaque visual do termo pesquisado.
- Versionamento com comparação completa entre revisões.
- Testes de interface automatizados.
- Criptografia opcional do backup.
- Sincronização corporativa, apenas se futuramente autorizada e definida pela empresa.
