# Red Hollow — Save Compatibility

Política de compatibilidade de saves para beta local **0.2.0-beta.1**.

**Ver também:** `BOOT_AND_SAVE_POLICY.md` (fluxo Novo Jogo / Continuar / corrompido).

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
| Arquivo pré–Novo Jogo | `user://saves/slot_01.save.archive.json` |
| Temp atômico | `user://saves/slot_01.save.tmp` |
| Settings | `user://settings.json` |

No Windows exportado, `user://` mapeia para `%APPDATA%/Godot/app_userdata/Red Hollow/`.

## Regras de compatibilidade (`inspect_slot`)

| Situação | Status | Continuar | Comportamento |
| --- | --- | --- | --- |
| Arquivo ausente | `none` | Off | Novo Jogo direto |
| JSON inválido (sem backup válido) | `corrupted` | Off | Mensagem + oferecer Novo Jogo |
| Primary inválido + backup válido | `valid` (`source=backup`) | On | Load usa `.bak` |
| Campos faltando | `corrupted` | Off | Novo Jogo |
| `save_version` &gt; atual | `corrupted` | Off | Novo Jogo |
| `save_version` &lt; atual | `incompatible` | Off | Novo Jogo (migração futura) |
| Manifesto / área fora do `beta_demo` | `incompatible` | Off | Novo Jogo |
| Schema + manifesto + área OK | `valid` | On | Continuar |

`inspect_slot` valida manifesto/`current_scene` contra `beta_demo` mesmo no menu (ativa registry temporário se necessário).

## Campos obrigatórios (v1)

Ver `SaveData.REQUIRED_FIELDS`:

- `save_version`, `current_scene`, `checkpoint_id`, `checkpoint_position`
- `player_max_health`, `player_current_health`, `red_brand_energy`
- `unlocked_abilities`, `destroyed_barriers`, `narrative_flags`
- `activated_checkpoints`, `settings`

## Campos opcionais (v1)

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `content_manifest_id` | String | `beta_demo` ou `full_game` |
| `chapter_id` | String | ex.: `chapter_zero_bell_before_nightfall` |
| `world_map` | Dictionary | Áreas descobertas / UI de mapa |

Saves **sem** `content_manifest_id` permanecem válidos se `current_scene` estiver no manifesto ativo.

## Política beta → jogo final

| Cenário | Comportamento |
| --- | --- |
| Save greybox sem `content_manifest_id` | Compatível se a cena salva estiver no manifesto ativo |
| Save `beta_demo` aberto em `full_game` | **Bloqueado** (`migrate_beta_saves_to_full = false`) |
| Migração futura | Exigir flag + migrador explícito antes do ship |

**Decisão:** saves da beta **não** migram automaticamente para `full_game`.

Runtime: `ContentRegistry.is_save_compatible_with_manifest()`.

## Novo Jogo e arquivo

Antes de limpar o slot, `SaveManager.archive_and_clear_slot()`:

1. Copia primary válido (senão backup; senão primary bruto) → `.save.archive.json`.
2. Remove `.save.json`, `.save.tmp`, `.save.bak`.
3. Não usa o arquivo de archive como fonte de Continuar.

## Backup em write

`create_backup()` / `_write_save_file`:

- Só copia primary → `.bak` se o primary **passar** validação.
- Primary corrompido **não** sobrescreve um `.bak` bom.

`load_game`: tenta primary; se vazio/inválido, tenta `.bak`. Falha **não** chama `create_new_save()` nem apaga arquivos.

## Bump de versão

1. Incrementar `SaveData.CURRENT_SAVE_VERSION`.
2. Espelhar em `GameVersion.SAVE_FORMAT_VERSION`.
3. Migrador em `SaveManager` / `SaveData`.
4. Atualizar este doc + `BOOT_AND_SAVE_POLICY.md` + checklist.
5. Testes: `save_tests.gd`, `product_shell_tests.gd`.

## Settings vs save

Settings são independentes do slot. Corrupção de settings → defaults; não apaga save.

## Testes automatizados

- `save_tests.gd` — roundtrip, backup, corrupção, archive, no clobber backup
- `product_shell_tests.gd` — `inspect_slot` none/valid/corrupted/incompatible + boot consume
- `content_registry_tests.gd` — manifesto e gate de áreas
