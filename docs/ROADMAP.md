# Red Hollow — Roadmap

Roadmap alinhado ao estado real do repositório (Godot 4.7, demo greybox jogável) e à meta **Capítulo Zero — O Sino Antes do Anoitecer**.

## Princípios

- Uma funcionalidade por etapa quando possível.
- Cada fase termina com teste manual ou headless documentado.
- Greybox até arte final substituir por área.
- 2D lateral, um plano; sem magia elemental genérica.
- 60 FPS no Windows.

## Legenda

- ✅ Concluído
- 🔧 Concluído com dívida técnica
- 🎯 Próximo
- 📋 Planejado

---

## Fase 0 — Base do projeto ✅

- Documentação inicial, git, `.gitignore`, convenções
- Repositório `redhollow` na main

## Fase 1 — Main scene e shell ✅

- Main scene `vertical_slice_greybox.tscn`
- Shell persistente: player, câmera, managers, `WorldHost`

## Fase 2 — Movimento base ✅

- `CharacterBody2D`, andar, acelerar, virar, gravidade

## Fase 3 — Pulo e colisão ✅

- Pulo, coyote time, buffer, queda, recuperação por `fall_recovery_y`

## Fase 4 — Estados do jogador 🔧

- Estados no `player.gd` (enum + lógica inline)
- 📋 Máquina de estados em módulos separados (`TECH_DEBT.md`)

## Fase 5 — Ataque corpo a corpo ✅

- Combo 3 golpes, `AttackData`, hitbox/hurtbox

## Fase 6 — Inimigo simples ✅

- Cult Brawler, dummy, attacker test

## Fase 7 — Esquiva e counter ✅

- Dodge com i-frames; counter com janela e ataque dedicado

## Fase 8 — Estilo e provocações ✅

- `StyleManager`, ranks, provocação no player

## Fase 9 — Red Brand ✅

- Energia, Breaker carregado (U), barreira destrutível, cristal na igreja

## Fase 10 — Exploração e backtracking ✅

- Rua → igreja → subterrâneo; barreira; retorno por exits

## Fase 11 — Diálogo e checkpoint ✅

- JSON, Elias, checkpoint com save automático ao ativar

## Fase 12 — Salvamento básico 🔧

- Save versionado, validação, backup, F8/F9
- Auto-load **desativado** na greybox; load manual
- 📋 Auto-load seguro para beta

## Fase 13 — Vertical slice técnica ✅

- Arena, dois brawlers, Deacon Rusk, overlay de conclusão, F7 reset
- Testes headless; plano em `VERTICAL_SLICE_TEST_PLAN.md`

---

## Fase 14 — Documentação canônica ✅

- GDD, arquitetura real, bíblia narrativa/arte/UI, escopos beta/final, dívida técnica

## Fase 15 — Estabilização pré-beta 🎯

- Testes headless sem runtime errors
- Gameplay lock manager (substituir panic unlock)
- Hitstop/feedback sem resets globais de `Engine.time_scale`
- Início da separação de `player.gd`

**Gate:** `TECH_DEBT.md` itens P0 críticos.

## Fase 16 — Arte Capítulo Zero (rua + igreja) 📋

- Pixel art Calder, rua, igreja, UI skin base
- Ver `CONTENT_PRODUCTION_PLAN.md` fase C

## Fase 17 — Inimigos beta (3 tipos) 📋

- Arte + IA derivada de Cult Brawler
- `BETA_DEMO_SCOPE.md`

## Fase 18 — Catacumbas + set pieces 📋

- Subterrâneo/catacumbas ilustrados
- Estátua Mol-Khar, aparição, silhueta Arcturus
- Uma variante de corrupção ambiental

## Fase 19 — UI beta completa 📋

- Mapa, objetivos, diário, pausa, tela Red Brand (≤3 habilidades)
- `UI_BIBLE.md`

## Fase 20 — Beta pública 🎯

- Capítulo Zero jogável 30–45 min
- Build Windows, QA `TEST_MATRIX.md`

---

## Pós-beta (jogo final) — resumo 📋

| Marco | Conteúdo |
| --- | --- |
| Distrito expandido | Novas áreas metroidvania |
| Barões | Encontros jogáveis (Silas, Rosa, Arcturus, Magnus) |
| Progressão ampla | Mais habilidades Red Brand |
| Palácio Rubro | Clímax narrativo |
| Polimento | Áudio, acessibilidade, localização |

Detalhes: `FINAL_GAME_SCOPE.md`.

## O que não está no roadmap imediato

- cidade inteira antes da beta;
- crafting complexo;
- loot aleatório;
- todos os arquétipos de inimigo;
- duplicação manual de mapas corrompidos.
