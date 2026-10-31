"""
LayerManager - owns the Physical <-> Digital Memory Grid toggle.

Both layers are pre-baked into the same Tiled map as parallel layer groups
(e.g. "Walls_Physical" / "Walls_Digital", "Decor_Physical" / "Decor_Digital").
Toggling swaps sprite-list visibility and re-targets the physics engine's
wall list so collisions match whichever reality the player is standing in.
"""

import arcade
from core.constants import WorldLayer


PHYSICAL_SPRITE_LAYERS = ["Walls_Physical", "Decor_Physical", "NPCs_Physical"]
DIGITAL_SPRITE_LAYERS = ["Walls_Digital", "Decor_Digital", "Fragments_Digital"]


class LayerManager:
    def __init__(self, scene: arcade.Scene, physics_engine):
        self.scene = scene
        self.physics_engine = physics_engine
        self.current_layer = WorldLayer.PHYSICAL
        try:
            self.toggle_sound = arcade.load_sound(":resources:sounds/layer_switch.wav")
        except FileNotFoundError:
            self.toggle_sound = None

    def toggle(self):
        target = (
            WorldLayer.DIGITAL
            if self.current_layer == WorldLayer.PHYSICAL
            else WorldLayer.PHYSICAL
        )
        self.set_layer(target)

    def set_layer(self, layer: WorldLayer):
        self.current_layer = layer
        show, hide = (
            (PHYSICAL_SPRITE_LAYERS, DIGITAL_SPRITE_LAYERS)
            if layer == WorldLayer.PHYSICAL
            else (DIGITAL_SPRITE_LAYERS, PHYSICAL_SPRITE_LAYERS)
        )

        for name in show:
            try:
                self.scene.get_sprite_list(name).visible = True
            except KeyError:
                pass
        for name in hide:
            try:
                self.scene.get_sprite_list(name).visible = False
            except KeyError:
                pass

        wall_key = "Walls_Physical" if layer == WorldLayer.PHYSICAL else "Walls_Digital"
        try:
            self.physics_engine.walls = self.scene.get_sprite_list(wall_key)
        except KeyError:
            pass

        if self.toggle_sound:
            arcade.play_sound(self.toggle_sound)
