"""Draw a 32x32 chainmail armor."""


def draw(img, d, config):
    c = config["colors"]
    metal = c["metal"]
    metal_light = c["metal_light"]
    metal_dark = c["metal_dark"]
    trim = c["trim"]

    d.rectangle([8, 4, 24, 24], fill=metal)

    d.rectangle([4, 4, 8, 10], fill=metal)
    d.rectangle([24, 4, 28, 10], fill=metal)

    d.arc([12, 2, 20, 8], 180, 0, fill=metal_dark, width=1)
    d.rectangle([12, 2, 20, 5], fill=(0, 0, 0, 0))
    d.ellipse([12, 1, 20, 7], fill=(0, 0, 0, 0))

    for row in range(0, 18, 3):
        offset = 1 if (row // 3) % 2 == 1 else 0
        for col in range(0, 16, 3):
            cx = 9 + col + offset
            cy = 6 + row
            if img.getpixel((cx, cy))[3] > 0:
                d.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], outline=metal_dark)
                img.putpixel((cx, cy - 1), metal_light)

    d.rectangle([8, 22, 24, 24], fill=trim)
    d.line([(4, 4), (28, 4)], fill=trim, width=1)

    d.rectangle([4, 10, 8, 12], fill=metal_dark)
    d.rectangle([24, 10, 28, 12], fill=metal_dark)

    d.rectangle([10, 24, 22, 28], fill=metal)
    d.line([(16, 24), (16, 28)], fill=metal_dark, width=1)
    d.rectangle([10, 27, 22, 28], fill=trim)
