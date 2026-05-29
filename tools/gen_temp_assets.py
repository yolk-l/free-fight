"""Generate temporary pixel-art assets for FreeFight demo.

Usage:
    python tools/gen_temp_assets.py              # generate all
    python tools/gen_temp_assets.py bat viper    # generate specific assets
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

from asset_config import ASSETS
from drawers import DRAWERS


def generate(name):
    if name not in ASSETS:
        print(f"  [SKIP] unknown asset: {name}")
        return
    if name not in DRAWERS:
        print(f"  [SKIP] no drawer for: {name}")
        return

    config = ASSETS[name]
    img = Image.new("RGBA", config["size"], (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    DRAWERS[name](img, d, config)

    output = Path(config["output"])
    output.parent.mkdir(parents=True, exist_ok=True)
    img.save(output)
    print(f"  saved {output}")


if __name__ == "__main__":
    print("Generating temporary pixel-art assets...")

    names = sys.argv[1:] if len(sys.argv) > 1 else list(ASSETS.keys())
    for name in names:
        generate(name)

    print("Done!")
