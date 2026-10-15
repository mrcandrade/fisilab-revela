# Modificações do Revela em relação ao LightCraft

O Revela é a versão do [LightCraft](https://github.com/storytold/lightcraft) (ArtCraft Team e contribuidores,
MIT OR Apache-2.0) que o **FisiLab — LARFIC · UFRGS**, em parceria com o **CTA — Centro de Tecnologia Acadêmica**,
disponibiliza na Suíte FisiLab para estudantes, professores e técnicos da UFRGS. Este arquivo lista o que foi alterado
e por quê. Modificações © 2026 FisiLab — LARFIC/UFRGS, sob os mesmos termos (MIT OR Apache-2.0).

## Nome e marca

- **Nome visível**: "LightCraft" virou "Revela" em tudo o que o usuário vê: título da janela, nome passado ao
  `eframe::run_native`, menus ("About Revela", "Quit Revela"…), diálogos, avisos, mensagens de erro, textos do
  servidor MCP, ajuda `--help`/`--version` do aplicativo e da CLI e os catálogos de tradução
  (`crates/ui-egui/locales/*.json`, chaves e valores renomeados juntos, para as traduções continuarem valendo). As
  notas de "What's New" (`docs/whats-new.md`, exibidas no programa) também usam o novo nome e ganharam uma nota
  inicial sobre a Suíte FisiLab.
- **Por quê**: o aviso do LightCraft (NOTICE) diz que o nome, a marca nominativa e os logotipos da ArtCraft são marcas
  registradas que não fazem parte da licença aberta. Uma versão modificada não deve se apresentar com o nome original.
- **Marca ArtCraft removida**: `docs/brand/` (logotipos e marca ArtCraft) foi apagado. O README original, que os
  exibia, foi mantido como `README.upstream.md` (as imagens dessa pasta não existem mais nele). Nenhum logotipo da
  ArtCraft é exibido ou embutido pelo programa.
- **Ícone**: o lince do LightCraft foi trocado pelo ícone do Revela (`assets/fisilab/`), tanto no executável
  (recurso do Windows) quanto na janela e na barra de tarefas. O ícone original continua em `assets/app-icon/`
  (MIT OR Apache-2.0) para as embalagens de macOS/Linux, que não foram refeitas.

## Suíte FisiLab

- **Crate `fisilab-brand`** (`crates/fisilab-brand`, cópia da fonte única da suíte): paleta, tela de abertura com a
  logo do CTA e janela "Sobre a Suíte FisiLab".
- **Tela de abertura**: ligada em `apps/lightcraft/src/main.rs` (`fisilab_brand::splash::enable()`), desenhada a cada
  quadro por `LightcraftApp::ui` (`fisilab_brand::frame`, em `crates/ui-egui/src/lib.rs`). `FISILAB_NO_SPLASH=1` a
  desliga.
- **`APP_INFO`** em `crates/ui-egui/src/lib.rs`: nome, descrição ("Revelação e catálogo de fotos"), equivalente
  proprietário ("Adobe Lightroom"), versão e créditos ao LightCraft.
- **Menu Ajuda**: novo item "Sobre a Suíte FisiLab…" (comando `app.fisilab`). A janela "About Revela" original
  (que credita os contribuidores do LightCraft) foi mantida, renomeada; o botão "Join the ArtCraft Discord" dela virou
  "Sobre a Suíte FisiLab…".
- **Links da comunidade** (`crates/ui-egui/src/links.rs`): "Join the ArtCraft Discord", "LightCraft Website",
  "LightCraft on GitHub" e "ArtCraft Website" foram substituídos por "Site da Suíte FisiLab" (`app.suite`),
  "Manifesto pelas tecnologias livres" (`app.manifesto`), "Projeto original (LightCraft)" (`app.upstream`) e
  "Reportar um problema" (`app.feedback`, agora em `github.com/mrcandrade/fisilab-revela/issues`). O botão do Discord na
  barra superior virou um botão "Sobre a Suíte FisiLab…". "Revela Help" continua abrindo a documentação do
  projeto original no GitHub.

## Cores: temas "UFRGS Noite" e "UFRGS Dia"

- Dois temas novos, primeiros da lista, em `crates/ui-egui/src/theme.rs`: **UFRGS Noite** (escuro, id `ufrgsNoite`) e
  **UFRGS Dia** (claro, id `ufrgsDia`), montados a partir de `fisilab_brand::palette::NOITE` e `DIA` (painéis, fundo,
  campos, bordas, textos, destaque vermelho, foco azul, seleção, avisos e erros). As medidas e o layout são os do tema
  original; mudam só as cores. Sombras usam o marinho da marca.
- **UFRGS Noite é o padrão** (`ThemeKind`, `DarkTheme` e `LightTheme` em `crates/ui-egui/src/state.rs`, e
  `AppSettings::default`). O tema claro padrão é UFRGS Dia. Os temas originais (Charcoal, Midnight, Silver, Paper)
  continuam disponíveis em Exibir ▸ Aparência e em Configurações ▸ Interface, e uma escolha já salva é respeitada.
