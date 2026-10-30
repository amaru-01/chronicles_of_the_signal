"""Lightweight pause overlay drawn on top of a frozen GameView frame."""

import arcade


class PauseView(arcade.View):
    def __init__(self, game_view):
        super().__init__()
        self.game_view = game_view

    def on_draw(self):
        self.clear()
        self.game_view.on_draw()  # draw last frame beneath the overlay
        arcade.draw_lrbt_rectangle_filled(
            0, self.window.width, 0, self.window.height, (0, 0, 0, 160)
        )
        arcade.draw_text(
            "PAUSED - ESC to resume", self.window.width / 2, self.window.height / 2,
            arcade.color.WHITE, font_size=24, anchor_x="center",
        )

    def on_key_press(self, key, modifiers):
        if key == arcade.key.ESCAPE:
            self.window.view_manager.resume_game()
