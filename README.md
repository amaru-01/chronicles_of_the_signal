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

> Art and audio are placeholders, generated for prototyping. The screenshots were taken in the early test room; the game now has two full districts.

---

## 🎮 What's in the game

Two playable districts and a short story with two endings:

- **District 01 &mdash; Static Row:** learn the world swap, hacking, levers, doors and a timed gate.
- **District 02 &mdash; The Archive:** alternating one-world walls, a three-key gate, a timed gate with a risky shortcut, and the Curator's core.
- **Trace drones** patrol the Digital world and drain signal integrity. Swapping back is the escape.
- **Hint system:** press **H** for a hint on the next unsolved puzzle. Each press is more specific.
- **Story fragments**, NPC dialogue with choices, and an ending choice (restore the city's memories or keep your own).
- **Checkpoints**, autosave and a **Continue** button on the title screen.
- **Audio:** sound effects, a music loop per world, and volume sliders in the pause menu.
- **Controller support** (untested on a real pad). See [md file/STORY.md](md%20file/STORY.md) for the story and design notes.

## 📖 Overview

**Chronicles of the Signal** is a narrative-driven, tile-based RPG centered around **Dual-Layer Exploration**: at any moment, the player can hit **Space** to phase between the tangible, physical city and its digital "memory grid" counterpart. Each world has its own collision geometry, visuals, NPCs, and soundscape, enabling puzzles that depend on perceiving both sides of reality.

Architecture:

- **`GameState` autoload** — health, signal integrity, inventory, hacked terminals and story flags persist across scenes.
- **`WorldLayers`** — each world is a `TileMapLayer`; toggling `enabled` swaps drawing *and* collision at once. A swap is blocked if it would leave the player inside a wall.
- **Interactables** — everything the player can press **E** on extends `Interactable` (an `Area2D`). Set its `realm` to make it exist in only one world. Terminals, doors, NPCs and pickups are built on it.
- **Autoloads** — `GameState` (persistent state, save/load, checkpoints), `SceneManager` (fade scene changes), `Audio` (sound effects, music, volume), `Dialogue` (typewriter dialogue box and `Dialogue.ask()` choices).
- **Districts** — every district scene extends `District` (`scenes/world/district.gd`), which provides the HUD, hints, music, checkpoints and the signal-lost reboot. A district only supplies its map, objects and hint list.
- **Text maps** — each district's layout is a text file in `scenes/world/maps/` (`#` wall in both worlds, `.` floor, `P` wall in Physical only, `D` wall in Digital only).
- **Puzzles** — `Terminal` (hack), `Switch` (lever, optionally timed), `Door` (needs one or more keys, never closes on the player) and `Drone` (Digital-world hazard).
- **Hacking** — `HackMinigame` is a timed code-breaker: find the key among 8 codes using the "likeness" hint before attempts or time run out. Failing costs signal integrity; reaching 0 reboots the level.
- **Placeholder art and audio** — sprites, tiles and sounds in `assets/` are generated (`tools/make_assets.py`) and follow fixed layouts and file names (see `character_sprite.gd`), so real art and audio can be dropped in over the same files.
- **Signals over references** — systems talk through signals such as `layer_changed`.

## 📁 Project Structure

```
chronicles_of_the_signal/
├── project.godot            # Engine config, input actions, physics layer names
├── scenes/
│   ├── player/              # player.tscn + player.gd
│   ├── interactables/       # interactable.gd base + terminal, switch, door, npc, pickup, checkpoint, exit zone
│   ├── hazards/             # drone (Digital-world threat)
│   └── world/               # district.gd base, district_01/02 scenes, world_layers.gd, maps/*.txt
├── scripts/autoload/        # game_state.gd, scene_manager.gd, audio.gd
├── ui/                      # title, end screen, pause menu, dialogue box, hacking minigame, theme
├── fx/ + shaders/           # screen effects: glitch pulse, scanlines, vignette
├── tools/                   # make_assets.py (regenerates placeholder art and audio)
├── md file/                 # STORY.md, TODO.md, DONE_1.md (design and progress notes)
└── assets/                  # fonts/, tiles/, sprites/, sounds/ (placeholder art and audio)
```

## 🚀 Getting Started

1. Install **Godot 4.3 or newer** (standard build — *not* .NET; C# cannot export to web).
2. Open Godot → **Import** → select `project.godot`.
3. Press **F5** to run.

**Controls:** WASD / arrows to move, **Space** to swap worlds, **E** interact, **H** hint, **Esc** pause.

**Controller:** D-pad or left stick to move, **A** interact, **X** hint, **Y** swap worlds, **Start** pause.

To regenerate the placeholder art and audio: `pip install pillow numpy`, then `python tools/make_assets.py`.

### Physics layers

| # | Name | Used by |
|---|---|---|
| 1 | `player` | Player body |
| 2 | `world_physical` | Physical-world walls |
| 3 | `world_digital` | Digital-world walls |
| 4 | `interactable` | Terminals, doors, NPCs |

## 🌐 Web Export

1. **Project → Export → Web**, and install the export templates when prompted.
2. Click **Export Project** — the preset writes to `web/index.html` (keep the file name `index.html`).
3. Commit the `web/` folder and push to `main`. Netlify serves `web/` automatically (see `netlify.toml`) at https://chronicles-of-signal.netlify.app.
4. For itch.io, zip the contents of `web/` and upload it as an HTML5 game.

`web/.gdignore` stops Godot from importing the exported files back into the project.

Browsers block audio until the first click or key press, so keep a title screen before gameplay.

## 🗺 Roadmap

- [x] Port project to Godot, global state, layer swap trial
- [x] Interactables, NPC dialogue, title screen, pause menu
- [x] Terminal hacking minigame (timed code-breaker)
- [x] Glitch shader, animated character, UI theme
- [x] District 01 and District 02 with puzzles, drones, checkpoints and two endings
- [x] Hint system, dialogue choices, audio, volume settings, save/load
- [ ] Playtesting and balance
- [ ] Real art, tiles and audio (replace the placeholders)
- [ ] Key rebinding and a tested controller setup
- [ ] Web export check in Chrome and Firefox
- [ ] itch.io release

## 🔗 Useful Links

- Godot docs: https://docs.godotengine.org/
- itch.io HTML5 guide: https://itch.io/docs/creators/html5

## 📄 License

This project is licensed under the MIT License — feel free to fork, modify, and build your own signal.
