"""Draw a 64x64 gray stone gargoyle."""
import random

from .common import put_pixels


def draw(img, d, config):
    c = config["colors"]
    stone = c["stone"]
    stone_dark = c["stone_dark"]
    stone_light = c["stone_light"]
    eye_color = c["eye"]
    horn_color = c["horn"]

    d.rectangle([22, 28, 42, 50], fill=stone)
    d.rectangle([22, 28, 26, 50], fill=stone_dark)
    d.rectangle([38, 28, 42, 50], fill=stone_dark)

    d.rectangle([24, 12, 40, 28], fill=stone)
    d.rectangle([24, 12, 28, 16], fill=stone_dark)
    d.rectangle([36, 12, 40, 16], fill=stone_dark)

    d.polygon([(24, 14), (18, 6), (22, 12)], fill=horn_color)
    d.polygon([(40, 14), (46, 6), (42, 12)], fill=horn_color)

    d.rectangle([27, 18, 30, 21], fill=eye_color)
    d.rectangle([34, 18, 37, 21], fill=eye_color)
    img.putpixel((28, 19), (180, 140, 20))
    img.putpixel((35, 19), (180, 140, 20))

    d.line([(28, 24), (36, 24)], fill=stone_dark, width=1)
    put_pixels(img, [(29, 25), (30, 26), (34, 25), (35, 26)], (200, 200, 200))

    wing_l = [(22, 30), (10, 22), (8, 30), (12, 38), (22, 40)]
    wing_r = [(42, 30), (54, 22), (56, 30), (52, 38), (42, 40)]
    d.polygon(wing_l, fill=stone_dark)
    d.polygon(wing_r, fill=stone_dark)
    d.line([(22, 30), (10, 22)], fill=stone_light, width=1)
    d.line([(22, 34), (8, 30)], fill=stone_light, width=1)
    d.line([(42, 30), (54, 22)], fill=stone_light, width=1)
    d.line([(42, 34), (56, 30)], fill=stone_light, width=1)

    d.rectangle([24, 50, 30, 58], fill=stone)
    d.rectangle([34, 50, 40, 58], fill=stone)
    put_pixels(img, [(24, 58), (27, 58), (30, 58)], stone_dark)
    put_pixels(img, [(34, 58), (37, 58), (40, 58)], stone_dark)

    d.rectangle([18, 32, 22, 42], fill=stone)
    d.rectangle([42, 32, 46, 42], fill=stone)
    put_pixels(img, [(18, 42), (20, 43), (22, 42)], stone_dark)
    put_pixels(img, [(42, 42), (44, 43), (46, 42)], stone_dark)

    random.seed(config.get("texture_seed", 42))
    for _ in range(30):
        tx = random.randint(23, 41)
        ty = random.randint(13, 49)
        if img.getpixel((tx, ty))[3] > 0:
            img.putpixel((tx, ty), stone_light)
