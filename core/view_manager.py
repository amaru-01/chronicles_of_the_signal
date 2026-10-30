"""
Central state/view manager.

Arcade Views are re-instantiated frequently (menu -> game -> terminal -> game),
so anything that must persist (player stats, inventory, which district is
loaded, hacking puzzle progress) lives on GameState, and all transitions
are funneled through this manager to keep views decoupled from each other.

Views never import other views directly - they call
self.window.view_manager.goto_xxx() instead. This keeps the dependency
graph a star shape instead of an unmaintainable web.
"""

import arcade


class ViewManager:
    """Owns transition logic between all arcade.View screens."""

    def __init__(self, window: arcade.Window, game_state):
        self.window = window
        self.game_state = game_state
        self._game_view = None  # cached so re-entering keeps world state

    # ------------------------------------------------------------------
    # Transitions
    # ------------------------------------------------------------------
    def show_menu(self):
        from views.menu_view import MenuView
        self.window.show_view(MenuView())

    def start_new_game(self, district="district_01"):
        from views.game_view import GameView
        self.game_state.reset()
        self._game_view = GameView(district_name=district)
        self._game_view.setup()
        self.window.show_view(self._game_view)

    def resume_game(self):
        """Return to the cached GameView instance instead of rebuilding it."""
        if self._game_view is None:
            self.start_new_game()
        else:
            self.window.show_view(self._game_view)

    def open_terminal(self, terminal_entity):
        from views.terminal_hacking_view import TerminalHackingView
        hacking_view = TerminalHackingView(
            terminal_entity=terminal_entity,
            return_view=self._game_view,
        )
        self.window.show_view(hacking_view)

    def pause_game(self):
        from views.pause_view import PauseView
        self.window.show_view(PauseView(game_view=self._game_view))

    def quit_to_menu(self):
        self._game_view = None
        self.show_menu()
