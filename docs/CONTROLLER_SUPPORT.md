# Red Hollow — Controller Support

Suporte a teclado, XInput e controles genéricos reconhecidos pela Godot 4.7.

## Autoloads

| Autoload | Função |
| --- | --- |
| `InputSetup` | Registra mapeamentos gamepad no boot |
| `InputDeviceManager` | Detecta último dispositivo; gera prompts visuais |

## Ações mapeadas

| Ação | Teclado (padrão) | Gamepad (XInput) |
| --- | --- | --- |
| `move_left` | A | Analógico esquerdo ← / D-Pad ← |
| `move_right` | D | Analógico esquerdo → / D-Pad → |
| `jump` | Espaço | A |
| `attack` | J | X |
| `dodge` | K | B |
| `counter` | L | Y |
| `interact` | E | A |
| `taunt` | T | RB |
| `special` | U (segurar) | RT (eixo) |
| `pause` | Esc | Start |

Mapeamentos adicionais são aplicados em runtime por `InputSetup` sem remover bindings de teclado existentes.

## Detecção de dispositivo

`InputDeviceManager` observa `_input`:

- Teclado / mouse → `KEYBOARD_MOUSE`
- Botão ou eixo gamepad → `GAMEPAD`

Emite `device_changed` quando o tipo muda.

## Prompts visuais

Componentes que consomem prompts:

- `InteractionDetector` — prompt de interação no HUD
- `Interactable` — indicador sobre NPC/objeto
- `DialogueBox` — avanço/fechar diálogo

API:

```gdscript
InputDeviceManager.get_action_prompt(&"interact")
InputDeviceManager.format_interaction_prompt("Falar")
InputDeviceManager.format_dialogue_advance_prompt(is_last_line)
```

Labels usam o último dispositivo ativo (`[E]` vs `[A]` vs `[Btn n]`).

## Reconexão

`Input.joy_connection_changed` reverte para teclado se nenhum pad permanecer conectado.

## Teste manual

1. Menu principal com teclado — navegar botões, Enter.
2. In-game — verificar prompts `[E]` no mundo.
3. Conectar gamepad — pressionar A; prompts devem mudar para `[A]`.
4. Pausa com Start; retomar com Start ou botão Continuar.
5. Opções — sliders com analógico (foco UI padrão Godot).

## Limitações beta

- Ícones de botão são texto (A/B/X/Y), não glifos por fabricante.
- Switch/PlayStation usam índices compatíveis via camada Godot, mas labels exibem layout Xbox.
- Vibração: opção salva em settings; feedback háptico ainda não wired a combate.
