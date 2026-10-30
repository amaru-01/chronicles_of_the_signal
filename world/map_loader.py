"""Tiled map loading helper with a small cache so revisiting a district
doesn't re-parse the JSON every time."""

import arcade

_MAP_CACHE = {}


class MapLoader:
    LAYER_OPTIONS = {
        "Walls_Physical": {"use_spatial_hash": True},
        "Walls_Digital": {"use_spatial_hash": True},
        "Interactables": {"use_spatial_hash": True},
    }

    def __init__(self, district_name: str):
        self.district_name = district_name
        self.map_path = f"assets/maps/{district_name}_physical.json"

    def load(self):
        if self.map_path not in _MAP_CACHE:
            _MAP_CACHE[self.map_path] = arcade.load_tilemap(
                self.map_path, scaling=1.0, layer_options=self.LAYER_OPTIONS
            )
        return _MAP_CACHE[self.map_path]

    def get_spawn_point(self):
        tile_map = _MAP_CACHE[self.map_path]
        spawn_objects = tile_map.object_lists.get("Spawns", [])
        for obj in spawn_objects:
            if obj.name == "PlayerStart":
                return obj.shape
        return (128, 128)
