"""Generate temporary pixel-art assets for FreeFight demo."""
from PIL import Image, ImageDraw


def put_pixels(img, pixels, color):
    for x, y in pixels:
        if 0 <= x < img.width and 0 <= y < img.height:
            img.putpixel((x, y), color)


def draw_bat(path):
    """64x64 purple bat with spread wings."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    wing_color = (120, 60, 160)
    body_color = (90, 40, 130)
    eye_color = (255, 50, 50)
    wing_membrane = (150, 90, 190)

    # Body (oval)
    d.ellipse([26, 24, 38, 40], fill=body_color)

    # Head
    d.ellipse([28, 18, 36, 28], fill=body_color)

    # Ears
    ear_l = [(28, 18), (26, 12), (30, 17)]
    ear_r = [(36, 18), (38, 12), (34, 17)]
    d.polygon(ear_l, fill=body_color)
    d.polygon(ear_r, fill=body_color)

    # Eyes
    img.putpixel((30, 22), eye_color)
    img.putpixel((31, 22), eye_color)
    img.putpixel((33, 22), eye_color)
    img.putpixel((34, 22), eye_color)

    # Left wing
    wing_l = [(26, 28), (6, 18), (4, 24), (8, 32), (14, 36), (24, 38)]
    d.polygon(wing_l, fill=wing_color)
    # Wing bone lines
    d.line([(26, 28), (6, 18)], fill=body_color, width=1)
    d.line([(26, 30), (4, 24)], fill=body_color, width=1)
    d.line([(26, 32), (8, 32)], fill=body_color, width=1)
    # Wing membrane highlight
    d.line([(16, 22), (12, 28)], fill=wing_membrane, width=1)
    d.line([(20, 26), (16, 32)], fill=wing_membrane, width=1)

    # Right wing (mirror)
    wing_r = [(38, 28), (58, 18), (60, 24), (56, 32), (50, 36), (40, 38)]
    d.polygon(wing_r, fill=wing_color)
    d.line([(38, 28), (58, 18)], fill=body_color, width=1)
    d.line([(38, 30), (60, 24)], fill=body_color, width=1)
    d.line([(38, 32), (56, 32)], fill=body_color, width=1)
    d.line([(48, 22), (52, 28)], fill=wing_membrane, width=1)
    d.line([(44, 26), (48, 32)], fill=wing_membrane, width=1)

    # Feet
    put_pixels(img, [(30, 40), (31, 41), (33, 40), (34, 41)], body_color)

    # Mouth / fangs
    img.putpixel((31, 26), (255, 255, 255))
    img.putpixel((33, 26), (255, 255, 255))

    img.save(path)
    print(f"  saved {path}")


def draw_gargoyle(path):
    """64x64 gray stone gargoyle."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    stone = (110, 110, 120)
    stone_dark = (80, 80, 90)
    stone_light = (140, 140, 150)
    eye_color = (220, 180, 40)
    horn_color = (90, 85, 80)

    # Body
    d.rectangle([22, 28, 42, 50], fill=stone)
    # Shading
    d.rectangle([22, 28, 26, 50], fill=stone_dark)
    d.rectangle([38, 28, 42, 50], fill=stone_dark)

    # Head
    d.rectangle([24, 12, 40, 28], fill=stone)
    d.rectangle([24, 12, 28, 16], fill=stone_dark)
    d.rectangle([36, 12, 40, 16], fill=stone_dark)

    # Horns
    horn_l = [(24, 14), (18, 6), (22, 12)]
    horn_r = [(40, 14), (46, 6), (42, 12)]
    d.polygon(horn_l, fill=horn_color)
    d.polygon(horn_r, fill=horn_color)

    # Eyes (glowing)
    d.rectangle([27, 18, 30, 21], fill=eye_color)
    d.rectangle([34, 18, 37, 21], fill=eye_color)
    # Eye pupils
    img.putpixel((28, 19), (180, 140, 20))
    img.putpixel((35, 19), (180, 140, 20))

    # Mouth (grim)
    d.line([(28, 24), (36, 24)], fill=stone_dark, width=1)
    # Fangs
    put_pixels(img, [(29, 25), (30, 26), (34, 25), (35, 26)], (200, 200, 200))

    # Wings (small, folded)
    wing_l = [(22, 30), (10, 22), (8, 30), (12, 38), (22, 40)]
    wing_r = [(42, 30), (54, 22), (56, 30), (52, 38), (42, 40)]
    d.polygon(wing_l, fill=stone_dark)
    d.polygon(wing_r, fill=stone_dark)
    # Wing edges
    d.line([(22, 30), (10, 22)], fill=stone_light, width=1)
    d.line([(22, 34), (8, 30)], fill=stone_light, width=1)
    d.line([(42, 30), (54, 22)], fill=stone_light, width=1)
    d.line([(42, 34), (56, 30)], fill=stone_light, width=1)

    # Legs
    d.rectangle([24, 50, 30, 58], fill=stone)
    d.rectangle([34, 50, 40, 58], fill=stone)
    # Claws
    put_pixels(img, [(24, 58), (27, 58), (30, 58)], stone_dark)
    put_pixels(img, [(34, 58), (37, 58), (40, 58)], stone_dark)

    # Arms
    d.rectangle([18, 32, 22, 42], fill=stone)
    d.rectangle([42, 32, 46, 42], fill=stone)
    # Claws on hands
    put_pixels(img, [(18, 42), (20, 43), (22, 42)], stone_dark)
    put_pixels(img, [(42, 42), (44, 43), (46, 42)], stone_dark)

    # Stone texture (scattered lighter pixels)
    import random
    random.seed(42)
    for _ in range(30):
        tx = random.randint(23, 41)
        ty = random.randint(13, 49)
        if img.getpixel((tx, ty))[3] > 0:
            img.putpixel((tx, ty), stone_light)

    img.save(path)
    print(f"  saved {path}")


