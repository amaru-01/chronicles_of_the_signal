"""Shared base class for all sprite-driven game objects."""

import arcade


class BaseEntity(arcade.Sprite):
    def __init__(self, texture_path: str, scale: float = 1.0):
        super().__init__(texture_path, scale=scale)
        self.uid = None

    def on_interact(self, game_view):
        """Override in subclasses: terminals, NPCs, pickups, doors."""
        raise NotImplementedError
