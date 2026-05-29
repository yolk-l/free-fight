"""Shared drawing utilities."""


def put_pixels(img, pixels, color):
    for x, y in pixels:
        if 0 <= x < img.width and 0 <= y < img.height:
            img.putpixel((x, y), color)
