# Playtest Visual Form — Art Vertical Slice (Rua North Star)

Formulário para gate `ART_VERTICAL_SLICE_GATE.md`.  
**Versão:** 2026-07-13  
**Build testada:** _______________  
**Resolução:** _______________  
**Dispositivo:** Teclado / Controle (círculo)  
**HUD:** V2 / Legado (F3)  
**Acessibilidade ativa:** shake ___ / flashes ___ / partículas ___ / distorção ___

---

## Instruções para o facilitador

1. Usar demo principal: menu → Capítulo Zero → rua art (`vertical_slice_greybox.tscn`).  
2. Duração sugerida: **15–25 min** por sessão.  
3. Não explicar controles antes da sessão **“jogador novo”**.  
4. Registrar FPS com tecla **P** na rua (repouso + combate).  
5. Anexar screenshots ou notas à seção final.  
6. Cada perfil abaixo deve completar pelo menos **uma** sessão.

---

## Perfil A — Desenvolvedor

Conhece sistemas; valida técnica e regressões.

### Checklist técnico

| # | Item | OK | Falha | Notas |
| ---: | --- | :---: | :---: | --- |
| A1 | Elias visível e interativo | ☐ | ☐ | |
| A2 | Flag `cz_met_elias` após diálogo | ☐ | ☐ | |
| A3 | Exit igreja abre após flag | ☐ | ☐ | |
| A4 | Plataformas elevadas visíveis | ☐ | ☐ | |
| A5 | Cult Brawler sprite ativo (não só polígono) | ☐ | ☐ | |
| A6 | Counter **L** funciona (não cicla luz) | ☐ | ☐ | |
| A7 | HUD V2 não cobre centro da tela | ☐ | ☐ | |
| A8 | F8/F9 save/load na rua art | ☐ | ☐ | |
| A9 | Pausa durante combate/diálogo | ☐ | ☐ | |
| A10 | Performance overlay **P**: FPS ≥ 55 | ☐ | ☐ | FPS: ___ draw: ___ |
| A11 | Ciclo iluminação **'** sem crash | ☐ | ☐ | |
| A12 | Esquiva **K** no chão e no ar | ☐ | ☐ | |

### Perguntas (resposta 1–5 ou Sim/Não)

| Pergunta | Resposta |
| --- | --- |
| Entendeu para onde ir? | |
| Identificou inimigo? | |
| Entendeu quando atacar? | |
| Entendeu quando esquivar? | |
| Conseguiu ler o HUD? | |
| Percebeu Red Brand? | |
| Sentiu peso nos golpes? | |
| Reconheceu o faroeste? | |
| Percebeu o culto? | |
| Gostaria de continuar? | |

**Observações desenvolvedor:**  
_________________________________________________________________

---

## Perfil B — Jogador que nunca viu o jogo

Sem briefing de controles (máx. “é um metroidvania de ação”).

### Checklist observação (facilitador marca)

| # | Item | OK | Falha | Notas |
| ---: | --- | :---: | :---: | --- |
| B1 | Encontrou Elias sem hint em < 3 min | ☐ | ☐ | Tempo: ___ |
| B2 | Descobriu ataque básico | ☐ | ☐ | |
| B3 | Descobriu interação [E] | ☐ | ☐ | |
| B4 | Percebeu objetivo na HUD | ☐ | ☐ | |
| B5 | Chegou ao Cult Brawler | ☐ | ☐ | |
| B6 | Sobreviveu ou morreu com compreensão do telegraph | ☐ | ☐ | |
| B7 | Encontrou rota elevada (opcional) | ☐ | ☐ | |
| B8 | Tentou ir à igreja antes de Elias (bloqueio claro?) | ☐ | ☐ | |

### Perguntas (voz do jogador — transcrever)

| Pergunta | Resposta |
| --- | --- |
| Entendeu para onde ir? | |
| Identificou inimigo? | |
| Entendeu quando atacar? | |
| Entendeu quando esquivar? | |
| Conseguiu ler o HUD? | |
| Percebeu Red Brand? | |
| Sentiu peso nos golpes? | |
| Reconheceu o faroeste? | |
| Percebeu o culto? | |
| Gostaria de continuar? | |

**Frases espontâneas memoráveis:**  
_________________________________________________________________

---

## Perfil C — Jogador de metroidvania

Já jogou Hollow Knight, Ori, Metroid, etc.

### Checklist

| # | Item | OK | Falha | Notas |
| ---: | --- | :---: | :---: | --- |
| C1 | Leitura de plataformas vs fundo | ☐ | ☐ | |
| C2 | Fluxo rua → objetivo → área seguinte claro | ☐ | ☐ | |
| C3 | Combate legível em 480p lógico / upscale | ☐ | ☐ | |
| C4 | Rota secreta / elevada perceptível | ☐ | ☐ | |
| C5 | Ritmo combate vs exploração | ☐ | ☐ | |
| C6 | Comparação justa: “parece protótipo” vs “parece produto” | ☐ | ☐ | |

