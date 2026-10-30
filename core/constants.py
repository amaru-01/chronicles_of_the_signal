"""Global constants & enums shared across the project."""

from enum import Enum, auto

SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720
SCREEN_TITLE = "Chronicles of the Signal"

PLAYER_MOVEMENT_SPEED = 5
TILE_SCALING = 1.0


class WorldLayer(Enum):
    """The two toggleable exploration layers."""
    PHYSICAL = auto()   # Real-world cyberpunk city
    DIGITAL = auto()    # The "Memory Grid" - digital overlay dimension


class GameKey:
    """Central keybind registry so re-mapping only happens in one place."""
    TOGGLE_LAYER = "SPACE"
    INTERACT = "E"
    PAUSE = "ESCAPE"
