# RC1 Report — Red Hollow Chapter Zero Beta

**Nome:** Red Hollow — Chapter Zero Beta RC1  
**Classificação:** **REPROVADA**

Não aprovar com P0. Não publicar na Steam. Não liberar release pública.

---

## Identidade da build

| Campo | Valor |
| --- | --- |
| Display | Red Hollow — Chapter Zero Beta RC1 |
| Versão | `0.2.0-beta.rc1` |
| Build number | `20260713.rc1` |
| Canal | `rc1-closed` |
| Save version | `1` (`SaveData.CURRENT_SAVE_VERSION`) |
| Settings version | `1` |
| Manifest conteúdo | `res://resources/content/manifests/beta_demo.tres` |
| Commit HEAD | `4f20f76e5f505f36eacdb9866d7d7e33404c15f3` (`4f20f76`) |
| Data UTC packaging | `2026-07-14T00:10:56Z` (manifest) |
| Engine | Godot **4.7** |

> Nota: working tree tem correções pós-packaging (contratos North Star + manifest molds). Binários em `builds/windows/` são do packaging anterior — **reexportar** antes de distribuir qualquer coisa.

## Artefatos gerados (`builds/windows/`)

| Artefato | Tipo |
| --- | --- |
| `red-hollow-0.2.0-beta.rc1-debug.exe` (+ `.pck`) | Debug / console |
| `red-hollow-0.2.0-beta.rc1-release.exe` (+ `.pck`) | Release |
| `red-hollow-0.2.0-beta.rc1-4f20f76-portable.zip` | Portable ZIP (release) |
| `build-manifest.json` | Metadados (ainda marca gate FAIL do packaging) |

Steam: **não**. Release pública: **não**.

## Pré-requisitos (resultado)

| Pré-requisito | Estado | Evidência |
| --- | --- | --- |
| Runner completo aprovado | **PASS** (pós-fix) | **43/43 PASS**, unexpected 0, exit 0 — `docs/_rc1_gate_fix_out.txt` |
| Playthrough completo assinado | **FAIL** | `BETA_PLAYTHROUGH_REPORT.md` incompleto |
| Zero P0 | **FAIL** | KI-004 + smoke/perf não assinados |
| Zero crash | Não assinado playthrough | Launch smoke 8s OK apenas |
| Zero softlock | Não assinado | — |
| Save válido | Partial | `save_tests` PASS |
| Build Windows funcional | Partial | Export OK; launch release 8s; **reexport pendente** pós-fix |
| Controle funcional | Não assinado build | — |
| Finale funcional | Não assinado build | headless parcial |
| Assets obrigatórios integrados | Partial | placeholders; schema manifest **OK** após paths mold únicos |
| Licenças registradas | Partial | procedural original |

### Correção KI-005 (gate)

Contratos alinhados a `*_art.tscn` + molds com `path` único (destino PNG) e composer em `source_path`.

Arquivos: `vertical_slice_verification.gd`, `vertical_slice_regression_tests.gd`, `content_registry_tests.gd`, `world_map_graph_tests.gd`, `data/art/beta_asset_manifest.json`.

## Smoke test na build exportada

| # | Passo | Resultado |
| ---: | --- | --- |
| 1 | Menu | **Parcial** — processo release iniciou (GUI); não assinado humano |
| 2–14 | Novo Jogo → … → load | **Não executado** |

## Robustez / Performance

Não executados / não medidos na release — ver `PERFORMANCE_BUDGET.md`.

Hardware packaging: i9-10900KF · RTX 2060 SUPER · ~64 GB RAM · Windows.

## Decisão

### Classificação: REPROVADA

KI-005 **fechado** no código. Ainda bloqueiam:

1. **KI-004** — playthrough menu→fim não assinado.  
2. Smoke / robustez / performance na build exportada incompletos.  
3. Binários RC1 **desatualizados** em relação ao gate verde (reexport necessário).

Próximo passo: playthrough + smoke 1–14 + perf na **release reexportada** → reavaliar (**APROVADA COM RESTRIÇÕES** se residual ≤ P1, ou **APROVADA PARA TESTE FECHADO**).

## Referências

- `docs/RC1_KNOWN_LIMITATIONS.md`
- `docs/KNOWN_ISSUES.md`
- `docs/BETA_RELEASE_CHECKLIST.md`
- `docs/_rc1_gate_fix_out.txt`
