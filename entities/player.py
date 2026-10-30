"""Player entity: input is handled in GameView; this class just stores
movement state, animation frames and stats."""

from entities.base_entity import BaseEntity


class Player(BaseEntity):
    def __init__(self):
        super().__init__(
            ":resources:images/animated_characters/"
            "female_person/femalePerson_idle.png",
            scale=1.0,
        )
        self.uid = "player"
        self.health = 100
        self.signal_integrity = 100

    def on_interact(self, game_view):
        pass  # Players don't interact with themselves
