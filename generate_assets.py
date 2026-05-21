from PIL import Image, ImageDraw

def create_image(size, bg=(0, 0, 0, 0)):
    img = Image.new("RGBA", (size, size), bg)
    return img, ImageDraw.Draw(img)


def draw_hero(path):
    img, d = create_image(64)
    # body
    d.rectangle([20, 16, 43, 48], fill=(50, 100, 200), outline=(30, 60, 150), width=2)
    # head
    d.ellipse([24, 4, 40, 20], fill=(220, 185, 150), outline=(180, 140, 100), width=1)
    # helmet
    d.arc([22, 2, 42, 18], 180, 0, fill=(80, 80, 100), width=3)
    # visor
    d.rectangle([28, 10, 36, 14], fill=(40, 40, 60))
    # arms
    d.rectangle([12, 20, 20, 40], fill=(50, 100, 200), outline=(30, 60, 150), width=1)
    d.rectangle([43, 20, 51, 40], fill=(50, 100, 200), outline=(30, 60, 150), width=1)
    # shield (left hand)
    d.rectangle([8, 22, 18, 38], fill=(160, 140, 80), outline=(120, 100, 40), width=2)
    # sword (right hand)
    d.rectangle([48, 10, 52, 38], fill=(200, 200, 210), outline=(160, 160, 170), width=1)
    d.polygon([(48, 10), (50, 4), (52, 10)], fill=(200, 200, 210))
    # sword handle
    d.rectangle([46, 38, 54, 42], fill=(139, 90, 43))
    # legs
    d.rectangle([22, 48, 30, 60], fill=(40, 40, 80), outline=(30, 30, 60), width=1)
    d.rectangle([33, 48, 41, 60], fill=(40, 40, 80), outline=(30, 30, 60), width=1)
    # boots
    d.rectangle([20, 56, 31, 62], fill=(100, 70, 40))
    d.rectangle([32, 56, 43, 62], fill=(100, 70, 40))
    img.save(path)


def draw_slime(path):
    img, d = create_image(64)
    # shadow
    d.ellipse([12, 48, 52, 58], fill=(0, 0, 0, 60))
    # body
    d.ellipse([10, 18, 54, 56], fill=(80, 200, 100), outline=(50, 160, 70), width=2)
    # top bulge
    d.ellipse([18, 10, 46, 36], fill=(100, 220, 120))
    # highlight
    d.ellipse([20, 16, 30, 26], fill=(150, 240, 170, 180))
    # eyes
    d.ellipse([22, 28, 30, 38], fill=(255, 255, 255))
    d.ellipse([34, 28, 42, 38], fill=(255, 255, 255))
    d.ellipse([25, 31, 29, 37], fill=(20, 20, 20))
    d.ellipse([36, 31, 40, 37], fill=(20, 20, 20))
    # mouth
    d.arc([26, 36, 38, 44], 0, 180, fill=(40, 100, 50), width=2)
    img.save(path)


def draw_wolf(path):
    img, d = create_image(64)
    # shadow
    d.ellipse([8, 52, 56, 62], fill=(0, 0, 0, 50))
    # body
    d.ellipse([12, 28, 52, 52], fill=(150, 150, 160), outline=(120, 120, 130), width=2)
    # head
    d.ellipse([2, 16, 28, 40], fill=(160, 160, 170), outline=(120, 120, 130), width=2)
    # ear left
    d.polygon([(8, 18), (4, 4), (16, 14)], fill=(140, 140, 150), outline=(110, 110, 120))
    # ear right
    d.polygon([(18, 14), (22, 2), (26, 14)], fill=(140, 140, 150), outline=(110, 110, 120))
    # snout
    d.ellipse([0, 26, 16, 38], fill=(180, 180, 190))
    # nose
    d.ellipse([2, 28, 10, 34], fill=(30, 30, 30))
    # eye
    d.ellipse([16, 22, 24, 30], fill=(255, 200, 50))
    d.ellipse([18, 24, 22, 28], fill=(20, 20, 20))
    # tail
    d.arc([44, 14, 62, 38], 220, 80, fill=(140, 140, 150), width=4)
    # legs
    d.rectangle([16, 48, 22, 58], fill=(140, 140, 150), outline=(110, 110, 120))
    d.rectangle([26, 48, 32, 58], fill=(140, 140, 150), outline=(110, 110, 120))
    d.rectangle([36, 48, 42, 58], fill=(140, 140, 150), outline=(110, 110, 120))
    d.rectangle([46, 48, 52, 58], fill=(140, 140, 150), outline=(110, 110, 120))
    img.save(path)


