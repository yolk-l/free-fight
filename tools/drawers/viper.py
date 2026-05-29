"""Draw a 64x64 green viper in coiled strike pose."""
import random


def draw(img, d, config):
    c = config["colors"]
    body = c["body"]
    body_dark = c["body_dark"]
    body_light = c["body_light"]
    belly = c["belly"]
    eye_color = c["eye"]
    tongue = c["tongue"]
    scale_color = c["scale"]

    d.arc([14, 40, 50, 60], 0, 360, fill=body, width=6)
    d.arc([16, 42, 48, 58], 0, 180, fill=belly, width=2)
    d.arc([18, 36, 46, 54], 0, 360, fill=body, width=6)
    d.arc([20, 38, 44, 52], 0, 180, fill=belly, width=2)

    d.arc([20, 30, 44, 48], 0, 360, fill=body, width=5)
    d.arc([22, 32, 42, 46], 0, 180, fill=belly, width=2)

    d.line([(32, 32), (30, 26), (34, 20), (32, 14)], fill=body, width=5)
    d.line([(32, 32), (30, 26), (34, 20), (32, 14)], fill=body_dark, width=3)
    d.line([(31, 30), (29, 25), (33, 19), (31, 14)], fill=body_light, width=1)

    head_poly = [(26, 10), (38, 10), (40, 16), (24, 16), (26, 10)]
    d.polygon(head_poly, fill=body)
    d.polygon([(28, 10), (36, 10), (35, 13), (29, 13)], fill=body_dark)

    d.ellipse([28, 12, 31, 15], fill=eye_color)
    d.ellipse([33, 12, 36, 15], fill=eye_color)
    d.line([(29, 12), (29, 15)], fill=(20, 20, 10), width=1)
    d.line([(35, 12), (35, 15)], fill=(20, 20, 10), width=1)

    d.line([(32, 16), (32, 21)], fill=tongue, width=1)
    d.line([(32, 21), (30, 23)], fill=tongue, width=1)
    d.line([(32, 21), (34, 23)], fill=tongue, width=1)

    random.seed(config.get("texture_seed", 77))
    for _ in range(40):
        sx = random.randint(15, 49)
        sy = random.randint(32, 59)
        if img.getpixel((sx, sy))[3] > 0:
            px = img.getpixel((sx, sy))
            if px[1] > 100:
                d.point((sx, sy), fill=scale_color)

    d.line([(48, 48), (52, 44), (54, 46)], fill=body_dark, width=2)
    img.putpixel((54, 46), body_light)
