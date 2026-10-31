"""Generate minimal valid Tiled map files for testing."""

import json
import os
from pathlib import Path


def create_tileset_image():
    """Create a simple tileset image if it doesn't exist."""
    try:
        from PIL import Image
        tileset_path = Path("assets/maps/tileset/tiles.png")
        if not tileset_path.exists():
            # Create a simple 32x32 blue tile
            img = Image.new('RGB', (32, 32), color=(100, 100, 255))
            tileset_path.parent.mkdir(parents=True, exist_ok=True)
            img.save(tileset_path)
            print(f"Created tileset image: {tileset_path}")
    except ImportError:
        print("PIL not available, skipping tileset image creation")


def create_minimal_map_json(district_name: str, layer_type: str):
    """Create a minimal valid Tiled map JSON file."""
    map_path = Path(f"assets/maps/{district_name}_{layer_type}.json")
    map_path.parent.mkdir(parents=True, exist_ok=True)

    # Determine which layers to include based on type
    if layer_type == "physical":
        layers = [
            {
                "data": [0] * 800,  # 40x20 grid
                "height": 20,
                "id": 1,
                "name": "Walls_Physical",
                "opacity": 1,
                "type": "tilelayer",
                "visible": True,
                "width": 40,
                "x": 0,
                "y": 0
            },
            {
                "data": [0] * 800,
                "height": 20,
                "id": 2,
                "name": "Decor_Physical",
                "opacity": 1,
                "type": "tilelayer",
                "visible": True,
                "width": 40,
                "x": 0,
                "y": 0
            },
            {
                "draworder": "topdown",
                "id": 3,
                "name": "Spawns",
                "objects": [
                    {
                        "id": 1,
                        "name": "PlayerStart",
                        "point": True,
                        "x": 128,
                        "y": 128,
                        "width": 0,
                        "height": 0,
                        "rotation": 0,
                        "visible": True
                    }
                ],
                "opacity": 1,
                "type": "objectgroup",
                "visible": True,
                "x": 0,
                "y": 0
            }
        ]
    else:  # digital
        layers = [
            {
                "data": [0] * 800,
                "height": 20,
                "id": 1,
                "name": "Walls_Digital",
                "opacity": 1,
                "type": "tilelayer",
                "visible": False,
                "width": 40,
                "x": 0,
                "y": 0
            },
            {
                "data": [0] * 800,
                "height": 20,
                "id": 2,
                "name": "Decor_Digital",
                "opacity": 1,
                "type": "tilelayer",
                "visible": False,
                "width": 40,
                "x": 0,
                "y": 0
            },
            {
                "data": [0] * 800,
                "height": 20,
                "id": 3,
                "name": "Fragments_Digital",
                "opacity": 1,
                "type": "tilelayer",
                "visible": False,
                "width": 40,
                "x": 0,
                "y": 0
            }
        ]

    map_data = {
        "compressionlevel": -1,
        "height": 20,
        "infinite": False,
        "layers": layers,
        "nextlayerid": len(layers) + 1,
        "nextobjectid": 2,
        "orientation": "orthogonal",
        "renderorder": "right-down",
        "tiledversion": "1.4.3",
        "tileheight": 32,
        "tilesets": [
            {
                "firstgid": 1,
                "source": "tileset/cyberpunk_tiles.tsx"
            }
        ],
        "tilewidth": 32,
        "type": "map",
        "version": "1.4",
        "width": 40
    }

    with open(map_path, 'w') as f:
        json.dump(map_data, f, indent=2)
    print(f"Created map file: {map_path}")


def create_tileset_tsx():
    """Create the tileset TSX file."""
    tileset_path = Path("assets/maps/tileset/cyberpunk_tiles.tsx")
    tileset_path.parent.mkdir(parents=True, exist_ok=True)

    tileset_content = """<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.4" tiledversion="1.4.3" name="cyberpunk_tiles" tilewidth="32" tileheight="32" tilecount="1" columns="1">
 <image source="tiles.png" width="32" height="32"/>
</tileset>
"""
    with open(tileset_path, 'w') as f:
        f.write(tileset_content)
    print(f"Created tileset file: {tileset_path}")


if __name__ == "__main__":
    # Create tileset
    create_tileset_tsx()
    create_tileset_image()

    # Generate maps for district_01
    create_minimal_map_json("district_01", "physical")
    create_minimal_map_json("district_01", "digital")

    print("\nMap generation complete!")
