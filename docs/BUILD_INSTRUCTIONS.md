# Red Hollow — Build Instructions (Windows RC / local beta)

Build **local** para avaliação / QA. **Não** publicar na Steam nem distribuir publicamente sem classificação aprovada.

## Versões canônicas (RC1)

| Campo | Valor | Fonte |
| --- | --- | --- |
| Display | Red Hollow — Chapter Zero Beta RC1 | `GameVersion.DISPLAY_NAME` |
| Jogo | `0.2.0-beta.rc1` | `project.godot` → `config/version`, `GameVersion.GAME_VERSION` |
| Build number | `20260713.rc1` | `GameVersion.BUILD_NUMBER` |
| Save | `1` | `SaveData.CURRENT_SAVE_VERSION` |
| Settings | `1` | `SettingsData.CURRENT_SETTINGS_VERSION` |
| Manifest conteúdo | `beta_demo` | `resources/content/manifests/beta_demo.tres` |
| Engine | Godot **4.7** | `config/features` |
| Canal | `rc1-closed` | `GameVersion.BUILD_CHANNEL` |

## Pré-requisitos

1. **Godot 4.7** + export templates Windows.
2. Anote `git rev-parse HEAD`.
3. Preferir working tree limpa (RC1 packaging avisou tree suja).
4. Suíte headless (`test_runner.gd`) — **obrigatória** para `qa_release_approved: true`.

## Export presets

| Preset | Saída |
| --- | --- |
| **Windows Beta Debug** | `builds/windows/red-hollow-0.2.0-beta.rc1-debug.exe` |
| **Windows Beta Release** | `builds/windows/red-hollow-0.2.0-beta.rc1-release.exe` |

`builds/` está no `.gitignore`.

## Script automatizado

```powershell
cd C:\Users\Stan\Documents\red-hollow
.\tools\build_windows.ps1 -GodotExe "C:\Users\Stan\Documents\Godot_v4.7-stable_win64.exe"
```

| Flag | Efeito |
| --- | --- |
| `-SkipTests` | Pula runner (manifest `test_runner=skipped`) |
| `-DebugOnly` / `-ReleaseOnly` | Um preset |
| `-SkipZip` | Não gera ZIP portátil |

Saídas típicas:

- `build-manifest.json`
- `red-hollow-0.2.0-beta.rc1-<short>-portable.zip` (release + pck + README)

Exit `2` = exportou, mas **testes falharam** — classificação permanece **REPROVADA**.

## Gate antes de aprovar

1. Runner **43/43 PASS**, unexpected = 0 (allowlist documentada OK).
2. Playthrough assinado (`BETA_RELEASE_CHECKLIST.md` / `BETA_PLAYTHROUGH_REPORT.md`).
3. **Zero P0** em `KNOWN_ISSUES.md`.
4. Performance medida na release (`PERFORMANCE_BUDGET.md`).
5. Smoke 1–14 na build exportada.

Veredito RC1: `docs/RC1_REPORT.md` → **REPROVADA**.

## Alterações em `project.godot` (RC1)

- `config/version="0.2.0-beta.rc1"`
- `config/description` — Chapter Zero Beta RC1 (closed test candidate)

Main scene: `scenes/product/main_menu.tscn`.