- Cores que representam dados do documento (rótulos de cor das fotos, sobreposição de máscara) não mudaram.
- Testes novos: os temas UFRGS vêm da paleta, são o padrão, e todo tema mantém o contraste do texto.

## Idioma

- Uma instalação nova (sem configurações salvas e sem `LIGHTCRAFT_LANGUAGE`) começa em **português do Brasil**. Um
  idioma escolhido e salvo continua valendo. A escolha é feita no aplicativo de desktop
  (`fresh_install_language` em `apps/lightcraft/src/main.rs`); a biblioteca de interface continua em inglês por padrão,
  para os testes e a CLI.

## Executáveis, identificador e pastas

- Executáveis: `fisilab-revela.exe` (interface) e `fisilab-revela-cli.exe` (linha de comando), por `[[bin]]` nos crates
  `apps/lightcraft` e `apps/lightcraft-cli` (os nomes dos pacotes Cargo continuam `lightcraft` e `lightcraft-cli`).
  Mensagens que citam os executáveis (`fisilab-revela --control`, `fisilab-revela-cli mcp`…) e os testes que os executam foram
  atualizados.
- Identificador do app: `ai.storyteller.lightcraft` → `br.ufrgs.fisilab.revela`.
- Pasta de configurações: `%APPDATA%\FisiLab Revela` (Windows), `~/Library/Application Support/FisiLab Revela` (macOS),
  `~/.config/fisilab-revela` (Linux). Modo portátil: `portable.txt` ou `Revela.portable` ao lado do executável,
  dados em `FisiLabRevelaData`. Biblioteca padrão: `~/Pictures/Revela Library`. Registro de pânico:
  `fisilab-revela-panics.log`. Nada disso colide com uma instalação do LightCraft.
- Filtros de log: o executável agora se chama `fisilab-revela` (crate `fisilab_revela`, pois o Rust troca o hífen por
  sublinhado nos alvos de log), então os filtros padrão incluem `fisilab_revela*`.
- Recursos do Windows (`apps/lightcraft/build.rs`): ícone, ProductName, FileDescription, CompanyName, LegalCopyright,
  OriginalFilename e InternalName do Revela.
- `packaging/windows/` (MSI WiX e `package.ps1`): nomes de executáveis, ícone, nome do produto, fabricante, chave de
  registro (`Software\FisiLab\Revela`), pasta de instalação (`Program Files\Suite FisiLab\Revela`) e novos GUIDs
  (UpgradeCode e componente), para não substituir uma instalação do LightCraft.
  A Suíte FisiLab distribui um instalador próprio (Inno Setup).
- Na metainformação de Linux, no `nfpm.yaml` e no `nix/package.nix`, os links para getartcraft.com e para o Discord
  foram trocados pelo repositório do Revela; o restante dessas embalagens não foi rebatizado.

## Contato com servidores externos

- Não há verificação de atualizações, telemetria nem envio de relatórios de falha no LightCraft. Os únicos acessos à
  rede acontecem quando o usuário pede: download de modelos (GitHub/opencv_zoo, Hugging Face, darktable-ai, espelhos
  do SAM 3 configurados pelo usuário) e dos nomes de lugares (GeoNames). Eles foram mantidos.
- Links para getartcraft.com e discord.gg/artcraft foram removidos do programa e das embalagens. A mensagem "PhotoCraft
  isn't installed" agora aponta para `github.com/storytold/photocraft` em vez de getartcraft.com.
- `.github/` (CI, releases e financiamento do projeto original) foi apagado, para não rodar contra este fork.

## O que não mudou

- Nomes de crates, pacotes, módulos, identificadores Rust, ids de comandos (exceto os links da comunidade), variáveis
  de ambiente (`LIGHTCRAFT_*`), formatos e extensões de arquivo (`.lcpreset`, `.lccurve`, formato do catálogo
  `lightcraft-catalog`, namespace XMP `ns.lightcraft.app`, URIs `lightcraft://` do MCP, nome `lightcraft` do servidor
  MCP), para manter compatibilidade com bibliotecas, predefinições e sidecars do LightCraft.
- Metadados gravados em arquivos técnicos (Software "LightCraft" em sidecars XMP e em DNGs, `xmptk`, marca dos
  arquivos sintéticos de teste do Photo Merge): mantidos porque o leitor de DNG e os testes reconhecem esses valores.
  A tag Software das exportações passou a ser "Revela".
- O aplicativo web (`apps/lightcraft-web`) só teve os textos renomeados; nomes de armazenamento do navegador
  continuam os originais.
- Comentários de código, documentação técnica em `docs/` (exceto `whats-new.md`), `CLAUDE.md`/`AGENTS.md`,
  `LICENSE-MIT`, `LICENSE-APACHE`, `assets/ATTRIBUTION.md` e o texto original do `NOTICE` (mantido por inteiro abaixo
  do cabeçalho do Revela).
- O recurso "Edit in PhotoCraft" continua procurando o PhotoCraft.
