# Beta — Balance Report (Capítulo Zero)

Data: 2026-07-13. Passagem de balanceamento baseada em critérios de playtest / curva alvo.  
**Identidade do combate preservada** (mesmos moves, counterabilidade, tags). Sem sistemas novos.

Registro técnico: `docs/CHAPTER_ZERO_BALANCE.md` (atualizado). Telemetria: `BetaPlaytestRecorder` (debug).

## Metas de playtest

| Meta | Alvo |
| --- | --- |
| Duração total Cap. Zero | 30–45 min (novo) |
| Mortes antes do boss | 0–3 |
| Arena igreja | 1–2 tentativas típicas |
| Boss — vitória média | **2–5 tentativas** |
| Counter no boss | útil, não obrigatório |
| Red Brand no boss | recompensa clara (stagger) |
| Stun lock | não permitido |

## Métricas registradas (recorder)

Eventos / agregados em `user://playtests/*.jsonl` e no `session_end` / `beta_completed`:

| Métrica | Evento(s) |
| --- | --- |
| Duração total | `elapsed_sec`, `duration_sec` |
| Mortes | `death` + contador |
| Dano recebido | `damage_taken` |
| Dodge | `dodge_used` |
| Counter | `counter_used` |
| Red Brand | `red_brand_used` |
| Tempo por arena | `arena_completed.arena_time_sec` |
| Tempo no boss | `boss_defeated.boss_time_sec` |
| Tentativas do boss | `boss_attempt` / `boss_attempts` |
| Segredos | `secret_found` (via WorldMapState) |
| Objetivos compreendidos | proxy `objective_completed.understood_proxy` (dwell ≥ 8s e ≤ 2 mortes) |
| Checkpoints | `checkpoint_activated` |

Painel F10: snapshot inclui os contadores.

---

## Tabela antes / depois

### Campo (inimigos comuns)

| Parâmetro | Antes | Depois | Justificativa |
| --- | ---: | ---: | --- |
| Cult Brawler HP | 14 | **12** | Encontro 1 ensina e termina rápido |
| Cult Brawler attack_cd | 1.35 | **1.55** | Menos spam; janela de leitura |
| Cult Brawler detect | 220 | **200** | Pressão baixa na introdução |
| Cult Hook damage | 5 | **4** | Menos punitivo no ensino |
| Cult Hook startup | 0.48 | **0.56** | Telegraph mais legível |
| Gunslinger HP | 12 | **11** | Rota opcional sem grind |
| Gunslinger reload | 1.15 | **1.35** | Janela de dodger pós-tiro |
| Gunslinger attack_cd | 1.5 | **1.65** | Ritmo ensinável |
| Gunshot damage | 4 | **3** | Erro recuperável (HP 12) |
| Gunshot startup | 0.55 | **0.62** | Telegraphed before projectile |
| Chain Penitent HP | 18 | **16** | Igreja exige leitura, não tank |
| Penitent attack_cd | 1.65 | **1.85** | Menos castigo em loop |
| Penitent vulnerable | 0.85 | **1.05** | Recompensa clara após miss |
| Sweep damage | 6 | **5** | Erro caro mas não one-shot combo |

### Arena (igreja)

| Parâmetro | Antes | Depois | Justificativa |
| --- | --- | --- | --- |
| Spawn | Simultâneo ×3 | **Stagger 1.7s** entre spawns | Doc já prometia leitura sequencial; evita overwhelm |
| Mensagem | “três arquetipos…” | “Um de cada vez — leia o telegraph” | Onboarding no cenário |

### Deacon Rusk (boss)

| Parâmetro | Antes | Depois | Justificativa |
| --- | ---: | ---: | --- |
| max_health | 120 | **100** | ~2–5 wins; ritmo Cap. Zero |
| move_speed | 95 | **92** | Ligeiramente menos chase |
| phase_2_speed | 1.28 | **1.16** | Fase 2 perceptível, não jump-scare |
| P2 startup scale | ×0.82 | **×0.90** | Telegraph ainda legível |
| P2 recovery scale | ×0.86 | **×0.92** | Recuperação utilizável |
| choose_attack | 0.42 | **0.55** | Respiro entre strings |
| intro | 1.35 | **1.55** | Leitura de abertura |
| phase_transition | 2.1 | **2.4** | Fase 2 sinalizada |
| stagger_duration | 1.75 | **1.90** | Red Brand / punish window |
| stagger_immunity | 3.6 | **4.2** | Anti stun-lock pós-stagger |
| hitstun_resistance | 0.5 | **0.62** | Sem lock de jab spam |
| max_hitstun/hit | 0.34 | **0.20** | Sem stun lock |
| red_brand_stagger | 100 | **100** | Mantido: 1 Breaker = stagger |
| jab1 startup | 0.34 | **0.40** | Counter window mais justa |
| jab2 startup | 0.22 | **0.28** | Idem |
| charge dmg / startup | 8 / 0.62 | **7 / 0.72** | Dodge teach; menos letal |
| sweep dmg / startup | 9 / 0.78 | **8 / 0.82** | Counter útil |
| slam dmg / startup | 11 / 0.58 | **9 / 0.68** | Fase 2 legível |
| armored charge dmg / startup | 10 / 0.48 | **9 / 0.58** | Red Brand ainda é a resposta |

### Red Brand (ensino igreja)

| Parâmetro | Antes | Depois | Justificativa |
| --- | ---: | ---: | --- |
| Cache energy floor | 35 | **45** | Garante breaker para barreira sem grind |

### Jogador (sem mudança de identidade)

HP 12, dodge/counter cooldowns e moveset **inalterados** — spam evitado via cadência inimiga e hitstun do boss, não nerf do Calder.

---

## Curva resultante

1. **Rua** — pressão baixa; telegraphs longos; duo só após pistoleiro (gate).  
2. **Igreja** — Penitente leciona espaço; arena escalonada; Coração + barreira [U].  
3. **Catacumbas** — checkpoint generoso; boss com tentativa justa; finale.

## O que não mudou (de propósito)

- Tags `counterable` / `super_armor` / kits de ataque.
- Número de encontros / áreas.
- Sistema de estilo / ranks.
- Salvamento e progressão.

## QA sugerido

1. Playtest novo com recorder (F10).  
2. Vitória Rusk em 2–5 tentativas (médio).  
3. Arena: nunca 3 agressivos no mesmo instante nos primeiros ~3–4 s.  
4. Confirmar jab spam **não** prende Rusk em hitstun infinito.
