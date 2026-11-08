# Technical Design Document: Chronicles of the Signal (Godot 4.x)

## 1. Overview

This document outlines the implementation strategy for adding the "Dual Reality" mechanic to the existing 2D cyberpunk/synthwave platformer project. The player can swap between a "Physical" world and a "Digital" world, visually separated by a dynamic, glitchy boundary.

**Target Engine:** Godot 4.2+
**Base Repository:** <https://github.com/amaru-01/chronicles_of_the_signal>

## 2. Repository Integration Strategy

*Note for AI Assistant (Claude):* Do not generate a new project structure from scratch. Instead, analyze the existing Godot project structure in the provided GitHub repository.

Review the existing 2D design, particularly:

1. The main level/world scenes to understand how layers are currently separated.

2. The current Player scene (likely a `CharacterBody2D`) to see existing movement and animation logic.

3. How environments and backgrounds are currently handled.

The goal is to inject the Dual Reality mechanic (Sections 3 & 4) seamlessly into the user's *existing* node hierarchy.

## 3. The "Reality Swap" Mechanic (GDScript Logic)

The AI should generate an expansion to the existing state machine for the player and a global signal bus to handle world transitions.

### 3.1 Player Script Integration (Extend Existing Script)

* **Variables to Inject:** `enum Reality { PHYSICAL, DIGITAL }`, `var current_reality = Reality.PHYSICAL`.

* **Input Handling:** Listen for the `swap_reality` action (mapped to Spacebar) within the existing `_physics_process` or `_input` functions.

* **Collision Masking Logic:**

  * Define which existing collision layers correspond to the Physical world vs. the Digital world based on the repo's project settings.

  * When in `PHYSICAL`: Update the `collision_mask` to interact with Physical layers, ignoring Digital.

  * When in `DIGITAL`: Update the `collision_mask` to interact with Digital layers, ignoring Physical.

### 3.2 Global Signal Bus (Autoload)

* Create or update an Autoload (e.g., `EventBus.gd`).

* Add: `signal reality_swapped(new_reality: int)`

* Update existing enemies, doors, and UI scripts in the repo to connect to this signal so they react to the reality state without needing a direct reference to the player.

## 4. The Glitch Mask Shader (Crucial Visual Element)

The defining feature is the jagged, lightning-like split down the screen. The AI needs to generate a `canvas_item` shader and apply it to the Node/CanvasGroup that currently houses the "Digital" environment assets in the repo.

### Shader Logic Instructions for Claude:

Create a Godot shader that uses a texture mask (FastNoiseLite) and a uniform coordinate (the player's X position on screen).

**Uniforms needed:**

* `uniform float split_x_position;` (Normalized 0.0 to 1.0 screen position, passed dynamically from the Camera/Player script).

* `uniform sampler2D noise_tex;` (For the jagged glitch edge).

* `uniform float edge_width;` (How thick the glitch boundary is).

* `uniform vec4 edge_color: source_color;` (The bright cyan/magenta color at the boundary).

**Fragment Logic:**

1. Get the `UV.x` of the screen.

2. Sample the `noise_tex` to offset the `UV.x` slightly, creating a jagged line instead of a perfectly straight one.

3. If `UV.x + noise_offset < split_x_position`: Set `COLOR.a = 0.0` (Hide digital, reveal physical beneath).

4. If `UV.x + noise_offset > split_x_position`: Retain the texture (Show digital world).

5. If `UV.x` is exactly near the boundary threshold: Emit the `edge_color` with high emission for the bloom effect.

## 5. Post-Processing & Lighting

Instruct the AI to verify or update the existing `WorldEnvironment` node in the repository.

* **Glow (Bloom):** Ensure `glow_enabled = true`. Set `glow_intensity` to \~0.8, `glow_bloom` to \~0.2, and `glow_blend_mode` to Additive. This makes the neon lights and the cyan digital grid pop.

## 6. AI Prompting Strategy (How to feed this to Claude)

When passing this document to your AI assistant, use prompts like:

1. *"Please review the Godot project structure in https://github.com/amaru-01/chronicles_of_the_signal. Based on my existing Player scene, how should I integrate the 'Reality Swap' collision masking described in Section 3?"*

2. *"Look at how my levels are currently built in the repo. Where is the best place to apply the 'Glitch Mask Shader' from Section 4 so it correctly hides the digital layer, and write the GLSL code for me."*

3. *"Create the `HUD.gd` script update to connect to the EventBus, so the 'Signal' bar (if it exists in my UI scene) drains while the player is in the DIGITAL state."*