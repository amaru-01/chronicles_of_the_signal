"""
Guideline: Arcade's loaders are synchronous, but under Pyodide a network
fetch must land in the virtual filesystem first. pyscript.toml's [files]
table handles that at boot for critical assets. For per-district lazy
loading (so the whole game isn't downloaded on first paint), fetch bytes
manually before calling arcade.load_tilemap() / load_sound().
"""

from pyodide.http import pyfetch


async def ensure_asset(remote_url: str, local_path: str):
    """Download an asset into Pyodide's virtual FS on demand, if missing."""
    import os
    if os.path.exists(local_path):
        return
    response = await pyfetch(remote_url)
    data = await response.bytes()
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    with open(local_path, "wb") as f:
        f.write(data)


async def load_district_assets(district_name: str):
    """Call this from an async transition hook before MapLoader.load()."""
    await ensure_asset(
        f"assets/maps/{district_name}_physical.json",
        f"assets/maps/{district_name}_physical.json",
    )
    await ensure_asset(
        f"assets/maps/{district_name}_digital.json",
        f"assets/maps/{district_name}_digital.json",
    )
    await ensure_asset(
        f"assets/sounds/ambient/{district_name}_ambient.ogg",
        f"assets/sounds/ambient/{district_name}_ambient.ogg",
    )
    # Now safe to call MapLoader(district_name).load() synchronously.
