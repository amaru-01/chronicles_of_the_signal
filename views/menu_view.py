"""Main menu - entry point UI. Kept intentionally simple."""

import arcade
from core.constants import SCREEN_WIDTH, SCREEN_HEIGHT


class MenuView(arcade.View):
    def on_show_view(self):
        self.window.background_color = arcade.color.CYBER_GRAPE

    def on_draw(self):
        self.clear()
        arcade.draw_text(
            "CHRONICLES OF THE SIGNAL", SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2 + 40,
            arcade.color.ELECTRIC_CYAN, font_size=40, anchor_x="center",
        )
        arcade.draw_text(
            "Press ENTER to jack in", SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2 - 20,
            arcade.color.NEON_FUCHSIA, font_size=18, anchor_x="center",
        )

    def on_key_press(self, key, modifiers):
        if key == arcade.key.ENTER:
            self.window.view_manager.start_new_game()
