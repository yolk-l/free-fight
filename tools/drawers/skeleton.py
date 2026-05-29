"""Draw a 64x64 bone-white skeleton warrior."""
from .common import put_pixels


def draw(img, d, config):
    c = config["colors"]
    bone = c["bone"]
    bone_dark = c["bone_dark"]
    bone_light = c["bone_light"]
    eye_color = c["eye"]
    teeth = c["teeth"]

    d.ellipse([24, 6, 40, 24], fill=bone)
    d.ellipse([27, 12, 31, 17], fill=(30, 20, 20))
    d.ellipse([33, 12, 37, 17], fill=(30, 20, 20))
    img.putpixel((29, 14), eye_color)
    img.putpixel((35, 14), eye_color)
    d.polygon([(31, 18), (33, 18), (32, 20)], fill=(40, 30, 30))
    d.rectangle([27, 21, 37, 24], fill=bone_dark)
    for tx in range(28, 37, 2):
        img.putpixel((tx, 22), teeth)
        img.putpixel((tx, 23), teeth)

    for sy in range(25, 38, 3):
        d.ellipse([30, sy, 34, sy + 2], fill=bone)
        d.point((32, sy + 1), fill=bone_dark)

    for ry in range(26, 35, 3):
        d.arc([22, ry, 32, ry + 4], 180, 0, fill=bone_dark, width=1)
        d.arc([32, ry, 42, ry + 4], 180, 0, fill=bone_dark, width=1)

    d.ellipse([18, 24, 24, 30], fill=bone)
    d.ellipse([40, 24, 46, 30], fill=bone)

    d.rectangle([18, 30, 22, 42], fill=bone)
    d.rectangle([42, 30, 46, 42], fill=bone)
    d.ellipse([17, 41, 23, 45], fill=bone_dark)
    d.ellipse([41, 41, 47, 45], fill=bone_dark)
    d.rectangle([18, 45, 22, 54], fill=bone)
    d.rectangle([42, 45, 46, 54], fill=bone)
    put_pixels(img, [(17, 54), (19, 55), (21, 54), (23, 55)], bone_light)
    put_pixels(img, [(41, 54), (43, 55), (45, 54), (47, 55)], bone_light)

    d.ellipse([26, 37, 38, 44], fill=bone_dark)

    d.rectangle([26, 44, 30, 56], fill=bone)
    d.rectangle([34, 44, 38, 56], fill=bone)
    d.ellipse([25, 49, 31, 53], fill=bone_dark)
    d.ellipse([33, 49, 39, 53], fill=bone_dark)
    d.rectangle([24, 56, 31, 60], fill=bone)
    d.rectangle([33, 56, 40, 60], fill=bone)

    d.line([(28, 8), (30, 11)], fill=bone_dark, width=1)
    d.line([(36, 9), (34, 12)], fill=bone_dark, width=1)
