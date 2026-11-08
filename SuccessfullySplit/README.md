# Project Delta — SuccessfullySplit

The original `ProjectDelta.luau` was **not modified**. Its code was split into 15 ordered modules plus a loader.

## Upload

Upload the entire `SuccessfullySplit` folder to your GitHub repo (keep every filename exactly the same).

## Configure the loader

Open `loader.lua` and change this line to your repo's raw folder URL:

```lua
local BASE_URL = "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/SuccessfullySplit/"
```

## Run

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/SuccessfullySplit/loader.lua"))()
```

The loader adds a timestamp cache-buster to every request, so if you edit one module on GitHub and run the same loadstring again, the new version is used automatically.

## Files

| File | Purpose |
| --- | --- |
| `00_core.luau` | Services, shared runtime references, executor safety checks |
| `01_icons.luau` | Full icon dictionary from `AllIcons.luau` + background preload |
| `02_state.luau` | Feature state, config save/load, ammo modifications |
| `03_fullbright.luau` | Lighting backup and fullbright logic |
| `04_ai_cache.luau` | AI/NPC model cache and workspace connections |
| `05_fov_visibility.luau` | FOV circle and line-of-sight raycasting |
| `06_gui_base.luau` | Main window shell, dragging, top toggle buttons |
| `07_target_lists.luau` | Hitpart selector and player exclusion lists |
| `08_targeting.luau` | Target selection, prediction, HUD target finder |
| `09_bullet_hook.luau` | `Bullet.CreateBullet` hook + hook restoration |
| `10_item_parser.luau` | Equipped weapon/armor parsing |
| `11_inventory_hud.luau` | Inventory HUD UI, slot pool, refresh logic |
| `12_esp.luau` | Skeleton/name/distance/weapon ESP |
| `13_runtime.luau` | Refresh loops, render loop, hotkeys |
| `14_cleanup.luau` | Global cleanup and unload hook |
| `loader.lua` | Downloads and runs every module in order |

## Hotkeys (unchanged)

- `CapsLock` — toggle silent aim
- `RightAlt` — toggle the menu
- `LeftAlt` — toggle ESP
- `Delete` — unload / clean up everything
