# itch.io page: Chronicles of the Signal

Copy each block into the matching field of the itch.io page editor.
Screenshots are in `docs/screenshots/` (the `3d-*.png` set). The first screenshot is the
cover image candidate: use `3d-intro-split.png` (it reads well small).

## Title
Chronicles of the Signal

## Short description (the one-liner under the title, 100 characters max)
Swap between two overlapping cities. Hack, fight and follow the Signal. A cyberpunk 3D adventure.

## Classification
Games. Kind of project: Downloadable (Windows).

## Genre / tags
Action-adventure, Cyberpunk, Puzzle, Pixel Art, Hacking, Story Rich, 3D, Singleplayer, Atmospheric, Short

## Description

**Two cities. One signal.**

Vantage City runs on the Signal. Six months ago it went quiet, and the people of the lower
districts forgot who they were. You wake in the rain with no name and one gift: you can phase
between the **real city** and the **Grid**, a ghost copy where every deleted memory ended up.

**Swap worlds to solve the street.** Walls that block you in one world do not exist in the
other. Slip into the Grid to cross a wall, swap back to hack a terminal, pull a lever that only
exists in the Grid and run for the gate before it closes.

**Fight with both hands.** Strike drones with a melee hit, or fire the hack pulse at armoured
Enforcers. Stalkers chase you through walls in the Grid, turrets fire bolts that vanish when
you change worlds, and the **Curator**, a boss that lives in one world at a time, flips between
them while you try to keep up.

**Find your way.** A GPS arrow points to your next objective, a journal tracks quests and
memories, and beacons let you fast-travel across a hub and four districts.

### Features
- An animated, narrated opening and a four-district open world around Vantage Plaza
- Two overlapping worlds with different walls, enemies and even bullets
- Melee and ranged hack-pulse combat, four enemy types and a three-phase boss
- Timed code-breaker hacking minigame
- Quests, side quests, memory fragments, hidden caches and six upgrades
- Two endings: restore the city's memories, or keep your own
- Controller support (untested on real hardware), autosave and fast travel

### Controls
| Action | Keyboard | Controller |
|---|---|---|
| Move | WASD / arrows | Left stick / D-pad |
| Swap worlds | Space | Y |
| Interact / hack | E | A |
| Strike | J or left click | B |
| Hack pulse | K or right click | Right shoulder |
| Hint | H | X |
| GPS on / off | G | Right stick click |
| Fast travel | T | Left shoulder |
| Journal | Tab | Back |
| Pause | Esc | Start |

### Status
Playable prototype. Art and audio are placeholders generated for development, and balance is
untuned. Feedback is very welcome, especially where you got stuck.

### System requirements
Windows 10 or 11, 64-bit. Any GPU with OpenGL 3.3 (an integrated GPU is fine: it runs above
140 fps on an Intel Iris Xe at 720p).

## Pricing
Free (or pay what you want).

## Community
Comments on, so players can report stuck spots.

## Uploads
`ChroniclesOfTheSignal-windows.zip` (built by `tools/build_windows.ps1`): mark **Windows**.

Command-line upload with butler (after `butler login`):

```
butler push build/ChroniclesOfTheSignal-windows.zip YOURNAME/chronicles-of-the-signal:windows --userversion 0.1.0
```
