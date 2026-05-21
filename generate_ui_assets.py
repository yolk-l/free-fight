from PIL import Image, ImageDraw
import math


def generate_battle_bg(path, w=1280, h=720):
    img = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        r = int(18 + t * 8)
        g = int(20 + t * 6)
        b = int(28 + t * 10)
        d.line([(0, y), (w, y)], fill=(r, g, b, 255))
    for gx in range(0, w, 48):
        for gy in range(0, h, 48):
            dot_alpha = 20 + int(10 * math.sin(gx * 0.05) * math.cos(gy * 0.05))
            d.rectangle([gx, gy, gx + 1, gy + 1], fill=(60, 70, 90, dot_alpha))
    for x in range(0, w, 48):
        d.line([(x, 0), (x, h)], fill=(40, 45, 55, 12))
    for y in range(0, h, 48):
        d.line([(0, y), (w, y)], fill=(40, 45, 55, 12))
    img.save(path)


def generate_panel_bg(path, w=1280, h=160):
    img = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        a = int(200 + t * 40)
        d.line([(0, y), (w, y)], fill=(22, 24, 32, a))
    d.line([(0, 0), (w, 0)], fill=(70, 130, 200, 120), width=2)
    img.save(path)


def generate_equip_slot_bg(path, size=48):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=6,
                        fill=(30, 32, 42, 200), outline=(70, 80, 100, 180), width=2)
    d.line([(4, 4), (size - 5, size - 5)], fill=(50, 55, 70, 60), width=1)
    d.line([(size - 5, 4), (4, size - 5)], fill=(50, 55, 70, 60), width=1)
    img.save(path)


def generate_card_bg(path, w=100, h=80):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=8,
                        fill=(28, 32, 45, 230), outline=(80, 100, 140, 200), width=2)
    d.rounded_rectangle([4, 4, w - 5, h - 5], radius=6,
                        fill=None, outline=(60, 70, 100, 80), width=1)
    img.save(path)


def generate_hp_bar_fill(path, w=140, h=16):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=4,
                        fill=(60, 200, 80, 255))
    d.rounded_rectangle([0, 0, w - 1, h // 2], radius=4,
                        fill=(100, 230, 120, 80))
    img.save(path)


def generate_hp_bar_bg(path, w=140, h=16):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=4,
                        fill=(20, 22, 30, 220), outline=(50, 55, 70, 180), width=1)
    img.save(path)


def generate_menu_bg(path, w=1280, h=720):
    img = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(img)
    cx, cy = w // 2, h // 2
    max_dist = math.sqrt(cx * cx + cy * cy)
    for y in range(h):
        for x in range(w):
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            t = dist / max_dist
            r = int(15 + t * 12)
            g = int(18 + t * 8)
            b = int(30 + t * 15)
            img.putpixel((x, y), (r, g, b, 255))
    for i in range(80):
        sx = int((hash(i * 7 + 3) % 1000) / 1000 * w)
        sy = int((hash(i * 13 + 7) % 1000) / 1000 * h)
        brightness = 60 + hash(i * 17) % 60
        size = 1 + hash(i * 23) % 2
        d.ellipse([sx, sy, sx + size, sy + size], fill=(brightness, brightness, brightness + 20, 120))
    img.save(path)


def generate_drop_zone_frame(path, w=540, h=480):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    dash_len = 12
    gap_len = 8
    color = (70, 130, 200, 60)
    for x in range(0, w, dash_len + gap_len):
        d.line([(x, 0), (min(x + dash_len, w), 0)], fill=color, width=2)
        d.line([(x, h - 1), (min(x + dash_len, w), h - 1)], fill=color, width=2)
    for y in range(0, h, dash_len + gap_len):
        d.line([(0, y), (0, min(y + dash_len, h))], fill=color, width=2)
        d.line([(w - 1, y), (w - 1, min(y + dash_len, h))], fill=color, width=2)
    img.save(path)


if __name__ == "__main__":
    import os
    base = "D:/learn/free-fight/assets/ui"
    os.makedirs(base, exist_ok=True)

    print("Generating battle background...")
    generate_battle_bg(f"{base}/battle_bg.png")

    print("Generating menu background...")
    generate_menu_bg(f"{base}/menu_bg.png")

    print("Generating panel background...")
    generate_panel_bg(f"{base}/panel_bg.png")

    print("Generating equip slot...")
    generate_equip_slot_bg(f"{base}/equip_slot.png")

    print("Generating card background...")
    generate_card_bg(f"{base}/card_bg.png")

    print("Generating HP bar assets...")
    generate_hp_bar_fill(f"{base}/hp_fill.png")
    generate_hp_bar_bg(f"{base}/hp_bg.png")

    print("Generating drop zone frame...")
    generate_drop_zone_frame(f"{base}/drop_zone_frame.png")

    print("All UI assets generated!")
