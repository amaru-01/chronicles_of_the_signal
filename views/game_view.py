"""
GameView - the core exploration + combat loop.

Responsible for:
    * Loading the Tiled map (.json) for the active district
    * Holding one Scene whose layer visibility/collision is driven by
      LayerManager (Physical <-> Digital)
    * Handling the Spacebar toggle between WorldLayer states
    * Updating/drawing the player, NPCs, camera and HUD
"""

import arcade

from core.constants import PLAYER_MOVEMENT_SPEED, WorldLayer
from entities.player import Player
from world.map_loader import MapLoader
from world.layer_manager import LayerManager
from ui.hud import HUD


class GameView(arcade.View):
    def __init__(self, district_name="district_01"):
        super().__init__()
        self.district_name = district_name

        self.scene = None
        self.tile_map = None
        self.physics_engine = None

        self.player = None
        self.camera = None
        self.gui_camera = None

        self.layer_manager = None
        self.hud = None

    # ------------------------------------------------------------------
    def setup(self):
        """(Re)build the world. Safe to call again to reset the level."""
        loader = MapLoader(self.district_name)
        self.tile_map = loader.load()
        self.scene = arcade.Scene.from_tilemap(self.tile_map)

        self.player = Player()
        self.player.center_x, self.player.center_y = loader.get_spawn_point()
        self.scene.add_sprite("Player", self.player)

        self.physics_engine = arcade.PhysicsEngineSimple(
            self.player, walls=self.scene.get_sprite_list("Walls_Physical")
        )

        self.layer_manager = LayerManager(self.scene, self.physics_engine)
        self.layer_manager.set_layer(WorldLayer.PHYSICAL)

        self.camera = arcade.Camera2D()
        self.gui_camera = arcade.Camera2D()
        self.hud = HUD(self.window.view_manager.game_state)

    # ------------------------------------------------------------------
    def on_show_view(self):
        self.window.background_color = arcade.color.BLACK

    def on_draw(self):
        self.clear()
        self.camera.use()
        self.scene.draw()

        self.gui_camera.use()
        self.hud.draw()

    def on_update(self, delta_time: float):
        self.physics_engine.update()
        self.scene.update(delta_time)
        self.camera.position = self.player.position

    # ------------------------------------------------------------------
    def on_key_press(self, key, modifiers):
        if key == arcade.key.SPACE:
            self.layer_manager.toggle()
        elif key == arcade.key.ESCAPE:
            self.window.view_manager.pause_game()
        elif key in (arcade.key.W, arcade.key.UP):
            self.player.change_y = PLAYER_MOVEMENT_SPEED
        elif key in (arcade.key.S, arcade.key.DOWN):
            self.player.change_y = -PLAYER_MOVEMENT_SPEED
        elif key in (arcade.key.A, arcade.key.LEFT):
            self.player.change_x = -PLAYER_MOVEMENT_SPEED
        elif key in (arcade.key.D, arcade.key.RIGHT):
            self.player.change_x = PLAYER_MOVEMENT_SPEED
        elif key == arcade.key.E:
            self._try_interact()

    def on_key_release(self, key, modifiers):
        if key in (arcade.key.W, arcade.key.S, arcade.key.UP, arcade.key.DOWN):
            self.player.change_y = 0
        elif key in (arcade.key.A, arcade.key.D, arcade.key.LEFT, arcade.key.RIGHT):
            self.player.change_x = 0

    # ------------------------------------------------------------------
    def _try_interact(self):
        """Check nearby interactables (terminals, NPCs, doors)."""
        hits = arcade.check_for_collision_with_list(
            self.player, self.scene.get_sprite_list("Interactables")
        )
        for obj in hits:
            if hasattr(obj, "on_interact"):
                obj.on_interact(self)
