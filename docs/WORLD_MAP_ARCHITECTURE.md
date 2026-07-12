# World Map — Arquitetura de mapa interligado

Red Hollow representa o mundo como um **grafo de áreas** (`WorldGraphData`), não como uma cena gigante.

## Componentes

| Componente | Caminho | Função |
| --- | --- | --- |
| `AreaData` | `scripts/content/area_data.gd` | Metadados + coordenadas + categoria visual |
| `AreaConnectionData` | `scripts/world/area_connection_data.gd` | Arestas (saídas, atalhos, requisitos) |
| `WorldGraphData` | `scripts/world/world_graph_data.gd` | Nós + conexões por manifesto |
| `WorldGraphFactory` | `scripts/world/world_graph_factory.gd` | Constrói beta (3 áreas) e full (13 regiões) |
| `WorldMapState` | `scripts/world/world_map_state.gd` | Persistência (descoberta, visitas, segredos…) |
| `WorldMapService` | `scripts/world/world_map_service.gd` | Runtime + integração com transições |
| `WorldMapView` | `scripts/ui/world_map_view.gd` | Mapa provisório (retângulos + linhas) |
| `ContentRegistry` | `scripts/content/content_registry.gd` | Carrega grafo via manifesto |

## Grafo textual — Beta (jogável)

```
[Centro / vs_greybox_street]
    | to_church
    v
[Distrito da Igreja / vs_greybox_church]
    | to_underground (req: cz_underground_reached)
    v
[Catacumbas / vs_greybox_underground]
    | to_church_entrance
    '--> (backtracking)

Atalhos (dados):
  church_shortcut_street (flag cz_church_shortcut_unlocked)
  street_secret_alley (segredo duo)
```

## Grafo textual — Full game (registros futuros)

Nós adicionais **sem arestas jogáveis** até implementação:

- `region_train_station` — Estação Ferroviária
- `region_prison` — Prisão
- `region_black_market` — Mercado Clandestino
- `region_cemetery` — Cemitério
- `region_vermilite_mine` — Mina Vermilite
- `region_industrial_complex` — Complexo Industrial
- `region_magnus_mansion` — Mansão de Magnus
- `region_crimson_church` — Igreja Rubra
- `region_crimson_palace` — Palácio Rubro
- `region_underground_altar` — Altar Subterrâneo

## Campos por área (`AreaData`)

| Campo | Uso |
| --- | --- |
| `area_id` | ID estável |
| `display_name` | Nome no mapa |
| `chapter_id` | Capítulo narrativo |
| `scene_path` | Cena jogável (vazio = bloqueado) |
| `map_position` | Coordenada no mapa (grid) |
| `visual_category` | street / church / underground / … |
| `checkpoint_ids` | Checkpoints da área |
| `secret_ids` | Segredos rastreados |
| `barrier_ids` | Barreiras Vermilite |
| `shortcut_ids` | Atalhos |
| `is_playable_in_build` | false para regiões futuras |

Conexões em `AreaConnectionData`: `from_exit_id`, `to_spawn_id`, `required_flag`, `required_ability_id`, `is_shortcut`, `is_secret_passage`.

## Persistência (`world_map` no save)

Salvo via `ProgressionComponent` — **sem referências de nós**:

- `discovered_areas`
- `visited_areas`
- `found_secrets`
- `unlocked_shortcuts`
- `known_barriers`
- `current_area_id`
- `objective_area_id`

## Mapa provisório (beta)

Tecla **M** na vertical slice greybox.

| Indicador | Visual |
| --- | --- |
| Sala atual | retângulo laranja |
| Visitada | tom mais claro |
| Objetivo | borda dourada |
| Checkpoint | ponto ciano |
| Barreira | marca vermelha |
| Segredo encontrado | ponto roxo |
| Passagem bloqueada | linha escura |
| Atalho | linha tracejada |
| Não descoberta | **oculta** |

## Manifestos

| Manifesto | Grafo | Jogável |
| --- | --- | --- |
| `beta_demo.tres` | `beta_world_graph.tres` | Capítulo Zero (3 áreas) |
| `full_game.tres` | `full_game_world_graph.tres` | Ch. Zero + 10 nós bloqueados |

Sem condicionais `if demo` espalhados — consultar `ContentRegistry.get_active()`.

## Fluxo para adicionar área

1. Criar cena `AreaRoot` com `area_id` estável.
2. Adicionar `AreaData` em `ChapterData.areas` com `scene_path` válido.
3. Registrar nó no `WorldGraphFactory` (coordenada, categoria, segredos/barreiras).
4. Adicionar `AreaConnectionData` **somente** se a transição for jogável.
5. Colocar `AreaExit` na cena com `exit_id` / `target_scene` / `target_spawn_id`.
6. Verificar `ContentRegistry.can_load_area_scene()`.
7. Testar descoberta + backtracking + save/load.

## Testes

```powershell
$env:RH_TEST_SUITE="res://scripts/world/world_map_graph_tests.gd"
godot --headless --main-scene res://scenes/tests/test_bootstrap.tscn
```

Cobre: descoberta, transição, backtracking, bloqueio por flag, save/load, objetivo, mapa oculto, manifestos beta/full.

## Documentos relacionados

- `MODULAR_ENVIRONMENT_KIT.md`, `AREA_TRANSITIONS.md`, `CONTENT_PRODUCTION_PLAN.md`
