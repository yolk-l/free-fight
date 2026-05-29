"""Generate simple pixel-art terrain icons (64x64) for FreeFight demo."""
from PIL import Image, ImageDraw

SIZE = 64
OUT_DIR = "../assets/terrains"


def put(img, x, y, color):
    """Draw a single pixel if within bounds."""
    if 0 <= x < SIZE and 0 <= y < SIZE:
        img.putpixel((x, y), color)


def fill_rect(draw, x1, y1, x2, y2, color):
    draw.rectangle([x1, y1, x2, y2], fill=color)


def fill_circle(draw, cx, cy, r, color):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)


def draw_outline_circle(draw, cx, cy, r, color, width=1):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color, width=width)


# ─── 1. 共鸣祭坛 (Resonance Altar) ───
# Purple altar with glowing runes
def gen_resonance_altar():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Base platform - stone gray
    stone = (100, 90, 110, 255)
    stone_light = (130, 120, 140, 255)
    stone_dark = (70, 60, 80, 255)

    # Platform base
    fill_rect(draw, 12, 42, 51, 55, stone)
    fill_rect(draw, 16, 40, 47, 42, stone_light)
    fill_rect(draw, 12, 55, 51, 58, stone_dark)

    # Altar pillar
    fill_rect(draw, 24, 18, 39, 42, stone)
    fill_rect(draw, 22, 16, 41, 18, stone_light)

    # Purple glow on top
    purple = (153, 77, 230, 255)
    purple_light = (190, 130, 255, 255)
    purple_dark = (100, 40, 160, 255)

    # Crystal/orb on top
    fill_circle(draw, 31, 14, 6, purple)
    fill_circle(draw, 31, 13, 4, purple_light)
    fill_circle(draw, 30, 12, 2, (220, 180, 255, 255))

    # Rune markings on pillar
    for y in range(22, 40, 4):
        fill_rect(draw, 27, y, 29, y + 2, purple)
        fill_rect(draw, 34, y, 36, y + 2, purple)

    # Glow particles
    for pos in [(18, 10), (44, 12), (14, 28), (48, 30), (20, 48)]:
        put(img, pos[0], pos[1], (190, 130, 255, 180))
        put(img, pos[0] + 1, pos[1], (190, 130, 255, 120))

    img.save(f"{OUT_DIR}/resonance_altar.png")
    return img


# ─── 2. 荆棘地 (Thorns) ───
# Brown thorny ground with spikes
def gen_thorns():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    brown = (140, 100, 60, 255)
    brown_dark = (90, 60, 30, 255)
    brown_light = (170, 130, 80, 255)
    thorn = (100, 70, 40, 255)
    thorn_tip = (160, 120, 70, 255)

    # Ground base
    fill_rect(draw, 8, 44, 55, 56, brown)
    fill_rect(draw, 10, 42, 53, 44, brown_light)
    fill_rect(draw, 8, 56, 55, 59, brown_dark)

    # Thorn branches - several spiky vines
    # Left branch
    points_l = [(16, 44), (14, 38), (12, 32), (10, 26), (8, 20), (10, 14)]
    for i, (x, y) in enumerate(points_l):
        fill_rect(draw, x, y, x + 2, y + 3, thorn)
        # Spikes
        if i % 2 == 0:
            put(img, x - 2, y - 1, thorn_tip)
            put(img, x - 1, y - 2, thorn_tip)
        else:
            put(img, x + 3, y - 1, thorn_tip)
            put(img, x + 4, y - 2, thorn_tip)

    # Center branch
    points_c = [(30, 44), (30, 38), (30, 32), (30, 26), (30, 20), (30, 14), (30, 8)]
    for i, (x, y) in enumerate(points_c):
        fill_rect(draw, x, y, x + 3, y + 3, thorn)
        if i % 2 == 0:
            put(img, x - 2, y, thorn_tip)
            put(img, x - 3, y - 1, thorn_tip)
        else:
            put(img, x + 4, y, thorn_tip)
            put(img, x + 5, y - 1, thorn_tip)

    # Right branch
    points_r = [(44, 44), (46, 38), (48, 32), (46, 26), (44, 20), (46, 14)]
    for i, (x, y) in enumerate(points_r):
        fill_rect(draw, x, y, x + 2, y + 3, thorn)
        if i % 2 == 0:
            put(img, x + 3, y - 1, thorn_tip)
            put(img, x + 4, y - 2, thorn_tip)
        else:
            put(img, x - 2, y - 1, thorn_tip)
            put(img, x - 1, y - 2, thorn_tip)

    # Red berries/blood drops
    red = (200, 50, 50, 255)
    for pos in [(12, 30), (35, 18), (48, 28), (26, 12)]:
        fill_rect(draw, pos[0], pos[1], pos[0] + 2, pos[1] + 2, red)

    img.save(f"{OUT_DIR}/thorns.png")
    return img


