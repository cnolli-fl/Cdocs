---
name: Cdocs
description: Base operacional nativa do macOS para registrar, localizar e executar runbooks com clareza.
colors:
  accent-blue: "#26659C"
  on-accent: "#FFFFFF"
  surface-canvas: "Canvas"
  text-primary: "CanvasText"
  text-secondary: "GrayText"
  fill-quaternary: "color-mix(in srgb, CanvasText 8%, transparent)"
  separator: "color-mix(in srgb, CanvasText 20%, transparent)"
  warning-orange: "orange"
  destructive-red: "red"
  favorite-yellow: "yellow"
typography:
  detail-title:
    fontFamily: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.18
  section-title:
    fontFamily: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.25
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.45
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "11px"
    fontWeight: 500
    lineHeight: 1.3
  code:
    fontFamily: "ui-monospace, SFMono-Regular, Menlo, monospace"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.45
rounded:
  field: "6px"
  search: "7px"
  compact: "8px"
  soft: "9px"
  panel: "10px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "6px"
  base: "8px"
  md: "12px"
  lg: "14px"
  xl: "18px"
  2xl: "24px"
  3xl: "28px"
  4xl: "34px"
components:
  search-field:
    backgroundColor: "{colors.fill-quaternary}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.search}"
    padding: "0 10px"
    height: "30px"
  code-block:
    backgroundColor: "{colors.surface-canvas}"
    textColor: "{colors.text-primary}"
    typography: "{typography.code}"
    rounded: "{rounded.soft}"
    padding: "12px"
  status-badge:
    backgroundColor: "{colors.fill-quaternary}"
    textColor: "{colors.text-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "5px 9px"
  editor-text-area:
    backgroundColor: "{colors.surface-canvas}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.field}"
---

# Design System: Cdocs

## Overview

**Creative North Star: "A Bancada de Resolução"**

Cdocs é uma ferramenta operacional nativa do macOS: direta, calma e feita para consulta durante um incidente. Como uma bancada de trabalho bem organizada, a interface mantém biblioteca, resultados e procedimento simultaneamente visíveis, enquanto o conteúdo técnico ocupa o centro da experiência. A personalidade aparece na precisão, não na decoração.

O sistema privilegia controles, materiais, menus, seleção e tipografia nativos. A densidade é confortável para uso diário, os runbooks têm largura de leitura controlada e os estados permanecem inequívocos em claro, escuro, alto contraste e sem depender apenas de cor. Cartões decorativos, gradientes e cromatismo de marca em grandes áreas não fazem parte desta linguagem.

**Características principais:**

- Estrutura macOS familiar em três colunas.
- Hierarquia tipográfica compacta, com largura de leitura de 760 pt no detalhe.
- SF Symbols acompanhando rótulos; símbolos nunca substituem texto quando a ação pode ser ambígua.
- Cor restrita a ação, seleção, aviso e estado.
- Superfícies semânticas e dinâmicas do macOS para paridade entre temas claro e escuro.

## Colors

A paleta é essencialmente neutra e fornecida pelo sistema; o azul Cdocs aparece com parcimônia nas ações principais e no tint nativo.

### Primary

- **Azul Cdocs** (`#26659C`): cor do asset `AccentColor`; aplica-se ao tint, seleção e botões `.borderedProminent`, como “Salvar” e “Nova documentação”.
- **Sobre o azul** (`#FFFFFF`): referência portátil para conteúdo sobre o accent; na implementação, o macOS escolhe o contraste do controle.

### Neutral

- **Canvas do sistema** (`Canvas`): representa `Color(nsColor: .textBackgroundColor)`, `.background` e materiais nativos. Não converter em um branco ou cinza fixo.
- **Texto primário do sistema** (`CanvasText`): conteúdo e rótulos principais, implementados com `.primary` ou o foreground padrão.
- **Texto secundário do sistema** (`GrayText`): resumo, metadados, contadores e ajuda, implementados com `.secondary` ou `.tertiary` conforme a hierarquia.
- **Preenchimento quaternário** (`color-mix(in srgb, CanvasText 8%, transparent)`): representa de forma portátil `.quaternary` e suas opacidades em busca, badges, tags, avisos neutros e linhas clicáveis.
- **Separador do sistema** (`color-mix(in srgb, CanvasText 20%, transparent)`): referência portátil para `.separator`, usada em contornos funcionais de campos e blocos de código.

### State

- **Laranja de atenção** (`orange`): aviso de privacidade e indicador de alterações não salvas.
- **Vermelho destrutivo** (`red`): marcador de campo obrigatório e `role: .destructive`; sempre acompanhado de texto, contexto e confirmação.
- **Amarelo de favorito** (`yellow`): estrela preenchida de favorito; o estado também é expresso por `star.fill` e rótulo acessível.

**A Regra da Cor com Função.** Cor existe para orientar ação, seleção ou estado. Todo significado permanece disponível por texto e/ou SF Symbol.

