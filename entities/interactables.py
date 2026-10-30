"""Environmental objects: terminals, doors, pickups."""

from entities.base_entity import BaseEntity


class Terminal(BaseEntity):
    def __init__(self, texture_path, uid: str, difficulty: int = 1):
        super().__init__(texture_path)
        self.uid = uid
        self.difficulty = difficulty
        self.hacked = False

    def on_interact(self, game_view):
        if not self.hacked:
            game_view.window.view_manager.open_terminal(self)

    def mark_hacked(self):
        self.hacked = True
        self.alpha = 120  # visually dim once breached


class Door(BaseEntity):
    def __init__(self, texture_path, target_district: str, target_spawn: str):
        super().__init__(texture_path)
        self.target_district = target_district
        self.target_spawn = target_spawn

    def on_interact(self, game_view):
        game_view.window.view_manager.start_new_game(self.target_district)
