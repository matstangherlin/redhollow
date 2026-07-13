# Street Art — Screenshot Checklist

Checklist de captura para validar a rua north-star antes de promover arte final ou trocar a demo principal.

Salvar em `docs/screenshots/street_art/` (não versionar sem LFS).

## Preparação

- [ ] Godot 4.7, resolução **1920×1080**, stretch expand
- [ ] Cena: `scenes/tests/street_art_test.tscn` (F6)
- [ ] Alternar **ART PILOT** com **F**; comparar **GREYBOX**
- [ ] Overlay performance com **P** (anotar FPS / draw calls)

## Composição por camada

- [ ] **Sky** — sol visível, gradiente quente, glow Mol-Khar sutil
- [ ] **FarMountains** — parallax lento, cicatriz de mina
- [ ] **DistantTown** — skyline legível, torre distante
- [ ] **MidgroundBuildings** — profundidade sem poluir gameplay
- [ ] **GameplayGround** — terra + calçada + **4 plataformas** visíveis
- [ ] **GameplayStructures** — saloon + abandonado + toldo
- [ ] **Props** — postes, carroça, barris, cerca, vegetação seca
- [ ] **Interactables** — marcadores discretos (opcional ocultar antes de captura final)
- [ ] **Lighting** — lanternas quentes, janelas saloon, Vermilite contida
- [ ] **Atmosphere** — poeira sem obscurecer personagens
- [ ] **Foreground** — silhueta sem bloquear leitura de combate

## Gameplay overlay (ART PILOT)

- [ ] Calder legível contra pôr do sol
- [ ] Diálogo com Elias (sem labels debug)
- [ ] Pista / interação chão
- [ ] Combate brawler — telegraphs legíveis
- [ ] Rota elevada (plataformas A/B/C + retorno)
- [ ] Duo gate + encontro opcional
- [ ] Segredo / cache
- [ ] Saída igreja
- [ ] Mapa (M) — HUD não conflita com cantos da arte
- [ ] Morte + respawn

## Comparação greybox

- [ ] Captura GREYBOX mesma posição câmera
- [ ] Captura ART PILOT mesma posição
- [ ] Toggle F em vídeo curto (10 s) se possível

## Performance (anotar na captura)

- [ ] FPS ≥ 58 médio (exploração 30 s)
- [ ] FPS ≥ 55 durante combate brawler
- [ ] Draw calls ≤ 80
- [ ] Sem hitch no primeiro ataque
- [ ] Memória estável após 2 transições (se testar via demo)

## Identidade

- [ ] Faroeste decadente legível
- [ ] Vermilite presente mas **não** domina a cena
- [ ] Culto sugerido (estátua, coração, placas)
- [ ] Nenhum elemento copiado de referência externa reconhecível

## Entrega

| Arquivo sugerido | Conteúdo |
| --- | --- |
| `street_art_wide_sunset.png` | vista geral spawn |
| `street_art_saloon_mid.png` | saloon + calçada |
| `street_art_combat.png` | brawler em combate |
| `street_art_elevated.png` | rota plataformas |
| `street_art_greybox_compare.png` | colagem F toggle |
| `street_art_perf_overlay.png` | com monitor P |

## Aprovação

- [ ] Lead arte
- [ ] Lead design (gameplay preservado)
- [ ] Playtest manual Capítulo Zero
