# Street Art — Screenshot Checklist

Use ao validar a vertical slice visual da rua. Salvar em `docs/screenshots/street_art/` (não versionar PNGs grandes sem LFS).

## Setup

- [ ] Abrir `scenes/tests/street_art_test.tscn` ou greybox com `vertical_slice_street_art.tscn`
- [ ] Resolução janela: 1920×1080
- [ ] Stretch: canvas_items + expand (padrão do projeto)
- [ ] Filtro Nearest ativo nos imports

## Camadas

- [ ] **Céu** — gradiente pôr do sol legível
- [ ] **Montanhas** — parallax visível ao mover câmera
- [ ] **Silhueta cidade** — separada das montanhas
- [ ] **Prédios médios** — profundidade entre fundo e chão
- [ ] **Chão** — alinhado à colisão (pés de Calder em Y≈848)
- [ ] **Calçada** — faixa de madeira acima do chão
- [ ] **Props** — saloon, prédio, carroça, barris, cercas, estátua
- [ ] **Placas e postes** — legíveis em 480p lógico
- [ ] **Lampiões** — PointLight2D visível ao anoitecer
- [ ] **Foreground** — viga/véu sem bloquear gameplay
- [ ] **Poeira** — partículas sutis, não excessivas

## Gameplay overlay

- [ ] Calder move/pula/ataca com arte ativa
- [ ] Elias interação [E]
- [ ] Brawler + combate
- [ ] Rota elevada opcional (gunslinger)
- [ ] Transição → igreja (exit direita)
- [ ] F alterna greybox ↔ art sem quebrar colisão

## Comparação greybox

| Captura | Nome arquivo sugerido |
| --- | --- |
| Vista wide art | `street_wide_art.png` |
| Vista wide greybox | `street_wide_greybox.png` |
| Spawn + Elias | `street_spawn_elias.png` |
| Saloon + estátua | `street_saloon_statue.png` |
| Pôr do sol + lanternas | `street_sunset_lights.png` |
| Combate brawler | `street_combat_brawler.png` |

## Performance (opcional)

- [ ] Draw calls ≤ 80
- [ ] FPS estável 60 na rua art
- [ ] Partículas ≤ 180

## Assinatura

| Campo | Valor |
| --- | --- |
| Data | |
| Build / commit | |
| Aprovado | SIM / NÃO |
| Observações | |