def draw_goblin(path):
    img, d = create_image(64)
    # body
    d.rectangle([22, 24, 42, 44], fill=(200, 130, 50), outline=(160, 100, 30), width=2)
    # head
    d.ellipse([20, 4, 44, 26], fill=(120, 180, 80), outline=(90, 140, 60), width=2)
    # ears
    d.polygon([(20, 14), (6, 8), (18, 20)], fill=(110, 170, 70), outline=(90, 140, 60))
    d.polygon([(44, 14), (58, 8), (46, 20)], fill=(110, 170, 70), outline=(90, 140, 60))
    # eyes
    d.ellipse([25, 10, 33, 18], fill=(255, 60, 60))
    d.ellipse([35, 10, 43, 18], fill=(255, 60, 60))
    d.ellipse([28, 12, 32, 16], fill=(20, 20, 20))
    d.ellipse([37, 12, 41, 16], fill=(20, 20, 20))
    # mouth
    d.arc([27, 18, 37, 24], 0, 180, fill=(60, 30, 10), width=2)
    # arms
    d.rectangle([14, 26, 22, 38], fill=(110, 170, 70), outline=(90, 140, 60), width=1)
    d.rectangle([42, 26, 50, 38], fill=(110, 170, 70), outline=(90, 140, 60), width=1)
    # dagger (right hand)
    d.rectangle([50, 18, 54, 36], fill=(200, 200, 210), outline=(160, 160, 170), width=1)
    d.polygon([(50, 18), (52, 12), (54, 18)], fill=(200, 200, 210))
    # legs
    d.rectangle([24, 44, 30, 56], fill=(110, 170, 70), outline=(90, 140, 60), width=1)
    d.rectangle([34, 44, 40, 56], fill=(110, 170, 70), outline=(90, 140, 60), width=1)
    # feet
    d.rectangle([22, 54, 32, 60], fill=(80, 50, 30))
    d.rectangle([32, 54, 42, 60], fill=(80, 50, 30))
    img.save(path)


def draw_wood_sword(path):
    img, d = create_image(32)
    # blade
    d.rectangle([14, 2, 18, 20], fill=(200, 200, 210), outline=(160, 160, 170), width=1)
    # blade tip
    d.polygon([(14, 2), (16, -2), (18, 2)], fill=(220, 220, 230))
    # guard
    d.rectangle([10, 20, 22, 23], fill=(180, 150, 50), outline=(140, 110, 30), width=1)
    # handle
    d.rectangle([14, 23, 18, 30], fill=(139, 90, 43), outline=(100, 60, 20), width=1)
    # pommel
    d.ellipse([13, 28, 19, 32], fill=(180, 150, 50), outline=(140, 110, 30))
    img.save(path)


def draw_leather_armor(path):
    img, d = create_image(32)
    # main body
    d.rectangle([8, 6, 24, 24], fill=(160, 110, 60), outline=(120, 80, 30), width=2)
    # neckline
    d.arc([12, 4, 20, 12], 180, 0, fill=(140, 90, 40), width=2)
    # shoulders
    d.rectangle([4, 6, 10, 14], fill=(150, 100, 50), outline=(120, 80, 30), width=1)
    d.rectangle([22, 6, 28, 14], fill=(150, 100, 50), outline=(120, 80, 30), width=1)
    # belt
    d.rectangle([8, 20, 24, 23], fill=(100, 70, 30), outline=(80, 50, 20), width=1)
    # belt buckle
    d.rectangle([14, 20, 18, 23], fill=(200, 180, 60))
    # bottom skirt
    d.rectangle([8, 23, 14, 30], fill=(150, 100, 50), outline=(120, 80, 30), width=1)
    d.rectangle([18, 23, 24, 30], fill=(150, 100, 50), outline=(120, 80, 30), width=1)
    # stitch detail
    d.line([(16, 8), (16, 20)], fill=(130, 85, 35), width=1)
    img.save(path)


if __name__ == "__main__":
    base = "D:/learn/free-fight/assets"
    draw_hero(f"{base}/hero.png")
    draw_slime(f"{base}/monsters/slime.png")
    draw_wolf(f"{base}/monsters/wolf.png")
    draw_goblin(f"{base}/monsters/goblin.png")
    draw_wood_sword(f"{base}/equipment/wood_sword.png")
    draw_leather_armor(f"{base}/equipment/leather_armor.png")
    print("All assets generated:")
    print(f"  {base}/hero.png")
    print(f"  {base}/monsters/slime.png")
    print(f"  {base}/monsters/wolf.png")
    print(f"  {base}/monsters/goblin.png")
    print(f"  {base}/equipment/wood_sword.png")
    print(f"  {base}/equipment/leather_armor.png")