**A Regra Semântica.** Os valores CSS no frontmatter são representações portáteis. No SwiftUI, preservar `.primary`, `.secondary`, `.tertiary`, `.quaternary`, `.background`, `.separator`, `textBackgroundColor` e materiais nativos para adaptação automática a claro, escuro e contraste aumentado.

## Typography

**Display Font:** SF Pro via fonte do sistema, com fallbacks `-apple-system` e `system-ui`  
**Body Font:** SF Pro via fonte do sistema, com os mesmos fallbacks  
**Label/Mono Font:** SF Mono via `.system(..., design: .monospaced)`, com Menlo como fallback portátil

**Character:** neutra, compacta e altamente legível. Pesos semibold e bold marcam estrutura; tamanho ou peso nunca é usado apenas como ornamento. Os valores em pixels do frontmatter documentam o baseline visual; a implementação deve continuar usando os estilos dinâmicos do SwiftUI sempre que o código não fixa um tamanho.

### Hierarchy

- **Detail title** (bold, 28 pt, line-height do sistema): título do runbook no painel de detalhe; é o único tamanho fixo de destaque.
- **Section title** (semibold, `.title3`): abre seções como Problema, Solução e Como validar, sempre com SF Symbol.
- **Modal title** (bold, `.title2`): cabeçalhos do editor e do histórico.
- **Row title** (`.headline`): títulos na lista e rótulos de grupos.
- **Body** (regular, `.body`): prosa, Markdown e entradas; a coluna de leitura limita o conteúdo a 760 pt.
- **Supporting text** (`.subheadline`, `.caption`, `.caption2`): resumo, labels de campos, metadados e timestamps, com `.secondary`/`.tertiary`.
- **Code** (regular, `.body`, monoespaçada): comandos, mensagens e códigos de erro; seleção de texto sempre habilitada no detalhe.

**A Regra do Procedimento Primeiro.** Títulos criam pontos de retomada; corpo e código preservam conforto de leitura. Não comprimir runbooks para aumentar densidade visual.

## Layout

A janela abre em 1280 × 780 pt e não deve ficar menor que 980 × 640 pt. A navegação usa `NavigationSplitView` com todas as colunas visíveis por padrão:

- **Barra lateral:** 190–280 pt, ideal 220 pt; biblioteca, situação, categorias, tags e lixeira.
- **Lista:** 300–470 pt, ideal 350 pt; busca, filtros, ordenação e metadados suficientes para decidir.
- **Detalhe:** ocupa o espaço restante; conteúdo centralizado com máximo de 760 pt, padding horizontal de 34 pt e vertical de 28 pt.

O ritmo nasce de uma base de 8 pt, mas respeita os ajustes observados do SwiftUI: 6–10 pt em relações compactas, 12–18 pt dentro de grupos e 24–34 pt entre regiões principais. O editor é uma sheet rolável de no mínimo 820 × 660 pt, ideal 940 × 780 pt; seu formulário limita-se a 880 pt e usa 24 pt de margem.

Quando a janela estreita, deixar o `NavigationSplitView` administrar recolhimento e navegação segundo o comportamento do macOS. Não criar uma navegação paralela nem transformar as colunas em cards.

## Elevation & Depth

O sistema não define sombras customizadas. Profundidade vem da hierarquia nativa da janela, sheets, barras, listas, `GroupBox`, divisores e diferenças tonais semânticas. Busca, badges, tags, avisos e anexos usam preenchimentos quaternários discretos; campos e blocos de código podem somar contorno `.separator` de 1 pt quando a delimitação ajuda a operar.

**A Regra Plana por Padrão.** Superfícies permanecem planas. Elevação estrutural pertence ao macOS; não adicionar sombras a linhas, seções ou runbooks.

## Shapes

As formas são discretas e subordinadas aos controles nativos. Campos usam raio de 6 pt; busca, 7 pt; linhas e blocos compactos, 8 pt; código e aviso de privacidade, 9 pt; avisos neutros maiores, 10 pt. Tags e status usam cápsulas. Bordas aparecem apenas para delimitar entrada e código, nunca para enquadrar toda seção de leitura.

SF Symbols são a geometria recorrente do produto: `books.vertical`, `clock`, `star`, `pencil.circle`, `eye.circle`, `archivebox`, `trash`, `folder`, `tag`, `checklist`, `doc.on.doc` e os símbolos próprios de status e dificuldade. Preservar escala e alinhamento nativos.

## Components

### Navigation

- **Estrutura:** `NavigationSplitView` em três colunas, `List` com `.sidebar` na primeira e `.inset` na segunda.
- **Seleção:** tint e realce nativos; rótulo textual, SF Symbol e contador monoespaçado quando aplicável.
- **Toolbar:** ações frequentes aparecem como `Label`; operações de dados e ações menos frequentes ficam em `Menu`.
- **Rodapé da barra lateral:** material `.bar`, ícone `lock.laptopcomputer` e mensagem de armazenamento local.

### Search & Filters

