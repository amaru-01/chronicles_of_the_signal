# Chronicles of the Signal (In progress building)

A 2D Cyberpunk RPG built with **Godot 4** and **GDScript**, exported to desktop and to the browser (HTML5/WebAssembly) for itch.io.

> Explore a neon-soaked city that exists in two overlapping realities — the **Physical World** and the **Digital Memory Grid** — switching between them on the fly to solve puzzles, evade threats, and uncover the signal hidden beneath the city.

> The original Python / Arcade prototype is preserved at the git tag `python-arcade-prototype`.

## 🧰 Tech Stack

<div align="left">
  <a href="https://godotengine.org/"><img src="https://img.shields.io/badge/Godot-4.3+-478CBF?style=for-the-badge&logo=godotengine&logoColor=white" alt="Godot" /></a>
  <a href="https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html"><img src="https://img.shields.io/badge/GDScript-Language-355570?style=for-the-badge" alt="GDScript" /></a>
  <a href="https://itch.io/"><img src="https://img.shields.io/badge/itch.io-Web%20Release-FA5C5C?style=for-the-badge&logo=itchdotio&logoColor=white" alt="itch.io" /></a>
  <a href="https://github.com/"><img src="https://img.shields.io/badge/GitHub-Repository-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub" /></a>
</div>

---

## 🖼 Preview

<p align="center">
  <img src="docs/screenshots/title.png" alt="Title screen" width="720" />
</p>

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/physical-world.png" alt="Physical world" /><br /><sub><b>Physical World</b> &mdash; neon-lit brick and asphalt</sub></td>
    <td align="center"><img src="docs/screenshots/digital-world.png" alt="Digital Memory Grid" /><br /><sub><b>Digital Memory Grid</b> &mdash; the same room, different rules</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/world-swap-glitch.png" alt="World swap glitch effect" /><br /><sub>Pressing <b>Space</b> glitches reality between the two worlds</sub></td>
    <td align="center"><img src="docs/screenshots/hacking-minigame.png" alt="Hacking minigame" /><br /><sub>Timed code-breaker minigame</sub></td>
  </tr>
</table>

> Art is placeholder, generated for prototyping.

---

## 📖 Overview

**Chronicles of the Signal** is a narrative-driven, tile-based RPG centered around **Dual-Layer Exploration**: at any moment, the player can hit **Space** to phase between the tangible, physical city and its digital "memory grid" counterpart. Each world has its own collision geometry, visuals, NPCs, and soundscape, enabling puzzles that depend on perceiving both sides of reality.

Architecture:

- **`GameState` autoload** — health, signal integrity, inventory, hacked terminals and story flags persist across scenes.
- **`WorldLayers`** — each world is a `TileMapLayer`; toggling `enabled` swaps drawing *and* collision at once. A swap is blocked if it would leave the player inside a wall.
- **Interactables** — everything the player can press **E** on extends `Interactable` (an `Area2D`). Set its `realm` to make it exist in only one world. Terminals, doors, NPCs and pickups are built on it.
- **Autoloads** — `GameState` (persistent state), `SceneManager` (fade scene changes), `Dialogue` (typewriter dialogue box).
- **Hacking** — `HackMinigame` is a timed code-breaker: find the key among 8 codes using the "likeness" hint before attempts or time run out. Failing costs signal integrity; reaching 0 reboots the level.
- **Placeholder art** — sprites and tiles in `assets/` are generated placeholders that follow fixed layouts (see `character_sprite.gd`), so real art can be dropped in over the same filenames.
- **Signals over references** — systems talk through signals such as `layer_changed`.

## 📁 Project Structure

```
chronicles_of_the_signal/
├── project.godot            # Engine config, input actions, physics layer names
├── scenes/
│   ├── player/              # player.tscn + player.gd
│   ├── interactables/       # interactable.gd base + terminal, door, npc, pickup
│   └── world/               # test_world.tscn, world_layers.gd (layer swap)
├── scripts/autoload/        # game_state.gd, scene_manager.gd
├── ui/                      # title, pause menu, dialogue box, hacking minigame, theme
├── fx/ + shaders/           # screen effects: glitch pulse, scanlines, vignette
└── assets/                  # fonts/, tiles/, sprites/ (placeholder pixel art), audio/
```

## 🚀 Getting Started

1. Install **Godot 4.3 or newer** (standard build — *not* .NET; C# cannot export to web).
2. Open Godot → **Import** → select `project.godot`.
3. Press **F5** to run.

**Controls:** WASD / arrows to move, **Space** to swap worlds, **E** interact, **Esc** pause.

### Physics layers

| # | Name | Used by |
|---|---|---|
| 1 | `player` | Player body |
| 2 | `world_physical` | Physical-world walls |
| 3 | `world_digital` | Digital-world walls |
| 4 | `interactable` | Terminals, doors, NPCs |

## 🌐 Web Export

1. **Project → Export → Add… → Web**, and install the export templates when prompted.
2. Export to `exports/web/index.html`.
3. Zip the folder's contents and upload to itch.io as an HTML5 game.

Browsers block audio until the first click or key press, so keep a title screen before gameplay.

## 🗺 Roadmap

- [x] Port project to Godot, global state, layer swap trial
- [ ] Real tileset and District 01 maps
- [x] Interactables, NPC dialogue, title screen, pause menu
- [x] Terminal hacking minigame (timed code-breaker)
- [x] Glitch shader, animated character, UI theme
- [ ] Audio, save/load
- [ ] itch.io release

## 🔗 Useful Links

- Godot docs: https://docs.godotengine.org/
- itch.io HTML5 guide: https://itch.io/docs/creators/html5

## 📄 License

This project is licensed under the MIT License — feel free to fork, modify, and build your own signal.
