# Art Approval Workflow (Beta)

Fluxo humano para promover assets finais do Capítulo Zero.  
Complementa `docs/BETA_ASSET_MANIFEST.md`.

## Regra absoluta

**Ninguém e nenhum script marca `approved` só porque o arquivo existe.**

Placeholders, geometria procedural, sheets de fixture de teste e arte greybox **nunca** entram como `approved` / `integrated`.

## Estados e transições

```
missing → concept → draft → review → approved → integrated
                         ↘ rejected
approved → deprecated (substituição)
rejected → draft (retrabalho)
```

| De | Para | Quem | Condição |
| --- | --- | --- | --- |
| `missing` | `concept` | Arte / direção | Referência documentada em `notes` / moodboard |
| `concept` | `draft` | Autor | Arquivo no `path` declarado (PNG/WebP/tres) |
| `draft` | `review` | Autor | Dimensões/frames batem com manifesto; changelog em `revision` |
| `review` | `approved` | Direção / lead arte | Checklist abaixo OK |
| `approved` | `integrated` | Eng / arte-tech | Ligado no pipeline; smoke visual OK |
| `*` | `rejected` | Revisor | Motivo em `notes` |
| `approved`/`integrated` | `deprecated` | Direção | Substituto novo no manifesto |

## Checklist de aprovação (`review` → `approved`)

1. Arquivo existe em `path` e abre no Godot sem erro de import.
2. `type`, `dimensions`, `frame_size`, `frames`, `pivot`, `facing` conferidos.
3. Paleta alinhada à `ART_BIBLE` (Vermilite com moderação).
4. Licença preenchida (`license`, `author`); sem asset externo sem autorização.
5. Não é reexport de placeholder/procedural com nome enganoso.
6. Comparação lado a lado com greybox: silhueta/escala jogável OK (Calder: ver `VISUAL_SCALE_STUDY.md`).
7. Entrada no manifesto atualizada: `status`, `revision++`, `checksum` opcional, `notes`.

Só depois disso o status muda para `approved` **no JSON**, por edição humana (ou ferramenta que registre aprovador).

## Checklist de integração (`approved` → `integrated`)

1. Registry / visual pipeline usa `BetaAssetRegistry.resolve_path` (ou path aprovado explícito).
2. Fallback procedural permanece para CI/headless se o arquivo for opcional em testes.
3. Suite relevante PASS (ex.: visual pipeline, area beta complete).
4. `status` = `integrated` no manifesto; `blocking` pode cair para `false` se o slot deixar de bloquear ship.

## Preview vs produção

| Situação | Preview | Produção (`resolve_path`) |
| --- | --- | --- |
| `missing` / sem arquivo | fallback | fallback + warning único |
| `draft` / `review` com arquivo | arquivo OK | fallback (não tratar como final) |
| `approved` / `integrated` com arquivo | arquivo | arquivo |
| `rejected` / `deprecated` | fallback | fallback |

## Relatório e gate

```powershell
.\tools\report_beta_assets.ps1
```

- `schema_ok`: manifesto coerente (ids, statuses, paths `res://`).
- `production_ready`: nenhum entry `required_for_beta` + `blocking` ausente/não aprovado.
- Órfãos: arquivos sob `scan_roots` não listados no manifesto → registrar ou remover.

Enquanto Cap. Zero final art não estiver completa, **é esperado** `production_ready = false`.

## O que não fazer

- Copiar arte procedural para `art/**` e marcar `approved`.
- Usar palavra `final` no filename como atalho de status.
- Auto-aprovar no import / no validator.
- Apagar fallbacks greybox antes da integração real.
- Commitar assets de terceiros sem licença em `license`.

## Responsáveis (preencher no manifesto)

Campos `author` e `notes` carregam a pessoa/equipa. Enquanto vazios, o slot continua `missing`/`concept` e o relatório lista bloqueadores normalmente.