def draw_dagger(path):
    """32x32 short dagger."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    blade = (190, 200, 210)
    blade_edge = (220, 225, 235)
    guard = (160, 130, 50)
    handle = (100, 70, 40)
    pommel = (140, 110, 50)

    # Blade (diagonal, short)
    blade_poly = [(18, 4), (20, 4), (17, 16), (15, 16)]
    d.polygon(blade_poly, fill=blade)
    # Blade highlight
    d.line([(19, 5), (17, 14)], fill=blade_edge, width=1)
    # Blade tip
    d.polygon([(18, 4), (20, 4), (19, 2)], fill=blade_edge)

    # Guard (crossguard)
    d.rectangle([12, 16, 22, 18], fill=guard)

    # Handle
    d.rectangle([15, 18, 19, 26], fill=handle)
    # Handle wrap lines
    for y in range(19, 26, 2):
        d.line([(15, y), (19, y)], fill=(80, 55, 30), width=1)

    # Pommel
    d.ellipse([14, 26, 20, 30], fill=pommel)

    img.save(path)
    print(f"  saved {path}")


def draw_iron_sword(path):
    """32x32 iron sword, more refined than wood sword."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    blade = (170, 180, 195)
    blade_light = (210, 215, 225)
    blade_dark = (130, 140, 155)
    guard = (180, 160, 60)
    handle = (90, 60, 35)
    pommel = (180, 160, 60)

    # Blade (long, vertical)
    d.polygon([(15, 2), (17, 2), (17, 18), (15, 18)], fill=blade)
    # Blade tip
    d.polygon([(15, 2), (17, 2), (16, 0)], fill=blade_light)
    # Blade highlight (center line)
    d.line([(16, 1), (16, 18)], fill=blade_light, width=1)
    # Blade edges
    d.line([(14, 3), (14, 18)], fill=blade_dark, width=1)
    d.line([(18, 3), (18, 18)], fill=blade_dark, width=1)

    # Fuller (groove)
    d.line([(16, 4), (16, 16)], fill=blade_dark, width=1)

    # Guard
    d.rectangle([10, 18, 22, 20], fill=guard)
    d.rectangle([10, 18, 11, 20], fill=(150, 130, 40))
    d.rectangle([21, 18, 22, 20], fill=(150, 130, 40))

    # Handle
    d.rectangle([14, 20, 18, 28], fill=handle)
    for y in range(21, 28, 2):
        d.line([(14, y), (18, y)], fill=(70, 45, 25), width=1)

    # Pommel
    d.ellipse([13, 28, 19, 32], fill=pommel)

    img.save(path)
    print(f"  saved {path}")


def draw_chainmail(path):
    """32x32 chainmail armor."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    metal = (160, 165, 175)
    metal_light = (200, 205, 215)
    metal_dark = (120, 125, 135)
    trim = (180, 160, 60)

    # Torso shape
    d.rectangle([8, 4, 24, 24], fill=metal)

    # Shoulders
    d.rectangle([4, 4, 8, 10], fill=metal)
    d.rectangle([24, 4, 28, 10], fill=metal)

    # Neckline
    d.arc([12, 2, 20, 8], 180, 0, fill=metal_dark, width=1)
    d.rectangle([12, 2, 20, 5], fill=(0, 0, 0, 0))
    d.ellipse([12, 1, 20, 7], fill=(0, 0, 0, 0))

    # Chain mail pattern (small rings)
    for row in range(0, 18, 3):
        offset = 1 if (row // 3) % 2 == 1 else 0
        for col in range(0, 16, 3):
            cx = 9 + col + offset
            cy = 6 + row
            if img.getpixel((cx, cy))[3] > 0:
                d.ellipse([cx - 1, cy - 1, cx + 1, cy + 1],
                          outline=metal_dark)
                img.putpixel((cx, cy - 1), metal_light)

    # Bottom trim
    d.rectangle([8, 22, 24, 24], fill=trim)

    # Shoulder trim
    d.line([(4, 4), (28, 4)], fill=trim, width=1)

    # Sleeve openings
    d.rectangle([4, 10, 8, 12], fill=metal_dark)
    d.rectangle([24, 10, 28, 12], fill=metal_dark)

    # Bottom skirt (short)
    d.rectangle([10, 24, 22, 28], fill=metal)
    # Skirt split
    d.line([(16, 24), (16, 28)], fill=metal_dark, width=1)
    d.rectangle([10, 27, 22, 28], fill=trim)

    img.save(path)
    print(f"  saved {path}")


if __name__ == "__main__":
    print("Generating temporary pixel-art assets...")
    draw_bat("assets/monsters/bat.png")
    draw_gargoyle("assets/monsters/gargoyle.png")
    draw_dagger("assets/equipment/dagger.png")
    draw_iron_sword("assets/equipment/iron_sword.png")
    draw_chainmail("assets/equipment/chainmail.png")
    print("Done!")