# ─── 3. 圣光圈 (Sanctuary) ───
# Golden holy circle with light rays
def gen_sanctuary():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    gold = (255, 220, 100, 255)
    gold_light = (255, 240, 170, 255)
    gold_dark = (200, 170, 60, 255)
    white = (255, 255, 240, 255)

    # Outer ring
    draw_outline_circle(draw, 31, 31, 24, gold, 3)
    draw_outline_circle(draw, 31, 31, 21, gold_dark, 2)

    # Inner cross/star pattern
    # Vertical beam
    fill_rect(draw, 29, 12, 33, 50, (255, 230, 130, 150))
    # Horizontal beam
    fill_rect(draw, 12, 29, 50, 33, (255, 230, 130, 150))

    # Center bright circle
    fill_circle(draw, 31, 31, 6, gold)
    fill_circle(draw, 31, 31, 4, gold_light)
    fill_circle(draw, 31, 30, 2, white)

    # Light ray dots at cardinal points
    for pos in [(31, 6), (31, 56), (6, 31), (56, 31)]:
        fill_rect(draw, pos[0] - 1, pos[1] - 1, pos[0] + 1, pos[1] + 1, gold_light)

    # Diagonal sparkle dots
    for pos in [(16, 16), (46, 16), (16, 46), (46, 46)]:
        put(img, pos[0], pos[1], gold)
        put(img, pos[0] + 1, pos[1], (255, 240, 170, 140))
        put(img, pos[0], pos[1] + 1, (255, 240, 170, 140))

    img.save(f"{OUT_DIR}/sanctuary.png")
    return img


# ─── 4. 暗影域 (Shadow) ───
# Dark purple shadow zone with eyes
def gen_shadow():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    dark = (30, 15, 50, 255)
    mid = (60, 30, 90, 255)
    purple = (90, 50, 130, 255)
    eye_yellow = (255, 220, 50, 255)

    # Dark cloud/smoke shape
    fill_circle(draw, 31, 35, 18, dark)
    fill_circle(draw, 22, 30, 12, dark)
    fill_circle(draw, 40, 30, 12, dark)
    fill_circle(draw, 31, 22, 14, dark)

    # Inner swirl details
    fill_circle(draw, 26, 26, 6, mid)
    fill_circle(draw, 38, 28, 5, mid)
    fill_circle(draw, 31, 36, 7, mid)

    # Glowing eyes
    fill_rect(draw, 22, 28, 26, 31, eye_yellow)
    fill_rect(draw, 36, 28, 40, 31, eye_yellow)
    # Pupils
    fill_rect(draw, 24, 29, 26, 30, dark)
    fill_rect(draw, 38, 29, 40, 30, dark)

    # Wispy edges
    for pos in [(12, 38), (50, 36), (14, 22), (48, 24), (31, 10)]:
        put(img, pos[0], pos[1], (60, 30, 90, 160))
        put(img, pos[0] + 1, pos[1] - 1, (60, 30, 90, 100))
        put(img, pos[0] - 1, pos[1] + 1, (60, 30, 90, 100))

    # Subtle purple glow particles
    for pos in [(18, 18), (44, 20), (16, 42), (46, 44), (31, 50)]:
        put(img, pos[0], pos[1], (120, 70, 170, 140))

    img.save(f"{OUT_DIR}/shadow.png")
    return img


