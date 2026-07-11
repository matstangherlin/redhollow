# Red Hollow — Vertical Slice Test Plan

Demonstração técnica jogável: `vertical_slice_greybox.tscn`  
Duração estimada: **10–20 minutos** (primeiro jogador).

**Importante:** ao iniciar o jogo, **não há auto-load** de save. Use **F9** para carregar manualmente após **F8**.

## Controles

| Tecla | Ação |
| --- | --- |
| A / D | Mover |
| Espaço | Pular |
| J | Ataque / combo |
| K | Esquiva |
| L | Counter |
| T | Provocação |
| U (segurar/soltar) | Red Brand Breaker |
| E | Interagir / avançar diálogo |
| R | Reiniciar posição (spawn/checkpoint) |
| F7 | Voltar ao início da demonstração |
| F8 | Salvar |
| F9 | Carregar |
| F | Toggle debug hitboxes |
| Esc | Panic unlock (destravar locks) |

## Roteiro (início ao fim)

### 1. Rua inicial

1. Inicie o projeto (main scene greybox).
2. Confirme spawn inicial (x≈120).
3. Verifique HUD estilo e barra Red Brand.
4. Caminhe e leia rótulo de área.

**Esperado:** movimento fluido; câmera com limites.

### 2. Elias e diálogo

1. Interaja com Elias (**E**).
2. Avance linhas; ao terminar, mova/ataque.

**Esperado:** controles liberados; cooldown reopen (~250 ms).

### 3. Plataformas

1. Pule plataformas cinza.
2. Se cair, confirme recuperação por queda (teleporte spawn).

### 4. Cult Brawler (rua)

1. Enfrente brawler; teste J/K/L.
2. Derrote; observe estilo.

### 5. Transição igreja

1. Saída **→ Igreja** (direita).
2. Spawn coerente (`from_street`).

### 6. Arena (dois Cult Brawlers)

1. Zona ~x=720 — portas fecham.
2. Derrote ambos; portas abrem; bônus estilo.

### 7. Red Brand

1. Cristal Coração Rubro após arena.
2. Energia ≥ 30; segure/solte **U**.

### 8. Barreira Vermilite

1. Breaker destrói barreira rubra.
2. Acesse saída subterrâneo.

### 9. Subterrâneo

1. Ambiente escuro; limites câmera novos.

### 10. Checkpoint

1. Ative checkpoint verde (**E**).
2. **F8** salvar.

### 11. Deacon Rusk

1. Zona chefe ~x=520; HUD chefe.
2. Telegraphs amarelo/vermelho; fase 2 <50% HP.
3. Derrote — overlay conclusão.

### 12. Reinício

1. Leia overlay **Demonstração Técnica Concluída**.
2. **F7** volta ao início.

## Testes de persistência

1. Após barreira destruída + checkpoint, **F8**.
2. Feche e reabra o jogo — **não** deve auto-carregar.
3. Pressione **F9**.

**Esperado:** área/posição/barreira/checkpoint/flags de arena e chefe consistentes.

## Testes de recuperação

| Cenário | Tecla | Esperado |
| --- | --- | --- |
| Reinício área | R | Spawn/checkpoint |
| Início demo | F7 | Rua, progresso reset |
| Queda | Cair do mapa | Teleporte spawn |
| Softlock | Esc | Locks destravados (escape hatch) |

## Verificação automatizada

Na raiz do projeto:

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

Suíte mínima demo:

```bash
godot --headless --path . --script res://scripts/demo/vertical_slice_verification.gd
godot --headless --path . --script res://scripts/demo/vertical_slice_regression_tests.gd
```

Ver lista completa em `TEST_MATRIX.md`.

## Critérios de aceite

- [ ] Fluxo 10–20 min completo.
- [ ] Sistemas obrigatórios exercitados.
- [ ] Sem softlock conhecido.
- [ ] F8/F9 consistente; **sem** expectativa de auto-load no boot.
- [ ] HUD/diálogo não bloqueiam gameplay indevidamente.
