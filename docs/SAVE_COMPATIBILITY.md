# Red Hollow — Save Compatibility

Política de compatibilidade de saves para beta local **0.2.0-beta.1**.

## Versões

| Artefato | Versão atual | Campo JSON |
| --- | ---: | --- |
| Formato save | **1** | `save_version` |
| Settings | **1** | `settings_version` (em `user://settings.json`) |
| Jogo (rótulo) | **0.2.0-beta.1** | `GameVersion.GAME_VERSION` |

Fonte de verdade código:

- `scripts/save/save_data.gd` → `CURRENT_SAVE_VERSION`
- `scripts/settings/settings_data.gd` → `CURRENT_SETTINGS_VERSION`
- `scripts/product/game_version.gd` → `SAVE_FORMAT_VERSION`

## Localização

| Arquivo | Caminho |
| --- | --- |
| Save slot | `user://saves/slot_01.save.json` |
| Backup | `user://saves/slot_01.save.bak` |
| Settings | `user://settings.json` |

No Windows exportado, `user://` mapeia para `%APPDATA%/Godot/app_userdata/Red Hollow/`.

## Regras de compatibilidade

| Situação | `SaveManager.inspect_slot()` | Comportamento |
| --- | --- | --- |
| Arquivo ausente | `none` | Continuar desabilitado |
| JSON inválido | `corrupted` | Menu avisa; Novo Jogo |
| Campos faltando | `corrupted` | Idem |
| `save_version` &gt; atual | `corrupted` (inválido) | Novo Jogo |
| `save_version` &lt; atual | `incompatible` | Novo Jogo (migração futura) |
| `save_version` == atual | `valid` | Continuar habilitado |

## Campos obrigatórios (v1)

Ver `SaveData.REQUIRED_FIELDS`:

- `save_version`, `current_scene`, `checkpoint_id`, `checkpoint_position`
- `player_max_health`, `player_current_health`, `red_brand_energy`
- `unlocked_abilities`, `destroyed_barriers`, `narrative_flags`
- `activated_checkpoints`, `settings`

## Campos opcionais (v1 — content architecture)

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `content_manifest_id` | String | `beta_demo` ou `full_game` quando gravado |
| `chapter_id` | String | ex.: `chapter_zero_bell_before_nightfall` |

Saves **sem** esses campos (greybox antigo) permanecem válidos se `current_scene` estiver no manifesto ativo.

## Política beta → jogo final (decisão explícita)

| Cenário | Comportamento |
| --- | --- |
| Save greybox sem `content_manifest_id` | Compatível se a cena salva estiver em `playable_chapter_ids` do manifesto ativo |
| Save com `content_manifest_id = beta_demo` aberto em `full_game` | **Bloqueado** — `migrate_beta_saves_to_full = false` em `full_game.tres` |
| Migração futura | Definir `migrate_beta_saves_to_full = true` **e** implementar migrador antes de ship |

**Decisão atual (2026-07-11):** saves da beta **não** migram automaticamente para o perfil `full_game`. Jogador inicia novo jogo ou equipe implementa migrador explícito.

Validação em runtime: `ContentRegistry.is_save_compatible_with_manifest()`.

## Bump de versão (procedimento)

1. Incrementar `SaveData.CURRENT_SAVE_VERSION`.
2. Espelhar em `GameVersion.SAVE_FORMAT_VERSION`.
3. Implementar migração em `SaveManager` ou `SaveData.merge/migrate`.
4. Atualizar `SAVE_COMPATIBILITY.md` e `BETA_RELEASE_CHECKLIST.md`.
5. Testes: `save_tests.gd`, `product_shell_tests.gd`.

**Beta 0.2.0-beta.1:** primeira versão pública local — **sem** migrador de versões anteriores greybox manual (F8/F9 in-game).

## Settings vs save

Settings são independentes do slot. Corrupção de settings → `SettingsManager` usa defaults; não apaga save.

## Backup

`SaveManager.create_backup()` gera `.bak` antes de writes críticos. Load tenta backup se principal corrompido.

## Testes automatizados

- `save_tests.gd` — roundtrip, backup, corrupção
- `product_shell_tests.gd` — `inspect_slot` none/valid/corrupted
- `content_registry_tests.gd` — manifestos, gate de áreas, política beta/full
