# Red Hollow — Final Game Scope

Visão do **jogo completo**. Distinto da beta (`BETA_DEMO_SCOPE.md`) e da demo técnica greybox (`CURRENT_IMPLEMENTATION.md`).

## Visão

Metroidvania de ação 2D em pixel art detalhada. Calder explora Red Hollow, enfrenta barões e a Ordem, desvende o ritual da Red Brand e o papel de Mol-Khar, enquanto a mineração de Vermilite enfraquece o selo sob a cidade.

## Pilares

- combate corpo a corpo técnico e estilizado;
- exploração interligada com backtracking;
- progressão por habilidades físicas e Red Brand;
- narrativa ambiental + diálogos curtos;
- terror religioso + faroeste decadente;
- humor agressivo de Calder;
- Ressonância Rubra — sem magia elemental genérica.

## Estrutura narrativa provisória

Ordem macro sujeita a ajuste de produção; cada arco deve reforçar pactos, culpa e custo da Red Brand.

| Arco | Conteúdo |
| --- | --- |
| **Prólogo** | Ritual infantil de Calder; origem incompleta da Red Brand |
| **Capítulo Zero** (beta) | O Sino Antes do Anoitecer — Rusk, primeira exposição ao culto |
| **Silas Crow** | Vigilância, execuções, medo institucionalizado |
| **Rosa “La Serpiente”** | Charme, veneno social, traições e duelos sujos |
| **Magnus Vane** | Minas, máquinas, dependência industrial da Vermilite |
| **Arcturus Vale** | Teologia da dor; primeira derrota → **Arcturus, Arauto de Mol-Khar** |
| **Palácio Rubro** | Clímax urbano/cerimonial antes do confronto final |
| **Confronto Mol-Khar** | Enfraquecimento do selo; receptáculo; presença física |
| **Finais** | Variantes ligadas ao uso excessivo da Red Brand e decisões morais de Calder |

## Mundo

- Red Hollow em múltiplos distritos conectados;
- minas, trilhos, igrejas, catacumbas, instalações industriais;
- variantes de corrupção (Ressonância Rubra) por camadas;
- atalhos e portas por habilidade/flag.

## Combate e progressão

- socos, chutes, agarrões, esquivas, counters, provocações;
- técnicas Red Brand desbloqueáveis (teto narrativo: físico + sobrenatural justificado);
- chefes com fases testáveis;
- sistema de estilo;
- flags, barreiras, checkpoints persistentes.

## Interface e áudio

- HUD completo, mapa metroidvania, diário, lore;
- menus pausa/opções/Red Brand (`UI_BIBLE.md`);
- trilha por distrito e estado de corrupção;
- SFX combate legíveis.

## Base técnica já existente

| Entrega | Estado |
| --- | --- |
| Shell + troca de áreas | Implementado |
| Player combate completo | Implementado (dívida) |
| Save, progressão, barreiras | Implementado |
| Arco demo rua → igreja → sub → Rusk | Implementado |
| GameplayLockManager + testes | Implementado (dívida) |
| Pixel art / cidade completa / barões / Palácio | Planejado |

## Fora do escopo (nunca)

- magia tradicional elemental;
- voo livre;
- projéteis mágicos genéricos;
- MMO, gacha, crafting infinito;
- cópia de IPs de referência.

## Marcos sugeridos

1. Beta — Capítulo Zero  
2. Vertical slice visual — uma área + um chefe com arte final  
3. Alpha — distrito expandido + primeiro barão  
4. Conteúdo completo — todos arcos + finais  

Produção: `CONTENT_PRODUCTION_PLAN.md`.
