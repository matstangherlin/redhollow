# Red Hollow — Build Instructions (Windows local beta)

Build **local** para QA interno. **Não** publicar na Steam nem distribuir publicamente sem gate completo.

## Versões canônicas

| Campo | Valor | Fonte |
| --- | --- | --- |
| Jogo | `0.2.0-beta.1` | `project.godot` → `config/version`, `GameVersion.GAME_VERSION` |
| Save | `1` | `SaveData.CURRENT_SAVE_VERSION` |
| Settings | `1` | `SettingsData.CURRENT_SETTINGS_VERSION` |
| Engine | Godot **4.7** | `project.godot` → `config/features` |
| Canal | `local-beta` | `GameVersion.BUILD_CHANNEL` |

## Pré-requisitos

1. **Godot 4.7** instalado (editor ou export templates embutidos).
2. **Export templates Windows** instalados no Godot (Editor → Manage Export Templates).
3. Repositório em estado conhecido; anote `git rev-parse HEAD`.
4. Suíte headless executada (ver abaixo).

## Export presets

Arquivo: `export_presets.cfg`

| Preset | Saída | Uso |
| --- | --- | --- |
| **Windows Beta Debug** | `builds/windows/red-hollow-0.2.0-beta.1-debug.exe` | Console, diagnóstico, QA técnico |
| **Windows Beta Release** | `builds/windows/red-hollow-0.2.0-beta.1-release.exe` | Jogadores internos (sem console) |

A pasta `builds/` está no `.gitignore`.

## Script automatizado (recomendado)

```powershell
cd C:\Users\Stan\Documents\red-hollow
.\tools\build_windows.ps1 -GodotExe "C:\Users\Stan\Documents\Godot_v4.7-stable_win64.exe"
```

Opções:

| Flag | Efeito |
| --- | --- |
| `-SkipTests` | Pula `test_runner.gd` (não recomendado) |
| `-DebugOnly` | Só export debug |
| `-ReleaseOnly` | Só export release |

Manifest gerado: `builds/windows/build-manifest.json` (versão, commit, resultado dos testes, `qa_release_approved`).

Exit code `2` = build exportou, mas **testes falharam** — release **não aprovada**.

## Manual (Godot CLI)

```powershell
# 1. Testes
& "C:\Path\To\Godot.exe" --headless --path . --script res://scripts/tests/test_runner.gd

# 2. Import
& "C:\Path\To\Godot.exe" --headless --path . --import

# 3. Export
& "C:\Path\To\Godot.exe" --headless --path . --export-debug "Windows Beta Debug"
& "C:\Path\To\Godot.exe" --headless --path . --export-release "Windows Beta Release"
```

## Gate antes de marcar release “aprovada”

1. `test_runner.gd` → **17/17 PASS**, unexpected issues = 0 (allowlist documentada OK).
2. Playthrough manual (`BETA_RELEASE_CHECKLIST.md`) assinado.
3. Sem **P0** em `KNOWN_ISSUES.md`.
4. Performance dentro de `PERFORMANCE_BUDGET.md` na config de referência.
5. Save/load validado na build exportada (não só no editor).

## Alterações em `project.godot` (beta build)

- `config/version="0.2.0-beta.1"` — rótulo da build.
- `config/description` — Capítulo Zero beta local.

Main scene permanece `scenes/product/main_menu.tscn`.

## Limitação conhecida — testes headless

Suítes executadas com `--script` como `SceneTree` raiz **não carregam autoloads** da mesma forma que o jogo exportado. Isso pode falhar verificações de `SettingsManager` / `InputDeviceManager` no runner, mesmo com o jogo funcional no export.

**Validação definitiva:** build exportada + checklist manual.

## Distribuição interna

1. Copiar `.exe` + `build-manifest.json`.
2. Incluir `BETA_TEST_FORM.md` para feedback.
3. Não enviar para Steam, itch público ou links abertos.
