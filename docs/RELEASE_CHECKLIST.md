# Release checklist (Windows build, 3D)

Version in `project.godot` (`config/version`) and the Windows preset
(`application/file_version`, `application/product_version`): **0.1.0**. Bump all three together.

## Before building
- [ ] The branch you are releasing from is the one you built and tested.
- [ ] All dev checks pass (run from the project root; `test_title_3d` and `test_reach_3d` can run with
  `--headless`, the rest need a window): `test_world_3d`, `test_adventure_3d`, `test_content_3d`,
  `test_title_3d`, `test_reach_3d`, `test_combat_3d`, `test_gps_3d`.
- [ ] `tools/perf_3d.gd` shows every district comfortably above 60 fps on the weakest machine you have.
- [ ] You have played it by hand from **New Game** to the ending at least once (see "Hand playtest").

## Build
1. Install the Windows export templates (once): Godot editor, **Editor > Manage Export Templates >
   Download and Install**. They must match the editor version (4.7.2).
2. `powershell -File tools/build_windows.ps1` writes `build/ChroniclesOfTheSignal-windows.zip`
   (a single `.exe` with the game embedded, plus the README).
3. `powershell -File tools/smoke_exe.ps1` loads every scene from the packed `.exe` and fails on any
   missing file. (It caught a real bug: the district maps and `data3d/quests.json` are not Godot
   resources, so they must stay in the Windows preset's include filter.)
4. Unzip the zip in a clean folder and run the `.exe` on a machine that does **not** have Godot installed.

## Smoke test of the built `.exe`
- [ ] Title screen appears, music plays, **New Game** plays the intro.
- [ ] The intro ends on the controls card and drops you in Vantage Plaza with the GPS arrow showing.
- [ ] Continue (3D) appears after quitting and relaunching, and resumes the same district.
- [ ] Gamepad: stick moves, A interacts, Y swaps worlds.
- [ ] Windowed, fullscreen (F11 or Alt+Enter if bound) and resizing keep the picture centred.
- [ ] Windows SmartScreen: an unsigned `.exe` shows "Windows protected your PC". Say so on the page
      ("More info > Run anyway") or sign the build.

## Hand playtest (things no automated test can judge)
- [ ] Is the Curator fight fair? Note how often you die and why.
- [ ] Do any enemies get stuck on walls (Enforcers slide along walls and have no pathfinding)?
- [ ] Can you always tell what to do next from the GPS, the hints (**H**) and the journal?
- [ ] Are the new sounds (bolts, boss) loud enough and not annoying?
- [ ] Does the intro feel too long? **Esc** skips it.

## Renderer
The project uses the **Compatibility** (OpenGL) renderer.
Measured on an Intel Iris Xe at 1280x720: Compatibility 5 to 7 ms per frame, Forward+ 3 to 4 ms,
so Forward+ is faster but not needed. Compatibility runs on any machine with OpenGL 3.3, while
Forward+ needs a working Vulkan driver. To try Forward+ on your machine:
`godot --path . --rendering-method forward_plus --rendering-driver vulkan`.

## itch.io
- [ ] Create the project page from `docs/ITCH_PAGE.md`; upload the zip; set the Windows platform.
- [ ] Add the screenshots from `docs/screenshots/3d-*.png` and the cover image.
- [ ] Keep the page **Draft** until the smoke test above passes, then publish.
