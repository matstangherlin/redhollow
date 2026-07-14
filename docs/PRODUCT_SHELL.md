# Red Hollow — Product Shell

Camada de produto da beta pública: boot, menus, pausa, configurações e fluxo de save separado de preferências.

## Boot flow

```
main_menu.tscn (main scene)
  ├─ Novo Jogo → GameBootState.NEW_GAME → vertical_slice_greybox.tscn
  ├─ Continuar → GameBootState.CONTINUE → vertical_slice_greybox.tscn
  └─ Opções / Créditos / Sair

vertical_slice_greybox.tscn
  └─ ProductShell
       ├─ boot (loading screen)
       ├─ PauseMenu (Esc / Start)
       └─ integração SaveManager + GameplayLockManager
```

## Arquivos principais

| Componente | Cena / script |
| --- | --- |
| Menu principal | `scenes/product/main_menu.tscn`, `main_menu_controller.gd` |
| Pausa | `scenes/ui/pause_menu.tscn`, `pause_menu_controller.gd` |
| Opções | `scenes/ui/options_menu.tscn`, `options_menu.gd` |
| Créditos | `scenes/ui/credits_screen.tscn` |
| Confirmação | `scenes/ui/confirmation_dialog.tscn` |
| Carregamento | `scenes/ui/loading_screen.tscn` |
| Shell in-game | `product_shell.gd` |
| Boot intent | autoload `GameBootState` |
| Settings | autoload `SettingsManager` |
| Input device | autoload `InputDeviceManager`, `InputSetup` |

## Menu principal

- **Novo Jogo:** confirma se houver qualquer progresso; arquiva slot (`archive_and_clear_slot`); reset via `return_to_start(true)` e grava save inicial.
- **Continuar:** habilitado só com `inspect_slot` → `valid` (versão + manifesto + área); falha devolve ao menu sem apagar o slot.
- Save corrompido: mensagem amigável + oferta de Novo Jogo (backup preservado no write).
- **Opções / Créditos / Sair:** overlays sobre o menu.

Política completa: `docs/BOOT_AND_SAVE_POLICY.md`.

## Pausa

- Adquire **somente** `LockReason.PAUSE` via `GameplayLockManager`.
- Não libera locks de diálogo, morte, transição, loading ou completion.
- Hitstop continua (marker-only, `PROCESS_MODE_ALWAYS`).
- Opções embutidas; retorno ao menu com confirmação.
- Bloqueada durante: morte, loading, transição, completion, diálogo.

## Persistência

| Arquivo | Conteúdo |
| --- | --- |
| `user://settings.json` | Vídeo, áudio, acessibilidade |
| `user://saves/slot_01.save.json` | Progresso da campanha |
| `user://saves/slot_01.save.bak` | Backup de write |
| `user://saves/slot_01.save.archive.json` | Cópia pré–Novo Jogo |

Settings **não** são mesclados ao save de campanha (schema separado).  
`auto_load_on_ready = false` — boot só via GameBootState (D-013 resolvida).

## Autoloads (`project.godot`)

- `SettingsManager`
- `GameBootState`
- `InputDeviceManager`
- `InputSetup` (mapeamentos gamepad)

## Áudio

Bus layout: `default_bus_layout.tres` — Master, Music, SFX, Voice, UI, Ambience.

## Testes

```bash
godot --headless --path . --script res://scripts/product/product_shell_tests.gd
```

Incluído no `test_runner.gd` como suíte `product_shell_tests`.

Ver também: `CONTROLLER_SUPPORT.md`, `ACCESSIBILITY.md`, `SETTINGS_FORMAT.md`.
