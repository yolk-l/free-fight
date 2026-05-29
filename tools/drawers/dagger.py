"""Draw a 32x32 short dagger."""


def draw(img, d, config):
    c = config["colors"]
    blade = c["blade"]
    blade_edge = c["blade_edge"]
    guard = c["guard"]
    handle = c["handle"]
    pommel = c["pommel"]

    d.polygon([(18, 4), (20, 4), (17, 16), (15, 16)], fill=blade)
    d.line([(19, 5), (17, 14)], fill=blade_edge, width=1)
    d.polygon([(18, 4), (20, 4), (19, 2)], fill=blade_edge)

    d.rectangle([12, 16, 22, 18], fill=guard)

    d.rectangle([15, 18, 19, 26], fill=handle)
    for y in range(19, 26, 2):
        d.line([(15, y), (19, y)], fill=(80, 55, 30), width=1)

    d.ellipse([14, 26, 20, 30], fill=pommel)
