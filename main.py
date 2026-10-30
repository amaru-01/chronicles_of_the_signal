"""
Chronicles of the Signal
Main entry point - initializes the Arcade window and boots the
central ViewManager, then pushes the MenuView as the first screen.

Web Note: under PyScript/Pyodide this file is executed as the
top-level script referenced in index.html via
<script type="py" src="main.py" config="pyscript.toml">.
"""

import arcade

from core.constants import SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_TITLE
from core.view_manager import ViewManager
from core.game_state import GameState
from views.menu_view import MenuView


def main():
    """Application bootstrap."""
    window = arcade.Window(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_TITLE, resizable=True)

    # Persistent state container survives across View swaps.
    game_state = GameState()

    # ViewManager hangs off the window so every View can reach it via
    # self.window.view_manager without threading references everywhere.
    window.view_manager = ViewManager(window, game_state)

    # Boot straight into the main menu.
    window.show_view(MenuView())

    arcade.run()


if __name__ == "__main__":
    main()