- **Busca:** 30 pt de altura, raio de 7 pt, 10 pt de padding horizontal e preenchimento `.quaternary.opacity(0.7)`; lupa à esquerda e limpeza `xmark.circle.fill` somente com texto presente.
- **Filtros:** `Menu` em `.controlSize(.small)` para status, dificuldade e sistema; ordenação permanece no extremo oposto da linha.
- **Estados:** busca sem resultado exibe `ContentUnavailableView` e a ação “Limpar filtros”.

### Document Rows

- **Hierarquia:** título `.headline` em até duas linhas, resumo `.subheadline` em até duas linhas, categoria/sistema/status em `.caption` e atualização em `.caption2`.
- **Densidade:** 7 pt entre blocos e 7 pt de padding vertical.
- **Favorite state:** `star.fill` amarelo com rótulo acessível; a ausência da estrela comunica o estado padrão.

### Runbook Detail

- **Leitura:** seções verticais a cada 24 pt; título e SF Symbol em `.title3.weight(.semibold)`; texto selecionável.
- **Markdown:** suporta títulos, listas, parágrafos e blocos de código sem esconder a estrutura operacional.
- **Code block:** fonte monoespaçada, scroll horizontal, padding de 12 pt, raio de 9 pt, fundo `windowBackgroundColor`, contorno `.separator` de 1 pt e ação “Copiar”.
- **Status badge:** texto + símbolo, peso medium, padding de 9 × 5 pt e forma de cápsula; cor não diferencia os quatro status.
- **Tags:** `.caption`, padding de 8 × 4 pt, forma de cápsula e fluxo com gap de 6 pt.
- **Attachments:** linha clicável com fundo quaternário, raio de 8 pt, nome, tamanho e indicador de abertura externa.

### Editor

- **Estrutura:** cabeçalho fixo, formulário rolável e rodapé fixo; seções semânticas em `GroupBox` com título + SF Symbol.
- **Fields:** controles nativos. Labels `.subheadline.weight(.medium)`; obrigatoriedade usa asterisco vermelho e validação textual.
- **Text areas:** fundo `textBackgroundColor`, raio de 6 pt, contorno `.separator` de 1 pt; mensagens/códigos usam fonte monoespaçada. A área de solução tem pelo menos 210 pt de altura.
- **Primary action:** “Salvar” usa `.borderedProminent` e atalho ⌘S; “Cancelar” e “Salvar como rascunho” mantêm estilo nativo secundário.
- **Dirty state:** rodapé alterna entre texto secundário e laranja; fechar com alterações abre confirmação.
- **Privacy notice:** símbolo e texto, padding de 12 pt, raio de 9 pt e fundo laranja a 9%.

### Buttons & Destructive Actions

- **Primary:** `.borderedProminent` somente para o próximo passo principal.
- **Secondary:** `.bordered` para ações como “Copiar solução”.
- **Utility:** `.borderless`/`.plain` em limpar busca, copiar código e remover anexo, sempre com `help` ou label acessível.
- **Destructive:** `role: .destructive`; mover para a Lixeira é recuperável, excluir definitivamente explicita que documento e anexos não poderão ser recuperados.

### Empty, Error & Disabled States

- **Sem seleção:** `ContentUnavailableView` explica selecionar ou registrar um procedimento e oferece “Nova documentação”.
- **Lista vazia:** oferece criar o primeiro documento; com filtros ativos, oferece limpá-los.
- **Validation/error:** alertas nomeiam o problema e mostram mensagem acionável; ação que depende de conteúdo, como copiar solução vazia, fica desabilitada.
- **Trash:** aviso neutro no detalhe e toolbar substituída por restaurar/excluir definitivamente.

## Do's and Don'ts

### Do:

- **Do** manter a arquitetura barra lateral → lista → detalhe e deixar o sistema gerenciar o recolhimento das colunas.
- **Do** usar controles, menus, materiais, fontes e estados de foco nativos do macOS.
- **Do** limitar runbooks a 760 pt e preservar seleção de texto em conteúdo técnico.
- **Do** combinar SF Symbol, texto e estado acessível em status, favoritos, avisos e ações.
- **Do** testar toda nova superfície em claro e escuro; cores semânticas devem adaptar-se sem overrides paralelos.
- **Do** manter a solução, validação, riscos e rollback visualmente fáceis de retomar durante um incidente.

### Don't:

- **Don't** substituir cores semânticas por branco, preto ou cinza fixos, nem criar paletas independentes para claro e escuro.
- **Don't** usar cor como único indicador de status, favorito, obrigatoriedade, erro ou ação destrutiva.
- **Don't** adicionar cards decorativos, sombras customizadas, gradientes ou grandes áreas do azul Cdocs.
- **Don't** trocar SF Symbols por ícones de estilo misto ou remover rótulos de ações ambíguas.
- **Don't** reduzir texto técnico, código ou áreas de edição para ganhar densidade aparente.
- **Don't** ocultar a consequência de exclusão permanente nem contornar a Lixeira em fluxos recuperáveis.
