"""NPC entity with a minimal dialogue hook. Extend with a dialogue
tree / behaviour-state-machine as content grows."""

from entities.base_entity import BaseEntity


class NPC(BaseEntity):
    def __init__(self, texture_path, dialogue_id: str):
        super().__init__(texture_path)
        self.dialogue_id = dialogue_id

    def on_interact(self, game_view):
        from ui.dialogue_box import DialogueBox
        DialogueBox.open(game_view, self.dialogue_id)
