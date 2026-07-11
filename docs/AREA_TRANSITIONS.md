# Area Transitions — Red Hollow

## Decision

Red Hollow uses a **persistent shell scene** (`scenes/core/game.tscn`) with **area swapping inside `WorldHost`**.

We do **not** use full `change_scene_to_file()` for every transition.

## Why

| Approach | Pros | Cons |
|----------|------|------|
| **Persistent shell + swap area** (chosen) | Single Calder, camera, HUD, SaveManager, StyleManager; health/Red Brand stay on player nodes; fast iteration | Requires explicit rebinding after each area load |
| **Full scene change** | Simple isolation per area | Duplicates or rebinds player/systems; easy to lose runtime state |

This matches the prototype architecture in `docs/ARCHITECTURE.md` and avoids duplicating controllers.

## Scene layout

```
Game (persistent)
├── HitstopController
├── StyleManager + StyleHud
├── RedBrandDirector
├── ProgressionSystem
├── DialogueSystem
├── SaveManager
├── AreaTransitionManager
├── WorldHost            ← only current area lives here
├── Player               ← never duplicated
└── CameraController     ← never duplicated
```

## Area scenes

Each area under `scenes/areas/`:

- extends `AreaRoot` with unique `area_id`
- `camera_limits`, `fall_recovery_y`
- `AreaSpawnPoint` markers (`spawn_id`)
- `AreaExit` triggers (`target_scene`, `target_spawn_id`, `transition_type`)
- provisional gray visuals + solids

Current test chain:

1. `street_test` → right exit → `church_entrance_test`
2. `church_entrance_test` → left exit → `street_test` (return)
3. `church_entrance_test` → right exit (past Red Brand barrier) → `underground_test`
4. `underground_test` → left exit → `church_entrance_test` (return)

## Transition flow

1. Player enters `AreaExit`
2. `AreaTransitionManager` locks player (`enter_transition_mode`)
3. Short pause (instant/fade placeholder)
4. Current area is freed from `WorldHost`
5. New area instanced
6. Player placed at `target_spawn_id`
7. Camera limits updated + snap
8. Systems rebound (save checkpoints, style enemies)
9. Player unlocked

## Persistence

- **Health / Red Brand** remain on the persistent `Player` node.
- **Barriers / progression** remain in global `ProgressionSystem`.
- **Save** stores `current_scene` as the **area scene path** (e.g. `res://scenes/areas/street_test.tscn`).
- **No auto-save on area transition** — only checkpoints and debug save (F8).

## Future gates

`AreaExit` supports:

- `required_ability_id`
- `required_flag`

Underground includes a locked exit requiring `dash` as a placeholder.

## Not in scope

- Streaming / multi-chunk loading
- Keeping multiple areas loaded simultaneously
- Full fade UI (transition type enum is ready)
