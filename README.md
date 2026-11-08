# Chronicles of the Signal (In progress building)

A cyberpunk dual-reality adventure built with **Godot 4** and **GDScript**. The classic **2D** version is live in the browser (HTML5/WebAssembly). A **3D open-world action-adventure** version, with an animated story intro, a GPS, combat and a boss fight, is in development on the `3d-prototype` branch, targeting Windows.

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

> Art and audio are placeholders, generated for prototyping. The 2D screenshots above were taken in the early test room; the 2D game now has two full districts.

### The 3D version (`3d-prototype` branch)

<p align="center">
  <img src="docs/screenshots/3d-title.png" alt="Title screen with the Start 3D button" width="720" />
</p>

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/3d-intro-tower.png" alt="Intro: the Signal tower and the Curator's eye" /><br /><sub><b>Intro</b> &mdash; the Curator kept the Signal</sub></td>
    <td align="center"><img src="docs/screenshots/3d-intro-split.png" alt="Intro: the city splits into two worlds" /><br /><sub><b>Intro</b> &mdash; the city splits into Physical and Grid</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/3d-intro-wake.png" alt="Intro: the Runner wakes" /><br /><sub><b>Intro</b> &mdash; "Wake up, Runner."</sub></td>
    <td align="center"><img src="docs/screenshots/3d-intro-controls.png" alt="Intro: the controls card" /><br /><sub><b>Intro</b> &mdash; ends on the controls card</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/3d-gps-hub.png" alt="GPS arrow in the hub" /><br /><sub><b>GPS</b> &mdash; a green arrow points to your next objective</sub></td>
    <td align="center"><img src="docs/screenshots/3d-gps-grid.png" alt="The Neon Market in the Digital Grid with the GPS" /><br /><sub><b>The Grid</b> &mdash; Neon Market, with the goal on the minimap</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/3d-combat.png" alt="Hack pulse hitting an Enforcer" /><br /><sub><b>Combat</b> &mdash; the K pulse against an armoured Enforcer</sub></td>
    <td align="center"><img src="docs/screenshots/3d-archive.png" alt="The Archive district's cold teal lighting" /><br /><sub><b>Per-district lighting</b> &mdash; the Archive's cold teal</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/3d-boss-physical.png" alt="The Curator in its Physical form" /><br /><sub><b>Boss</b> &mdash; the Curator, Physical form (armoured)</sub></td>
    <td align="center"><img src="docs/screenshots/3d-boss-digital.png" alt="The Curator in its Digital form" /><br /><sub><b>Boss</b> &mdash; Digital form, after it flips worlds</sub></td>
  </tr>
</table>

<p align="center">
  <img src="docs/screenshots/3d-journal.png" alt="The quest journal" width="720" /><br />
  <sub><b>Journal</b> &mdash; main and side quests, memories, items and upgrades</sub>
</p>

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

