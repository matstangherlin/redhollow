# Combat Feedback Profiles

Perfis de apresentação por ataque Calder — **não alteram** `AttackData` (dano, timing de hitbox, knockback, hitstun).

**Registry:** `CombatFeedbackProfileLibrary`  
**Resource:** `CombatFeedbackProfile`  
**Resolver:** `CombatFeedbackResolver.resolve_hit_feedback()`  
**Diretor:** `CombatFeedbackDirector` + `CombatVfxSpawner`

---

## Perfis criados

| Ataque | Profile ID | Tier | Shake | Partículas | SFX |
| --- | --- | --- | --- | --- | --- |
| Calder Straight | `calder_straight_feedback` | LIGHT | 1.8 / 0.06s | 4 | `punch` |
| Body Hook | `body_hook_feedback` | MEDIUM | 4.8 / 0.11s | 7 | `kick` (grave) |
| Red Knuckle | `red_knuckle_feedback` | HEAVY | 7.8 / 0.16s | 10 | `impact_vermilite` |
| Counter Attack | `calder_counter_feedback` | COUNTER | 6.8 hit / 9.0 parry | 11 | `counter` |
| Red Brand Breaker Lv1 | `red_brand_breaker_lv1_feedback` | BREAKER | 13.0 / 0.26s | 16 + shockwave | `red_brand_breaker` |
| Red Brand Breaker Lv2 | `red_brand_breaker_lv2_feedback` | BREAKER | 14.5 / 0.28s | 18 + shockwave | `red_brand_breaker` |

Arquivos em `resources/combat/feedback_profiles/`.

---

## Hierarquia de impacto (antes → depois)

| Ataque | Antes | Depois |
| --- | --- | --- |
| Straight | LIGHT genérico, shake 2.5 | Shake quase imperceptível (1.8), 4 partículas, pitch alto |
| Body Hook | LIGHT (heurística por dano) | **MEDIUM** dedicado, bias lateral, kick grave |
| Red Knuckle | HEAVY genérico | Zoom punch, 10 partículas vermelhas, pitch baixo |
| Counter | Shake duplicado (player + hit) | Parry shake no perfil; hit shake no impacto |
| Breaker | Shake duplicado (brand config + hit) | Shake unificado no perfil + shockwave Vermilite |

---

## Campos do perfil

- **Hitstop** (`attacker_hitstop`, `target_hitstop`) — espelham `AttackData`; gameplay continua lendo `AttackData`.
- **Câmera** — `shake_intensity`, `shake_duration`, `camera_effect`, `zoom_amount`.
- **VFX** — `vfx_kind`, `particle_count`, `impact_color`, `flash_strength`, `swing_trail_*`, `shockwave_enabled`, `lateral_impact_bias`.
- **Áudio** — `sfx_id`, `sfx_volume_scale`, `pitch_min`/`pitch_max`.
- **Counter** — `parry_shake_*`, `parry_flash_strength`, `parry_sfx_id`.
- **Acessibilidade** — `respect_shake_setting`, `respect_flash_setting`, `respect_particle_setting`.

---

## Acessibilidade

| Setting | Efeito |
| --- | --- |
| Screen shake 0% | `CameraController` suprime shake e punch zoom |
| Flashes reduzidos | Partículas ×0.55, flash alpha ×0.35 |
| Partículas reduzidas | Contagem ×0.4 (opção nova no menu) |
| Volume 0% | Bus SFX via `SettingsManager.apply_audio()` |
| Vibração off | `FeedbackSettingsAccess.is_vibration_enabled()` |

---

## Áudio

Todos os SFX usam **placeholder procedural** gerado em runtime:

- **Origem:** `scripts/audio/placeholder_audio_factory.gd`
- **Licença:** código próprio do projeto — sem assets externos
- **Substituição:** trocar stream no `AudioManager` library quando áudio final existir

---

## Assets faltantes (produção)

| Asset | Status |
| --- | --- |
| SFX punch/kick finais | Placeholder procedural |
| SFX counter dedicado | Placeholder (`counter`) |
| SFX Red Brand Breaker | Placeholder (`red_brand_breaker`) |
| SFX impact Vermilite | Placeholder (`impact_vermilite`) |
| Partículas pixel art | Procedural `CPUParticles2D` |
| Swing trail sprite | Procedural burst |
| Shockwave sprite | Procedural burst expandido |
| Vibração gamepad | Stub mobile `Input.vibrate_handheld` |

---

## Testes

```bash
godot --headless --path . --main-scene res://scenes/tests/test_bootstrap.tscn -- res://scripts/feedback/feedback_system_tests.gd
```

Cobre: hierarquia de tiers, perfis registrados, `AttackData` inalterado, partículas reduzidas, shake 0%, performance do pool.

---

## Garantias

- `AttackData` `.tres` — dano, `startup_time`, `active_time`, `recovery_time`, `hitbox_size`, `hitbox_offset` **não modificados**.
- Hitstop de gameplay — continua em `AttackData`; `HitboxComponent._request_hitstop()` inalterado em lógica.
- Nenhum golpe novo criado.
