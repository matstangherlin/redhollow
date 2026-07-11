# Red Hollow — Art Bible

Direção visual definitiva para arte final. Complementa `VISUAL_REFERENCE_RULES.md`.

## Visão geral

Red Hollow é um metroidvania de ação 2D lateral em **pixel art detalhada**.

A identidade combina:

- faroeste decadente;
- terror religioso;
- arquitetura de madeira e pedra;
- minas, saloons, igrejas, catacumbas;
- instalações industriais e ruínas cerimoniais;
- anime na construção de personagens e transformações;
- violência estilizada;
- iluminação dramática;
- cenários com grande profundidade visual.

## Pixel art — requisitos

- alto nível de detalhe sem perder legibilidade;
- silhuetas claras em escala de gameplay;
- animações expressivas e rápidas no combate;
- contraste forte entre personagens e fundo;
- iluminação atmosférica (lampiões, fogo, Vermilite, sombras);
- texturas legíveis: madeira, poeira, pedra, metal, tecido;
- parallax com moderação — gameplay primeiro.

## Paleta conceitual

| Função | Cores |
| --- | --- |
| Sombra profunda | preto, cinza muito escuro |
| Cidade e madeira | marrom, ocre, sépia |
| Distância / névoa | cinza esverdeado ou acinzentado |
| Calor / lampiões / fogo | laranja quente |
| Poder, culto, corrupção | **vermelho Vermilite** (uso controlado) |
| Sagrado distorcido | tons pálidos, osso, cera |

**Vermilite** é o principal destaque cromático. Não cobrir a tela constantemente.

Indica:

- perigo;
- influência de Mol-Khar;
- energia da Red Brand;
- corrupção;
- barreiras;
- elementos importantes de gameplay.

Fundo e estruturas permanecem terrosos e dessaturados para o vermelho “pulsar” com intenção.

## Calder Knox

- sobretudo ou casaco longo;
- chapéu ou silhueta de pistoleiro, se mantido no design final;
- **mão direita** visualmente marcada (Red Brand);
- pose de combate agressiva;
- animações rápidas;
- silhueta reconhecível em sprite pequeno.

### Red Brand (visual)

Afeta **somente braço e mão** inicialmente.

Evitar:

- armadura genérica de fantasia;
- partículas permanentes que escondem animação;
- aparência de mago;
- ataques elementais visuais;
- glow que obscurece frames de golpe.

Estados visuais sugeridos: repouso (marca sutil), carga (Vermilite no antebraço), release (flash curto no impacto).

## Inimigos — arquétipos

Combinar profissões do faroeste com a Ordem. Cada arquétipo precisa de:

- silhueta própria;
- função mecânica clara;
- arma ou estilo físico coerente;
- elemento da Ordem;
- grau de corrupção visível.

| Arquétipo | Notas |
| --- | --- |
| Caçador rubro | Perseguidor, rifle ou faca, marca cultista |
| Fanático | Agressivo, pouca defesa, gritos/ritual |
| Carrasco | Golpes pesados, ameaça de execução |
| Pistoleiro da Ordem | Distância curta, duelo |
| Sacerdote | Suporte, bênçãos, zona de pressão |
| Justiceiro | Controle de espaço, punição |
| Mineiro alterado | Corpo deformado por Vermilite |
| Guarda industrial | Armadura leve, ferramentas |
| Penitente | Autodano ritual, área perigosa |

**Não criar todos para a beta.** A demo técnica atual usa **Cult Brawler** (greybox); a beta terá três inimigos visuais finais + Deacon Rusk.

## Cenários — camadas

Ordem de prioridade: **leitura de plataformas, inimigos e interativos** > detalhe decorativo.

Camadas sugeridas:

1. **foreground** — detalhes próximos, ocasional parallax leve;
2. **plano jogável** — colisão, plataformas, props funcionais;
3. **estruturas intermediárias** — vigas, grades, altares;
4. **background** — silhueta urbana, minas, cruzes distorcidas;
5. **céu / profundidade** — gradiente, fumaça, poeira;
6. **partículas atmosféricas** — cinzas, fagulhas, pó de mina.

## Corrupção ambiental

Duas variantes por região quando necessário:

| Aspecto | Normal / decadente | Corrompido (Ressonância Rubra) |
| --- | --- | --- |
| Iluminação | Lampiões quentes, sombras longas | Vermilite, contraste duro |
| Vegetação | Seca, rachada | Retorcida, cristalizada |
| Cristais | Ausentes ou raros | Crescimento em paredes |
| Estátuas | Desgaste secular | Distorção religiosa |
| Inimigos | Humanos alterados levemente | Corrupção visível |
| Fundo | Poeira e névoa | Pulsação rubra distante |

Arquitetura técnica: variantes por camada, não duplicação manual de mapa inteiro (ver `ARCHITECTURE.md`).

## Estado atual vs beta

| Item | Agora (greybox) | Beta |
| --- | --- | --- |
| Personagens | Formas geométricas | Pixel art final |
| Cenários | Blocos cinza | Rua, igreja, catacumbas ilustradas |
| UI | Placeholder funcional | `UI_BIBLE.md` |
| Efeitos | Cores sólidas | Partículas e luz controladas |
