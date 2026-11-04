# Done so far: Chronicles of the Signal

A summary of what has been built. See [TODO.md](TODO.md) for what is left.

---

## Project history

| Step | What happened |
|---|---|
| Original prototype | A Python + Arcade version (~770 lines) with PyScript for the web. Preserved at the git tag `python-arcade-prototype`. |
| Move to Godot | Switched to **Godot 4** (GDScript) because it exports to the web reliably and has built-in tilemaps, collision layers, animation, shaders and UI. The Python code was removed from `main`'s working tree on the `godot-port` branch. |
| Version | Godot **4.7.2**, standard build (not .NET), Compatibility renderer, 1280x720. |

---

## Phase A: project setup (done)

- Godot project created with the Compatibility renderer, `canvas_items` stretch and nearest-neighbour texture filtering.
- Input actions: `move_*` (WASD and arrows), `toggle_layer` (Space), `interact` (E), `pause` (Esc).
- Named physics layers: `player`, `world_physical`, `world_digital`, `interactable`.
- `.gitignore` and `.gitattributes` set up for Godot; web export preset added.
- Web export tested and uploaded to a private itch.io draft.
- README rewritten for Godot, with a preview section and screenshots in `docs/screenshots/`.

---

## Phase B: core systems (done)

| System | What it does | Main files |
|---|---|---|
| Global state | `GameState` autoload: current world, health, signal integrity, inventory, hacked terminals, flags. Emits signals when things change. | `scripts/autoload/game_state.gd` |
| Scene changes | `SceneManager` autoload fades between scenes. | `scripts/autoload/scene_manager.gd` |
| World swap | Press Space to swap between the Physical World and the Digital Memory Grid. Each world is a `TileMapLayer`, so one flag swaps both visuals and collision. A swap is refused if it would trap the player inside a wall or a closed door. | `scenes/world/world_layers.gd` |
| Interaction | Everything the player can press E on extends `Interactable`. The closest object in range shows a prompt. | `scenes/interactables/interactable.gd` |
| Layer-specific objects | Each interactable has a `realm` setting (both, physical, digital). Out of its world it is hidden and unusable. | `interactable.gd` |
| Interactables | Terminal, Door, NPC (talks; says different lines after a terminal is hacked) and Pickup (remembered after collecting). | `scenes/interactables/` |
| Dialogue | Typewriter dialogue box autoload. E finishes a line and advances; the player is frozen while it is open. | `ui/dialogue_box.*` |
| Menus | Title screen and pause overlay (Resume, Main menu, Quit on desktop). | `ui/title_screen.*`, `ui/pause_menu.*` |

### The test room puzzle

1. A wall splits the physical room, with a locked door in it.
2. The Fixer NPC (physical world only) explains the idea.
3. Swap to the Digital world, which has no wall, and walk across.
4. Swap back and hack the terminal (physical world only) to open the door.
5. A memory fragment sits in the digital world only.

---

## Phase C: hacking minigame (done)

A **timed code-breaker**:

- 8 candidate codes are listed; one is the key.
- Picking a code shows its "likeness" (letters in the correct position).
- **30 seconds** and **4 attempts** by default.
- **Win:** the terminal is hacked and the door opens.
- **Fail** (wrong picks or time out): lose 20 signal integrity.
- **Esc:** abort with no penalty.
- **Integrity reaches 0:** "SIGNAL LOST", then the level reloads with integrity restored and progress kept.
- Time, attempts, code length (5 or 6 letters) and damage are settings on each `Terminal`.

Main files: `ui/hack_minigame.gd`, `ui/hack_minigame.tscn`, `scenes/interactables/terminal.gd`.

---

## Phase E: polish (partly done)

### Character and art (placeholder)
- Animated pixel-art player with 4-direction walk and idle animations, built from a sprite sheet by `CharacterSprite`.
- A second character (the Fixer) from the same system; NPCs turn to face the player when talked to.
- Feet-sized collision box, so heads overlap walls (top-down look).
- Tiles for both worlds: neon-edged brick and asphalt (physical), circuit grid (digital).
- Sprites for the terminal (locked and hacked), door and data fragment.
- Y-sorting so characters draw in the right order, and a smooth 2x camera.

### Look and feel
- **Glitch shader** (tearing and RGB split) on every world swap, on signal damage and now and then on the title screen.
- **Red flash** when a swap is blocked or the player takes damage.
- **Scanlines and vignette** overlay.
- **UI theme** (neon panels, buttons and progress bars) and the project-wide cyber font.
- HUD with the current world, item count and a signal integrity bar.
- Title screen with a grid backdrop and the runner walking across.

### Not done yet in Phase E
Audio, save and load, dialogue choices, controller support and playtesting. See [TODO.md](TODO.md).

---

## How it was checked

- Scenes load without errors in Godot 4.7.2 (headless).
- A scripted playthrough passed all **33 checks**: interaction, dialogue, swapping, door blocking, all minigame outcomes (win, wrong answers, time out, abort), the signal-lost reboot, pickups and scene changes.
- Screenshots were captured from the real game and reviewed.
- Not yet checked: the new shaders in a web build, and play by other people.

---

## Project layout

```
chronicles_of_the_signal/
├── project.godot
├── scenes/
│   ├── player/          # player + CharacterSprite
│   ├── interactables/   # base class, terminal, door, npc, pickup
│   └── world/           # test_world (to become district_01), world_layers
├── scripts/autoload/    # game_state, scene_manager
├── ui/                  # title, pause menu, dialogue, hacking minigame, theme
├── fx/ and shaders/     # screen effects
├── assets/              # fonts, tiles, sprites (placeholder art)
├── docs/screenshots/    # README images
└── md file/             # this folder: TODO.md and DONE.md
```

---

## Status at a glance

| Phase | Status |
|---|---|
| A: setup | Done |
| B: core systems | Done |
| C: hacking minigame | Done |
| D: real content | **Current phase, not started** |
| E: polish | Partly done |
| F: release | Not started |

Uncommitted at the time of writing: character, art, effects, minigame, README preview and these notes.
