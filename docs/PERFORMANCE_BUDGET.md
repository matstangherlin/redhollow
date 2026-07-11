# Red Hollow — Performance Budget (beta local)

Alvo: **60 FPS** estável no Windows na configuração de referência documentada.

## Configuração de referência (QA)

| Parâmetro | Valor |
| --- | --- |
| OS | Windows 10/11 x64 |
| Resolução | **1920×1080**, janela ou borderless |
| VSync | Ligado |
| Max FPS | 60 (`Engine.max_fps` / opções) |
| GPU | D3D12 (`rendering_device/driver.windows=d3d12`) |
| Cena | Capítulo Zero completo (rua → igreja → subterrâneo → Rusk) |
| Build | **Release** export (`Windows Beta Release`) |

## Métricas a medir

| Métrica | Como medir | Alvo beta |
| --- | --- | --- |
| FPS médio | Godot Monitor (Debugger) ou overlay | ≥ **58** (≈60 cap) |
| Frame time médio | Monitor → Time → Frame | ≤ **16.7 ms** |
| Frame time p95 | Amostrar 60s combate | ≤ **20 ms** |
| Memória estática | Monitor → Memory | ≤ **512 MB** (greybox+beta systems) |
| Objetos/nós | Monitor → Objects | Tendência estável; sem leak por transição |
| Partículas ativas | Contagem VFX feedback + barreira | Sem spike &gt; 200 partículas CPU simultâneas |
| Colisões ativas | Debugger → Visible Collision Shapes | Estável na arena (≤ ~40 areas ativas típico) |

## Marcos de primeira ocorrência (latência)

Medir **tempo até primeiro frame útil** na build release:

| Marco | Alvo |
| --- | --- |
| Boot menu → gameplay interativo | ≤ 5 s (SSD) |
| Transição de área | ≤ 0.5 s bloqueio perceptível |
| Primeiro ataque (input → hitbox active) | ≤ 1 frame input lag + startup AttackData |
| Primeiro VFX de impacto | ≤ 2 frames após hit_landed |
| Primeiro diálogo (linha visível) | ≤ 0.3 s após interact |
| Boss Rusk — fase 1 estável | ≥ 55 FPS médio |

## Cenários de stress recomendados

1. Arena igreja — 3 inimigos + gates.
2. Gunslinger + penitente na rua.
3. Rusk fase 2 com partículas + screen shake + hitstop.
4. Alt+Tab durante combate (sem leak de input).

## Orçamento por sistema (greybox beta)

| Sistema | Budget frame (orientativo) |
| --- | --- |
| Física 2D + player | ≤ 4 ms |
| Inimigos (≤ 4 ativos) | ≤ 4 ms |
| UI/HUD | ≤ 1 ms |
| Audio (pools) | ≤ 0.5 ms |
| VFX CPU particles | ≤ 1.5 ms |
| Resto / margem | ≥ 5 ms |

## Ações se fora do budget

1. Reproduzir na build **release**, gravar cena e posição.
2. Profiler Godot 1 frame spike + 10 s média.
3. Registrar em `KNOWN_ISSUES.md` como P1 (performance).
4. **Não** marcar release QA-approved.

## Notas

- Greybox geométrico é leve; dívida futura (arte final, tilemaps) exigirá revisão deste documento.
- `FeedbackSystem` usa pools fixos (12 SFX 2D, 24 VFX CPU) — dimensionados para beta.