# ─── 5. 共鸣节点 (Resonance Node) ───
# Blue energy node with arcing electricity
def gen_resonance_node():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    blue = (70, 140, 255, 255)
    blue_light = (140, 190, 255, 255)
    blue_dark = (30, 80, 180, 255)
    white = (220, 240, 255, 255)

    # Outer hexagon-ish shape using circles
    draw_outline_circle(draw, 31, 31, 22, blue_dark, 2)

    # Inner energy core
    fill_circle(draw, 31, 31, 10, blue)
    fill_circle(draw, 31, 30, 7, blue_light)
    fill_circle(draw, 31, 29, 4, white)

    # Energy arcs - simple lightning lines
    # Top arc
    arc_points = [(31, 19), (28, 15), (31, 11), (34, 7)]
    for x, y in arc_points:
        fill_rect(draw, x, y, x + 1, y + 2, blue_light)

    # Bottom arc
    arc_points = [(31, 43), (34, 47), (31, 51), (28, 55)]
    for x, y in arc_points:
        fill_rect(draw, x, y, x + 1, y + 2, blue_light)

    # Left arc
    arc_points = [(19, 31), (15, 28), (11, 31), (7, 34)]
    for x, y in arc_points:
        fill_rect(draw, x, y, x + 2, y + 1, blue_light)

    # Right arc
    arc_points = [(43, 31), (47, 34), (51, 31), (55, 28)]
    for x, y in arc_points:
        fill_rect(draw, x, y, x + 2, y + 1, blue_light)

    # Sparkle dots
    for pos in [(18, 18), (44, 18), (18, 44), (44, 44)]:
        put(img, pos[0], pos[1], blue_light)
        put(img, pos[0] + 1, pos[1], (140, 190, 255, 120))

    # Ring nodes
    for pos in [(31, 8), (31, 54), (8, 31), (54, 31)]:
        fill_rect(draw, pos[0] - 1, pos[1] - 1, pos[0] + 1, pos[1] + 1, white)

    img.save(f"{OUT_DIR}/resonance_node.png")
    return img


# ─── 6. 腐毒地 (Poison Land) ───
# Green toxic swamp with bubbles
def gen_poison_land():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    green = (60, 180, 60, 255)
    green_dark = (30, 120, 30, 255)
    green_light = (100, 220, 80, 255)
    green_glow = (140, 255, 100, 255)
    brown = (80, 60, 40, 255)

    # Swamp puddle base
    fill_circle(draw, 31, 38, 20, green_dark)
    fill_circle(draw, 25, 36, 14, green)
    fill_circle(draw, 38, 38, 12, green)
    fill_circle(draw, 31, 42, 16, green_dark)

    # Toxic surface highlights
    fill_circle(draw, 24, 34, 5, green_light)
    fill_circle(draw, 38, 36, 4, green_light)

    # Bubbles
    draw_outline_circle(draw, 20, 30, 3, green_glow, 1)
    put(img, 19, 28, (200, 255, 180, 200))

    draw_outline_circle(draw, 36, 32, 4, green_glow, 1)
    put(img, 35, 30, (200, 255, 180, 200))

    draw_outline_circle(draw, 28, 26, 2, green_glow, 1)
    put(img, 27, 25, (200, 255, 180, 200))

    # Rising vapor/skull hint
    # Small skull shape
    skull = (200, 255, 180, 200)
    fill_circle(draw, 31, 14, 6, (80, 180, 80, 180))
    fill_circle(draw, 31, 14, 4, skull)
    # Eye sockets
    fill_rect(draw, 28, 13, 30, 15, green_dark)
    fill_rect(draw, 32, 13, 34, 15, green_dark)
    # Nose
    put(img, 31, 16, green_dark)
    # Teeth
    fill_rect(draw, 29, 18, 33, 19, skull)
    put(img, 30, 18, green_dark)
    put(img, 32, 18, green_dark)

    # Drip drops
    for pos in [(22, 22), (40, 24), (15, 40), (47, 42)]:
        put(img, pos[0], pos[1], green_glow)

    img.save(f"{OUT_DIR}/poison_land.png")
    return img


if __name__ == "__main__":
    import os
    os.makedirs(OUT_DIR, exist_ok=True)

    gen_resonance_altar()
    gen_thorns()
    gen_sanctuary()
    gen_shadow()
    gen_resonance_node()
    gen_poison_land()

    print("Generated 6 terrain icons in", OUT_DIR)
