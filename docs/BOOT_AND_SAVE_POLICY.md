# Boot and Save Policy — Beta `0.2.0-beta.1`

Política definitiva de inicialização e carregamento. Fonte de verdade para menu, `GameBootState`, `ProductShell` e `SaveManager`.

**Ver também:** `SAVE_COMPATIBILITY.md`, `MANUAL_PLAYTHROUGH_CHECKLIST.md`, decisões **D-010…D-013**.

---

## Princípio

| Quem decide | Responsabilidade |
| --- | --- |
| **Menu principal** | Novo Jogo / Continuar; confirmações; mensagens de save inválido |
| **GameBootState** | Intenção one-shot (`NEW_GAME` / `CONTINUE`) + manifesto ativo |
| **ProductShell** | Consome boot e executa a política |
| **SaveManager** | Persistência, validação, backup, arquivo de arquivo |
| **Cena de gameplay** | **Não** decide Novo Jogo vs Continuar; `auto_load_on_ready = false` |

Fluxo:

```
main_menu → GameBootState.set_new_game / set_continue_game
         → change_scene(vertical_slice_greybox)
         → game.gd (ativa beta_demo, bind SaveManager sem auto-load)
         → ProductShell._run_boot_sequence
```

---

## Novo Jogo

1. Se existir progresso (`inspect_slot` ≠ `none`): pedir confirmação.
2. Se status `corrupted`: diálogo amigável + oferta de Novo Jogo (não força Continuar).
3. Arquivar save atual em `user://saves/slot_01.save.archive.json` (preferir primary válido; senão backup; senão cópia do primary corrompido **sem** destruir `.bak` antes do clear).
4. Limpar primary, temp e backup do slot.
5. Manifesto: `beta_demo`.
6. Iniciar Capítulo Zero na rua (`vs_greybox_street` / `vertical_slice_street_art.tscn`).
7. Limpar flags narrativas, mapa descoberto, checkpoints ativados, barreiras.
8. Calder: vida padrão, Red Brand 0, estilo reset.
9. Gravar novo save inicial em disco (`create_new_save(true)`).

Implementação: `MainMenuController` → `GameBootState.set_new_game()` → `ProductShell._boot_new_game()` → `VerticalSliceController.return_to_start(true)`.

---

## Continuar

1. Botão habilitado **somente** se `inspect_slot` → `valid`.
2. Validação inclui:
   - JSON / schema (`SaveData.validate`);
   - `save_version` compatível;
   - manifesto / `content_manifest_id` vs `beta_demo`;
   - `current_scene` carregável no manifesto.
3. Runtime `load_game()` restaura:
   - área e posição;
   - checkpoint / checkpoints ativados;
   - flags;
   - barreiras destruídas;
   - mapa descoberto (`world_map`);
   - vida e Red Brand.
4. Falha de load: aviso, retorno ao menu (**não** apaga o slot; **não** cria save fresco em disco).

---

## Save corrompido

| Regra | Comportamento |
| --- | --- |
| Crash | Proibido — falhas viram status / warning |
| Backup | `load_game` tenta `.bak` se primary inválido |
| Menu | Mensagem amigável; Continuar desabilitado; oferecer Novo Jogo |
| Backup no write | **Não** sobrescrever `.bak` copiando primary inválido |

---

## Auto-load

- `SaveManager.auto_load_on_ready` default = **`false`**.
- Greybox e `game.gd` reforçam `false`.
- Sem intenção em `GameBootState` (abrir cena no editor): sessão de rua **sem** carregar disco e **sem** apagar slot (`return_to_start(false)`).

---

## Debug F8 / F9

| Build | Comportamento |
| --- | --- |
| Debug (`OS.is_debug_build()`) | F8 grava / F9 carrega; prompt no log |
| Release | Hotkeys ignoradas; fluxo normal = menu + checkpoint |

Não use F8/F9 como caminho obrigatório da beta.

---

## Checkpoint

Ao ativar:

1. Registrar checkpoint na progressão.
2. Aplicar restore de vida / Red Brand (por export do checkpoint).
3. `save_game()` síncrono com write atômico + backup do primary **válido**.
4. Não pausar o jogo com tela de loading — write JSON de slot é pequeno.

---

## Casos cobertos

| Caso | Expectativa |
| --- | --- |
| Primeiro boot / sem save | Continuar off; Novo Jogo direto |
| Novo Jogo | Confirma se houver slot; arquiva; rua; defaults |
| Continuar válido | Restaura estado completo |
| Corrompido + backup válido | Continuar possível via backup |
| Corrompido sem backup | Continuar off; Novo Jogo |
| Versão / manifesto / área inválidos | `incompatible`; Novo Jogo |
| Checkpoint inexistente no load | Área/posição do save; visuals sincronizam o que existir |
| Morte após load | Respawn pelo serviço / checkpoint salvos |
| Load antes/depois barreira ou boss | Flags e `destroyed_barriers` / boss flags restauradas |
| Voltar ao menu | `ProductShell.return_to_main_menu_from_game` |
| Novo Jogo após concluir beta | Confirmação + arquivo + reset |

---

## Testes

- `scripts/product/product_shell_tests.gd`
- `scripts/save/save_tests.gd`
- Checklist manual: `MANUAL_PLAYTHROUGH_CHECKLIST.md` seções A e H
