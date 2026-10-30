"""Serializable data persisted across view transitions / save files."""

from dataclasses import dataclass, field
from core.constants import WorldLayer


@dataclass
class GameState:
    current_layer: WorldLayer = WorldLayer.PHYSICAL
    current_district: str = "district_01"
    player_health: int = 100
    player_signal_integrity: int = 100  # "HP" for the digital layer
    inventory: list = field(default_factory=list)
    hacked_terminals: set = field(default_factory=set)
    flags: dict = field(default_factory=dict)

    def reset(self):
        self.__init__()
