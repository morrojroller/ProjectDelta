# Project Delta — SuccessfullySplit

The original `ProjectDelta.luau` was **not modified**. Its code was split into 16 ordered modules plus a loader, and wrapped in the **Fabled** rage-cheat-style UI.

## Upload

Upload the entire `SuccessfullySplit` folder to your GitHub repo (keep every filename exactly the same).

## Run

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/morrojroller/ProjectDelta/main/SuccessfullySplit/loader.lua"))()
```

The loader adds a timestamp cache-buster to every request, so if you edit one module on GitHub and run the same loadstring again, the new version is used automatically.

## Fabled UI

The menu is titled **FABLED** with a white → dark-green gradient title. It has four tabs:

| Tab | Contents |
| --- | --- |
| **Combat** | Silent aim toggle/keybind, visible-only, movement prediction, FOV radius, no recoil/drop, hitpart selector, player target/exclusion lists |
| **Visuals** | ESP master toggle + skeleton/names/distance/health/weapon/team/tracers/boxes, max ESP distance, ESP color pickers (7 colors), fullbright, FOV circle settings |
| **Misc** | Inventory HUD toggle/scale/position/weapon/gear/accent, utility buttons (restore ammo, reset HUD) |
| **Settings** | Keybinds (menu/ESP/unload), menu scale, config save/load/reset/unload, info |

### UI Controls
- **Toggles** — animated checkboxes with accent highlight
- **Sliders** — draggable track with knob, live value label
- **Color Pickers** — saturation/value box + hue strip + hex input + preset swatches
- **Keybind Changers** — click to listen, press key to assign, Escape to clear
- **Textboxes** — inline text input (used for player search)
- **Buttons** — hover-highlighted action buttons

## Files

| File | Purpose |
| --- | --- |
| `00_core.luau` | Services, shared runtime references, executor safety checks |
| `01_icons.luau` | Full icon dictionary from `AllIcons.luau` + background preload |
| `02_state.luau` | Feature state, generic config encode/decode (Color3 serialization), ammo mods |
| `03_fullbright.luau` | Lighting backup and fullbright logic |
| `04_ai_cache.luau` | AI/NPC model cache and workspace connections |
| `05_fov_visibility.luau` | FOV circle drawing and line-of-sight raycasting |
| `05a_ui_library.luau` | Reusable Fabled UI component library (window, tabs, sections, controls) |
| `06_gui_base.luau` | Creates the Fabled window with all four tabs and wires every control |
| `07_target_lists.luau` | Combat tab: hitpart selector and player exclusion/target lists |
| `08_targeting.luau` | Target selection, movement prediction, HUD target finder |
| `09_bullet_hook.luau` | `Bullet.CreateBullet` hook + hook restoration |
| `10_item_parser.luau` | Equipped weapon/armor parsing + `getItemCategory` with category colors |
| `11_inventory_hud.luau` | Upgraded inventory HUD with category accents, icon cards, scale, drag, live dot |
| `12_esp.luau` | Full ESP: skeleton, names, distance, health, weapon, team tag, boxes, tracers, colors |
| `13_runtime.luau` | Refresh loops, render loop, configurable hotkeys |
| `14_cleanup.luau` | Global cleanup, UI cleanup, and unload hook |
| `loader.lua` | Downloads and runs every module in order |

## Hotkeys (all configurable in Settings tab)

| Default Key | Action |
| --- | --- |
| `CapsLock` | Toggle silent aim |
| `RightAlt` | Toggle the Fabled menu |
| `LeftAlt` | Toggle ESP |
| `Delete` | Unload / clean up everything |

## Config

Settings persist to `SilentAim_Config.json` in the executor's workspace. Color3 values are serialized as `{__color: true, r, g, b}`. Use **Save Config** / **Load Config** / **Reset To Defaults** in the Settings tab.
