# Red Hollow — Known Issues

Issues na linha **RC1** (`0.2.0-beta.rc1`). Gate pós-fix: **43/43 PASS** (`docs/_rc1_gate_fix_out.txt`).

Classificação:

- **P0:** impede declarar a beta pronta para release / teste fechado de ship;
- **P1:** deve ser corrigido antes do próximo gate;
- **P2:** dívida ou higiene.

## Resumo do gate (RC1 pós-fix)

| Item | Estado |
| --- | --- |
| Versão packaging | `0.2.0-beta.rc1` |
| Suítes | **43 PASS / 0 FAIL** · unexpected **0** |
| Gate automatizado | **PASS** (exit 0) |
| Playthrough menu→fim | **Não assinado** |
| Build Windows RC1 | Exportada; **reexport** recomendado pós-fix |
| Classificação RC1 | **REPROVADA** — ver `docs/RC1_REPORT.md` |

## P0 — bloqueadores

### KI-004 — Playthrough manual completo não assinado

- **Estado:** aberto.
- **Escopo:** main menu → rua → igreja → catacumbas → Deacon Rusk → finale → retorno → Continuar.
- **Impacto:** automação não substitui validação de fluxo na build exportada.

### KI-RC1-SMOKE — Smoke/robustez/performance na build exportada incompletos

- Launch release ~8 s OK; passos 1–14 **não** assinados.
- Performance FPS não medida na release RC1.

## P1 — estabilização

### KI-113 — Working tree / binários desalinhados do gate

- Packaging foi feito com tree suja; correções de contrato são posteriores aos `.exe` atuais.

### KI-114 — Source art pesada Cult Brawler

- Regras de ignore de source ainda a auditar.

### KI-107 — Leaks no encerramento de `world_map_graph_tests`

- Noise ObjectDB/resources at exit; suite passa.

## P2 — dívida

### KI-102 — Auto-load desativado

- Intencional na demo greybox.

### KI-101 — Panic unlock Esc

- Útil para QA; risco em release.

### KI-ART-01 — Arte / áudio finais pendentes

- Procedural + registro de licença original; sem pack externo integrado.

## Resolvidos

### KI-005 — Gate automatizado

- **Resolvido** pós-RC1 packaging: contratos `*_art.tscn` + mold paths únicos.
- Evidência: `docs/_rc1_gate_fix_out.txt` (43/43).

### KI-116 — Manifest molds paths duplicados

- **Resolvido:** `path` = slot PNG único; composer em `source_path`.

### KI-002 — physics flush arenas

- Corrigido; `combat_arena_tests` PASS.

### KI-UNDERGROUND-CRASH / KI-115

- Resolvidos historicamente; suítes art e `region_visual_tests` PASS no gate atual.

## Histórico

Auditoria pré-fix (38/43) documentada em `docs/_rc1_runner_out.txt` e packaging inicial.
