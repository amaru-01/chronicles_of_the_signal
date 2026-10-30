"""Minimal HUD overlay: health, signal integrity, current layer indicator."""

import arcade
from core.constants import WorldLayer


class HUD:
    def __init__(self, game_state):
        self.game_state = game_state

    def draw(self):
        gs = self.game_state
        arcade.draw_text(f"HP: {gs.player_health}", 20, 680, arcade.color.NEON_FUCHSIA, 16)
        arcade.draw_text(f"SIGNAL: {gs.player_signal_integrity}", 20, 655, arcade.color.ELECTRIC_CYAN, 16)
        layer_label = "PHYSICAL WORLD" if gs.current_layer == WorldLayer.PHYSICAL else "MEMORY GRID"
        arcade.draw_text(layer_label, 20, 630, arcade.color.ACID_GREEN, 16)
