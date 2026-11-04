# TODO: Chronicles of the Signal

**Current phase: D (real content).** Phases A, B and C are finished, and part of E is done.
See [DONE.md](DONE.md) for what already exists.

Legend: `[ ]` not started, `[~]` partly done, `[x]` done.

---

## Now: housekeeping (do first)

- [ ] Commit the current work (character, art, effects, minigame, README preview).
- [ ] Push `godot-port` and the `python-arcade-prototype` tag:
  `git push origin python-arcade-prototype godot-port`
- [ ] Merge `godot-port` into `main` and push `main`.
- [ ] Re-export for the web and test in Chrome and Firefox. The new shaders (glitch, scanlines) are not yet confirmed in a browser build.
- [ ] Upload the new web build to the private itch.io draft page.

---

## Phase D: real content (current phase)

### 1. Story and design (do this before building maps)
- [ ] Write the story outline, 5 to 10 beats: who the player is, what "the signal" is, who they meet, how it ends.
- [ ] List the districts and what each one teaches the player.
- [ ] Decide the tone and the writing style for dialogue.
- [ ] Decide what the threat is (see "Threats" below).

### 2. District 01
- [ ] Rename `test_world` to `district_01` (scene, script and the `GameState.current_district` value).
- [ ] Replace the code-generated test room with `TileMapLayer` nodes built in the editor (one per world).
- [ ] Keep the physics layers: `world_physical` (2) and `world_digital` (3).
- [ ] Add spawn points and a camera limit that matches the real map size.
- [ ] Add more NPCs, terminals, doors and pickups using the existing scenes.
- [ ] Move to the next district through a door or an exit trigger.

### 3. Puzzles using both worlds
- [ ] Puzzle 1: cross a wall that exists in one world only (already in the test room; polish it).
- [ ] Puzzle 2: an object or switch that exists in the digital world but changes the physical world.
- [ ] Puzzle 3: two terminals that must both be hacked before a door opens.
- [ ] Puzzle 4: a timed puzzle that uses the swap (for example, a door that closes again).
- [ ] Make sure no puzzle can leave the player stuck (a swap is already blocked inside walls).

### 4. Threats ("evade threats" from the original pitch)
- [ ] Decide: patrolling drones, trace pressure in the digital world, or both.
- [ ] Add one enemy or hazard type that costs `player_signal_integrity`.
- [ ] Use the existing "signal lost" reboot for when integrity reaches 0.

### 5. Game flow
- [ ] Add an ending or end screen (with a "play again" option).
- [ ] Make a game over screen, or keep the current reboot and tune it.
- [ ] Give the hacking minigame variety: different difficulty per terminal (already supported through `Terminal` exports).

### 6. Art
- [ ] Replace the placeholder art with real art. Keep the same file names and layouts:
  - `assets/sprites/player/player_sheet.png` (5 columns by 4 rows of 32x48 cells)
  - `assets/sprites/npc/*_sheet.png` (same layout)
  - `assets/tiles/physical_tiles.png` and `digital_tiles.png` (wall, floor, floor variant)
  - `assets/sprites/objects/` (terminal, door, fragment)
- [ ] Add a few more tiles: props, doors, neon signs, decoration.
- [ ] Add NPC variety (more sprite sheets).
- [ ] Check the licence of any art you download.

---

## Phase E: polish (partly done)

- [x] Glitch shader on the world swap
- [x] Scanlines and vignette overlay
- [x] Animated character and UI theme
- [ ] Sound effects: walking, swap, hack success and fail, dialogue blips, UI clicks
- [ ] Ambient loop for each world and a title screen track
- [ ] Volume settings (music and effects) in the pause menu
- [ ] Save and load: write `GameState` to JSON in `user://`
- [ ] Dialogue improvements: choices and branching (try the Dialogue Manager plugin)
- [ ] Controller support and key rebinding (optional)
- [ ] Playtest with 2 or 3 other people and write down what confused them

---

## Phase F: release

- [ ] Confirm the licence of `cyber_mono.ttf`, art, audio and plugins, and that they fit the repo's MIT licence.
- [ ] Write the itch.io page: description, controls, screenshots, a GIF of the world swap.
- [ ] Make a cover image and a short tagline.
- [ ] Test the final web build in Chrome and Firefox (audio starts after the first click).
- [ ] Switch the itch.io page from Draft to Public.
- [ ] Link the itch.io page from the README and update the roadmap.

---

## Small things to remember

- [ ] Keep the first public release small: one or two districts, a few puzzles, a short ending. More districts can come as later updates.
- [ ] Keep `README.md` roadmap and screenshots up to date after big changes (screenshots live in `docs/screenshots/`).
- [ ] Re-run a full playthrough after each big change to catch broken puzzles.