The list above is the 2D game. The 3D version adds an intro cinematic, a GPS, combat, two more districts and a boss: see [the 3D prototype section](#-3d-prototype-branch-3d-prototype-windows).

## 🧊 3D Prototype (branch `3d-prototype`, Windows)

The 2D game is being rebuilt as a 3D open-world action-adventure. The web build stays 2D; the title screen's **Start 3D (new)** button is hidden on web.

**Story and onboarding**
- **Intro cinematic:** *Start 3D* plays an animated, narrated opening drawn entirely in code: the rainy skyline and the Signal tower with the Curator's eye, the blackout, the city splitting into the real world and the Grid, the Runner waking in Vantage Plaza, and finally a controls card. **Enter** or click advances (the first press finishes the typed line), **Esc** skips to the controls card.
- **GPS:** a green arrow orbits the player and points at the next objective, with the distance and a short label (for example `41 m  Static Row: start the trail`). The goal also shows on the minimap. It follows your story progress in every district, hides when you arrive and during dialogue, and **G** toggles it. A district supplies its goals by overriding one method, `_gps_target()`.
- **Hints:** **H** gives progressively more specific help for the next unsolved puzzle.

**Look and feel**
- **Camera and render:** a low fixed-angle camera behind the player, rendered into a 480x270 `SubViewport` and upscaled with nearest filtering for a pixel-art feel. Billboard sprite characters, wet neon streets, rain, and walls that cut away when they block the view.
- **Lighting:** each district has its own palette (cold teal Archive, loud magenta Neon Market, crimson Relay Tower, the original pink and cyan elsewhere), a few flickering lamps, and a different light in each world.
- **Props:** crates, glowing barrels and floor vents in the real world, and server racks in the Grid, kept against walls and away from spawns, exits and objects.
- **Readable text:** doorway names are full-resolution HUD labels pinned to the 3D doorways, not text inside the low-res viewport.

**Gameplay**
- **Two worlds, same rules:** **Space** swaps Physical and Digital. Walls, enemies and even enemy bolts exist in only one world.
- **Combat:** **J** melee strike and **K** hack pulse (ranged). Enemies: Trace drones, Enforcers (armoured, pulse only), Stalkers (Grid only, walk through walls) and Sentries (Physical turrets that fire bolts).
- **Boss:** the Curator in the Relay Tower. It flips worlds on a timed telegraph, is armoured in its Physical form, summons Stalkers and Enforcers, and escalates in three phases. Beating it triggers the Restore / Keep ending choice.
- **Open world:** the Vantage Plaza hub plus four districts (Static Row, The Archive, Neon Market, Relay Tower), beacons for checkpoints and fast travel (**T**), and a minimap.
- **Adventure systems:** quests with a HUD tracker and a journal (**Tab**), optional side quests, collectible memory fragments and data nodes, a hidden cache, and upgrades (Pulse Core, Strike Edge, Hardened Plating, Signal Cell, Phase Boots, Echo Core).
- **Saves:** autosave on entering a district, a SAVED indicator, a **Continue (3D)** button, and a fallback for a corrupt save file.
- **Audio:** the 2D effects plus new ones for enemy bolts and the boss (wake, world flip, phase change, armour clang, defeat), generated by `tools/make_sfx_3d.py`.

**3D controls:** WASD move, **Space** swap, **E** interact, **J** strike, **K** pulse, **H** hint, **G** GPS on/off, **T** fast travel, **Tab** journal, **Esc** pause.
**3D controller:** stick/D-pad move, **A** interact, **B** strike, **Right shoulder** pulse, **Y** swap, **X** hint, **Right stick click** GPS, **Left shoulder** fast travel, **Back** journal, **Start** pause. (Untested on a real pad.)

3D code lives in `scripts3d/`, `scenes3d/`, `shaders3d/`, `assets3d/` and `data3d/` (quests). It shares the autoloads with the 2D game, and 3D district ids are prefixed `3d_` so saves never clash.

**Dev checks** are Godot scripts in `tools/`:

```
godot --headless --path . --script res://tools/test_content_3d.gd -- <out_dir>
```

- Headless: `test_world_3d`, `test_adventure_3d`, `test_content_3d`, `test_title_3d`.
- Need a real window (leave out `--headless`; they read the rendered frame): `test_combat_3d`, `test_gps_3d`.
- Screenshot tools: `capture_title_3d`, `capture_intro_3d`, `capture_polish_3d`, `capture_boss_3d`, `capture_combat_3d`. The images in `docs/screenshots/` came from these.
- Any run started with `--script` defaults to a throwaway save file (`user://dev_test_save.json`), so tests and captures can never overwrite a real save.
- Sprites are generated with `tools/make_assets_3d.py` and extra sounds with `tools/make_sfx_3d.py` (`pip install pillow numpy`).

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

3D architecture (the same ideas, rebuilt in 3D):

- **`District3D`** (`scripts3d/district_3d.gd`) is the base of every 3D district: it builds the pixel viewport, the HUD, minimap, GPS, journal, lighting, props and autosave. A district overrides `_populate()`, `_objectives()` (hints), `_gps_target()` and optionally `_theme()` (its colours).
- **`WorldLayers3D`** turns the same text maps into two 3D worlds (physical and digital roots with their own collision) and hides the walls that block the camera.
- **`Enemy3D`** is the enemy base with hooks (which world it lives in, what hurts it, contact damage); drones, Enforcers, Stalkers, Sentries and the Curator extend it.
- **`Quests3D`** reads `data3d/quests.json` and keeps its state in `GameState.flags`, so quests and upgrades are saved with everything else.
- **`Intro3D`** is the opening cinematic; **`Gps3D`** draws the objective arrow.

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
├── scripts3d/ scenes3d/     # 3D prototype: districts, player, enemies, boss, quests, GPS, intro
├── shaders3d/ assets3d/     # 3D shaders and generated sprites
├── data3d/                  # quests.json
├── tools/                   # make_assets*.py, make_sfx_3d.py, 3D tests and screenshot captures
├── docs/screenshots/        # README images (2D and 3D)
├── md file/                 # STORY.md, TODO.md, DONE_1.md (design and progress notes)
└── assets/                  # fonts/, tiles/, sprites/, sounds/ (placeholder art and audio)
```

## 🚀 Getting Started

1. Install **Godot 4.3 or newer** (standard build — *not* .NET; C# cannot export to web).
2. Open Godot → **Import** → select `project.godot`.
3. Press **F5** to run.

**Controls:** WASD / arrows to move, **Space** to swap worlds, **E** interact, **H** hint, **Esc** pause.

**Controller:** D-pad or left stick to move, **A** interact, **X** hint, **Y** swap worlds, **Start** pause.

3D controls are listed in [the 3D prototype section](#-3d-prototype-branch-3d-prototype-windows).

To regenerate the placeholder art and audio: `pip install pillow numpy`, then `python tools/make_assets.py` (2D) or `python tools/make_assets_3d.py` and `python tools/make_sfx_3d.py` (3D).

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
- [x] 3D prototype: camera, two-world swap, combat, hub and districts (3d-prototype branch)
- [x] 3D adventure systems: quests, journal, upgrades, boss fight, saves
- [x] 3D intro cinematic and in-game GPS
- [x] 3D lighting palettes, props, readable exit labels and boss sounds
- [ ] Real 3D art (the sprites are generated placeholders) and a listening pass on the new sounds
- [ ] Windows export, performance pass and itch.io page for the 3D version
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
