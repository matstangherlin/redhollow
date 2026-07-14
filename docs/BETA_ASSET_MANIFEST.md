# Beta Asset Manifest

Controle central de produção e integração dos **assets finais** da beta (Capítulo Zero).

- Fonte de verdade: `data/art/beta_asset_manifest.json`
- Código: `scripts/art/beta_asset_*.gd`
- Relatório: `tools/report_beta_assets.ps1`

## Princípios

1. **Existência ≠ aprovação.** Um PNG no disco nunca promove `status` para `approved` ou `integrated`.
2. **Sem falsos finais.** Não renomear arte procedural / greybox / placeholder como `final`.
3. **Sem substituição cega.** Placeholders só saem quando houver arquivo real + revisão + aprovação.
4. **Build resiliente.** Arquivo ausente → fallback + warning único; não quebra o jogo.

## Status permitidos

| Status | Significado |
| --- | --- |
| `missing` | Slot planejado; arquivo ainda não existe |
| `concept` | Referência / moodboard / esboço externo |
| `draft` | Trabalho em progresso no path declarado |
| `review` | Submetido à revisão artística |
| `approved` | Aprovado para beta (humana); arquivo presente |
| `integrated` | Aprovado **e** ligado no pipeline de jogo |
| `rejected` | Reprovado; não usar em produção |
| `deprecated` | Obsoleto; manter só para histórico |

## Categorias no manifesto

| Categoria | Conteúdo |
| --- | --- |
| `calder` | Idle, run, jump/fall/land, ataques, dodge, hurt, counter, taunt, death, respawn, interact, Red Brand charge/Breaker |
| `enemy` | Cult Brawler, Vermilite Gunslinger, Chain Penitent, Deacon Rusk |
| `npc` | Elias |
| `street` | Tiles, fachadas, saloon, props, céu, montanhas, cidade, sinais, estátua, foreground, kit modular |
| `church` | Tiles, torre, entrada, praça, estátua, altar, portão, passagem |
| `catacombs` | Tiles, madeira, correntes, velas, raízes, Vermilite, altar, estátua colossal, passagem, sombra Mol-Khar |
| `ui` | Frame de vida, Red Brand, estilo, objetivo, diálogo, boss HUD, menu, mapa, ícones |
| `vfx` | Impactos, trails, telegraphs, Vermilite, checkpoint, barreira, Mol-Khar, finale |

## Campos por entrada

`asset_id`, `category`, `path`, `source_path`, `type`, `dimensions`, `frame_size`, `frames`, `animations`, `pivot`, `facing`, `palette`, `status`, `required_for_beta`, `blocking`, `license`, `author`, `revision`, `checksum` (opcional), `notes`.

## Scripts

| Script | Papel |
| --- | --- |
| `beta_asset_manifest.gd` | Schema, load, status helpers |
| `beta_asset_registry.gd` | Lookup runtime + resolve/fallback + warning único |
| `beta_asset_validator.gd` | Validação, órfãos, paths inválidos, bloqueadores |
| `beta_asset_report.gd` | Relatório estruturado / texto |
| `beta_asset_report_cli.gd` | CLI headless |

## Integração (runtime)

```gdscript
var path := BetaAssetRegistry.resolve_path("calder_idle", procedural_fallback_path)
# status approved/integrated + arquivo existe → path do manifesto
# caso contrário → fallback (warning uma vez por asset_id)

var preview := BetaAssetRegistry.resolve_preview_path("calder_idle", procedural_fallback_path)
# draft/review com arquivo → preview permitido
# rejected/deprecated/missing → fallback
```

`BetaAssetRegistry.is_usable_as_final(id)` só retorna `true` com status `approved`/`integrated` **e** arquivo presente.

## Relatório

```powershell
.\tools\report_beta_assets.ps1
.\tools\report_beta_assets.ps1 -OutFile "docs\_beta_asset_report.txt"
```

O relatório inclui: totais por status, bloqueadores, % por categoria, órfãos / não registrados, paths inválidos, `schema_ok` e `production_ready`.

## Baseline atual

No baseline greybox/beta foundation, a maioria dos slots está `missing` ou `concept`. Contagens `approved` / `integrated` devem permanecer **0** até o workflow de aprovação (ver `docs/ART_APPROVAL_WORKFLOW.md`).

## Relacionados

- `docs/ART_APPROVAL_WORKFLOW.md`
- `docs/ART_BIBLE.md`
- `docs/VISUAL_REFERENCE_RULES.md`
- `docs/CONTENT_PRODUCTION_PLAN.md`
- `docs/NORTH_STAR_FINAL_SAMPLE.md` — amostra visual X 100–900 (não é rua inteira final)
