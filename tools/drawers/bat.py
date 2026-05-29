"""Draw a 64x64 purple bat with spread wings."""
from .common import put_pixels


def draw(img, d, config):
    c = config["colors"]
    wing_color = c["wing"]
    body_color = c["body"]
    eye_color = c["eye"]
    wing_membrane = c["wing_membrane"]

    d.ellipse([26, 24, 38, 40], fill=body_color)
    d.ellipse([28, 18, 36, 28], fill=body_color)

    d.polygon([(28, 18), (26, 12), (30, 17)], fill=body_color)
    d.polygon([(36, 18), (38, 12), (34, 17)], fill=body_color)

    img.putpixel((30, 22), eye_color)
    img.putpixel((31, 22), eye_color)
    img.putpixel((33, 22), eye_color)
    img.putpixel((34, 22), eye_color)

    wing_l = [(26, 28), (6, 18), (4, 24), (8, 32), (14, 36), (24, 38)]
    d.polygon(wing_l, fill=wing_color)
    d.line([(26, 28), (6, 18)], fill=body_color, width=1)
    d.line([(26, 30), (4, 24)], fill=body_color, width=1)
    d.line([(26, 32), (8, 32)], fill=body_color, width=1)
    d.line([(16, 22), (12, 28)], fill=wing_membrane, width=1)
    d.line([(20, 26), (16, 32)], fill=wing_membrane, width=1)

    wing_r = [(38, 28), (58, 18), (60, 24), (56, 32), (50, 36), (40, 38)]
    d.polygon(wing_r, fill=wing_color)
    d.line([(38, 28), (58, 18)], fill=body_color, width=1)
    d.line([(38, 30), (60, 24)], fill=body_color, width=1)
    d.line([(38, 32), (56, 32)], fill=body_color, width=1)
    d.line([(48, 22), (52, 28)], fill=wing_membrane, width=1)
    d.line([(44, 26), (48, 32)], fill=wing_membrane, width=1)

    put_pixels(img, [(30, 40), (31, 41), (33, 40), (34, 41)], body_color)

    img.putpixel((31, 26), (255, 255, 255))
    img.putpixel((33, 26), (255, 255, 255))
