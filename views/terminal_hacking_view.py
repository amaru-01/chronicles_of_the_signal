"""
TerminalHackingView - self-contained minigame overlay.

Pushed on top of the game by ViewManager.open_terminal(). Keeps its own
state entirely (grid, timer, attempts) and, on exit, hands control back
via self.window.show_view(self.return_view) instead of rebuilding GameView.
"""

import arcade


class TerminalHackingView(arcade.View):
    def __init__(self, terminal_entity, return_view):
        super().__init__()
        self.terminal_entity = terminal_entity
        self.return_view = return_view
        self.puzzle_solved = False
        # TODO: generate puzzle grid/sequence based on terminal difficulty

    def on_show_view(self):
        self.window.background_color = (5, 5, 15)

    def on_draw(self):
        self.clear()
        arcade.draw_text(
            "TERMINAL BREACH IN PROGRESS...", self.window.width / 2,
            self.window.height / 2, arcade.color.CYBER_GRAPE,
            font_size=28, anchor_x="center",
        )
        # TODO: draw hack grid / code sequence UI

    def on_key_press(self, key, modifiers):
        if key == arcade.key.ESCAPE:
            self._exit(success=False)

    def _exit(self, success: bool):
        if success:
            self.terminal_entity.mark_hacked()
            self.window.view_manager.game_state.hacked_terminals.add(
                self.terminal_entity.uid
            )
        self.window.show_view(self.return_view)
