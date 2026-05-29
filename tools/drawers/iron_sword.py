"""Draw a 32x32 iron sword."""


def draw(img, d, config):
    c = config["colors"]
    blade = c["blade"]
    blade_light = c["blade_light"]
    blade_dark = c["blade_dark"]
    guard = c["guard"]
    handle = c["handle"]
    pommel = c["pommel"]

    d.polygon([(15, 2), (17, 2), (17, 18), (15, 18)], fill=blade)
    d.polygon([(15, 2), (17, 2), (16, 0)], fill=blade_light)
    d.line([(16, 1), (16, 18)], fill=blade_light, width=1)
    d.line([(14, 3), (14, 18)], fill=blade_dark, width=1)
    d.line([(18, 3), (18, 18)], fill=blade_dark, width=1)

    d.line([(16, 4), (16, 16)], fill=blade_dark, width=1)

    d.rectangle([10, 18, 22, 20], fill=guard)
    d.rectangle([10, 18, 11, 20], fill=(150, 130, 40))
    d.rectangle([21, 18, 22, 20], fill=(150, 130, 40))

    d.rectangle([14, 20, 18, 28], fill=handle)
    for y in range(21, 28, 2):
        d.line([(14, y), (18, y)], fill=(70, 45, 25), width=1)

    d.ellipse([13, 28, 19, 32], fill=pommel)
