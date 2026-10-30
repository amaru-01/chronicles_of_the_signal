# Chronicles of the Signal (In progress building)

A 2D Cyberpunk RPG built with **Python** and the **Arcade** library, architected to run natively on desktop and deploy straight to the browser via **PyScript / Pyodide (WASM)**.

> Explore a neon-soaked city that exists in two overlapping realities — the **Physical World** and the **Digital Memory Grid** — switching between them on the fly to solve puzzles, evade threats, and uncover the signal hidden beneath the city.

## 🧰 Tech Stack

<div align="left">
  <a href="https://www.python.org/"><img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python" /></a>
  <a href="https://api.arcade.academy/"><img src="https://img.shields.io/badge/Arcade-2D%20Game%20Engine-1F6FEB?style=for-the-badge" alt="Arcade" /></a>
  <a href="https://pyscript.net/"><img src="https://img.shields.io/badge/PyScript-Web%20Runtime-5B2C83?style=for-the-badge" alt="PyScript" /></a>
  <a href="https://pyodide.org/"><img src="https://img.shields.io/badge/Pyodide-WASM-5E5CE6?style=for-the-badge" alt="Pyodide" /></a>
  <a href="https://www.mapeditor.org/"><img src="https://img.shields.io/badge/Tiled-Map%20Editor-8B5CF6?style=for-the-badge" alt="Tiled" /></a>
  <a href="https://developer.mozilla.org/en-US/docs/Web/HTML"><img src="https://img.shields.io/badge/HTML5-Frontend-E34F26?style=for-the-badge&logo=html5&logoColor=white" alt="HTML5" /></a>
  <a href="https://github.com/"><img src="https://img.shields.io/badge/GitHub-Repository-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub" /></a>
</div>

---

## 📖 Overview

**Chronicles of the Signal** is a narrative-driven, tile-based RPG centered around a core mechanic called **Dual-Layer Exploration**: at any moment, the player can hit **Spacebar** to phase between the tangible, physical city and its digital "memory grid" counterpart. Each layer has its own collision geometry, visual overlay, NPCs, and ambient soundscape, enabling puzzles and narrative beats that depend on perceiving both sides of reality at once.

The project is built with a strongly modular architecture:

- **Modular View Controller** — a central `ViewManager` cleanly separates Menu, Gameplay, Terminal-Hacking, and Pause states, so screens never reference each other directly.
- **Component-Based Entities** — Player, NPCs, and environmental objects (terminals, doors, pickups) all share a common `BaseEntity` contract with a uniform `on_interact()` hook.
- **Dual-Layer World System** — a dedicated `LayerManager` swaps collision maps, sprite layers, and ambience between the Physical and Digital layers without reloading the map.
- **Web-First Asset Strategy** — critical assets are preloaded into Pyodide's virtual filesystem at boot, while larger/later-game assets are lazily fetched asynchronously as the player progresses.

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Language | Python 3.10+ |
| Game Engine / Rendering | [Arcade](https://api.arcade.academy/) — OpenGL-accelerated 2D Python game library |
| Map Design | [Tiled Map Editor](https://www.mapeditor.org/) — `.tmx` / `.json` maps loaded via `arcade.load_tilemap()` |
| State Management | Arcade's built-in `View` system (`MenuView`, `GameView`, `TerminalHackingView`, `PauseView`) |
| Audio | Arcade's `arcade.Sound` for ambient soundscapes and SFX |
| Web Deployment | [PyScript](https://pyscript.net/) running on [Pyodide](https://pyodide.org/) (CPython compiled to WebAssembly) |
| Dev Server | Python's built-in `http.server` (or any static file server) |

---

## 📁 Project Structure

```
chronicles_of_the_signal/
│
├── index.html                 # PyScript web entry point (canvas + loader)
├── pyscript.toml               # Pyodide package + virtual-FS file mapping
├── main.py                     # Application entry point
│
├── core/                       # Constants, view manager, persistent game state
├── views/                      # MenuView, GameView, TerminalHackingView, PauseView
├── entities/                   # Player, NPC, interactables (base_entity.py contract)
├── world/                      # Map loading + dual-layer (Physical/Digital) manager
├── ui/                         # HUD, dialogue box
├── assets/                     # maps/ (Tiled), sprites/, sounds/, fonts/
├── build/                      # Generated bundle for web deployment
└── README.md                   # Project documentation
```

---

## 🚀 Installation & Setup

### Prerequisites

- Python **3.10+**
- `pip` (or `uv` / `poetry`, if preferred)
- A modern browser (Chrome, Firefox, Edge) for web testing
- [Tiled Map Editor](https://www.mapeditor.org/) (optional, only needed if you want to edit/create maps)

### 1. Clone the repository

```bash
git clone https://github.com/<your-org>/chronicles-of-the-signal.git
cd chronicles-of-the-signal
```

### 2. Create a virtual environment

```bash
python -m venv venv

# Activate it
source venv/bin/activate      # macOS / Linux
venv\Scripts\activate         # Windows
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

Minimum required package:

```bash
pip install arcade
```

### 4. Run the game locally (native desktop mode)

```bash
python main.py
```

This launches the game in a native OpenGL window using the standard CPython + Arcade runtime — ideal for fast iteration during development.

### 5. Run the game in the browser (PyScript / Pyodide)

Because PyScript requires a real HTTP origin (not `file://`), serve the project root with a local static server:

```bash
python -m http.server 8000
```

Then open:

```
http://localhost:8000/index.html
```

PyScript will boot Pyodide, mount the files declared in `pyscript.toml` into its virtual filesystem, and execute `main.py` inside the browser.

> **Note:** On first load, Pyodide downloads the CPython WASM runtime and the Arcade package, so the initial boot may take a few seconds longer than native startup. Subsequent loads are cached by the browser.

---

## 🗺 Editing Maps

Maps are authored in [Tiled Map Editor](https://www.mapeditor.org/) and exported as JSON to `assets/maps/`. Each district ships **two parallel layer groups** (`_Physical` and `_Digital`) within the same map so `LayerManager` can toggle between them without a reload.

---

## 🔗 Useful Links

- **Arcade (Python Game Library):** https://api.arcade.academy/
- **Arcade GitHub Repository:** https://github.com/pythonarcade/arcade
- **Tiled Map Editor:** https://www.mapeditor.org/
- **PyScript:** https://pyscript.net/
- **Pyodide:** https://pyodide.org/

---

## 📄 License

This project is licensed under the MIT License — feel free to fork, modify, and build your own signal.