### Perguntas

| Pergunta | Resposta |
| --- | --- |
| Entendeu para onde ir? | |
| Identificou inimigo? | |
| Entendeu quando atacar? | |
| Entendeu quando esquivar? | |
| Conseguiu ler o HUD? | |
| Percebeu Red Brand? | |
| Sentiu peso nos golpes? | |
| Reconheceu o faroeste? | |
| Percebeu o culto? | |
| Gostaria de continuar? | |

**O que faltou vs metroidvania de referência (sem pedir cópia):**  
_________________________________________________________________

---

## Perfil D — Jogador com controle (gamepad)

`InputDeviceManager` deve mostrar prompts de controle.

### Checklist

| # | Item | OK | Falha | Notas |
| ---: | --- | :---: | :---: | --- |
| D1 | Prompts mudam para gamepad | ☐ | ☐ | |
| D2 | Movimento + pulo responsivos | ☐ | ☐ | |
| D3 | Combate (ataque, esquiva, counter) | ☐ | ☐ | |
| D4 | Interação e diálogo | ☐ | ☐ | |
| D5 | Pausa com botão Start/Options | ☐ | ☐ | |
| D6 | Mapa **M** acessível | ☐ | ☐ | |
| D7 | Red Brand (hold/tap conforme settings) | ☐ | ☐ | |
| D8 | Sem conflito deadzone / drift | ☐ | ☐ | |

### Perguntas

| Pergunta | Resposta |
| --- | --- |
| Entendeu para onde ir? | |
| Identificou inimigo? | |
| Entendeu quando atacar? | |
| Entendeu quando esquivar? | |
| Conseguiu ler o HUD? | |
| Percebeu Red Brand? | |
| Sentiu peso nos golpes? | |
| Reconheceu o faroeste? | |
| Percebeu o culto? | |
| Gostaria de continuar? | |

---

## Seção comum — Legibilidade visual

Marcar após sessão (qualquer perfil):

| Elemento | 1 ilegível — 5 excelente | Notas |
| --- | :---: | --- |
| Calder vs background | | |
| Cult Brawler | | |
| Gunslinger | | |
| Projéteis | | |
| Telegraphs | | |
| Plataformas chão | | |
| Plataformas elevadas | | |
| Porta / exit igreja | | |
| Story props | | |
| NPC Elias | | |
| Prompt [E] | | |
| Objetivo HUD | | |
| Vida | | |
| Red Brand | | |
| Estilo / rank | | |

---

## Seção comum — Movimento e combate

| Ação | Responsivo? | Legível? | Notas |
| --- | :---: | :---: | --- |
| Corrida | ☐ | ☐ | |
| Pulo / aterrissagem | ☐ | ☐ | |
| Combo 3 hits | ☐ | ☐ | |
| Esquiva | ☐ | ☐ | |
| Counter | ☐ | ☐ | |
| Dano recebido | ☐ | ☐ | |
| Knockback | ☐ | ☐ | |
| Morte / respawn | ☐ | ☐ | |

---

## Seção comum — Cenário (rua only)

| Critério | 1–5 | Notas |
| --- | :---: | --- |
| Repetição excessiva de módulos | | |
| Parallax (conforto / nausea) | | |
| Escala coerente | | |
| Perspectiva 2D | | |
| Density (vazio vs cheio) | | |
| Foreground (obstrui ação?) | | |
| Iluminação pôr do sol | | |
| Cores / paleta | | |
| Poluição visual | | |
| Leitura de rota principal | | |
| Leitura rota elevada | | |

---

## Performance (registro obrigatório G3)

| Cenário | FPS | Frame ms | Draw calls | Partículas | Luzes | Mem MB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Repouso rua início | | | | | | |
| Combate Brawler | | | | | | |
| Estado Mol-Khar (**'**) | | | | | | |
| Diálogo Elias | | | | | | |
| 1280×720 | | | | | | |
| 1920×1080 | | | | | | |

**Stutter perceptível?** Sim / Não — quando: _______________  
**Build Windows testada?** Sim / Não — caminho: _______________

---

## Consolidação do gate

| Métrica | Valor |
| --- | --- |
| Sessões completadas | A ☐ B ☐ C ☐ D ☐ |
| Média “gostaria de continuar” (1–5) | |
| Bloqueadores encontrados | |
| Recomendação | Aprovar ajustes / Reprovar / Escalar molde |

### Assinaturas

| Papel | Nome | Data |
| --- | --- | --- |
| Facilitador playtest | | |
| QA | | |
| Direção | | |

---

## Anexos

- [ ] Screenshot HUD V2  
- [ ] Screenshot combate Brawler  
- [ ] Screenshot performance (**P**)  
- [ ] Screenshot rota elevada  
- [ ] Notas de bugs (link issue / KI)
