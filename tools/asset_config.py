"""Asset configuration for temporary pixel-art generation."""

ASSETS = {
    "bat": {
        "size": (64, 64),
        "output": "assets/monsters/bat.png",
        "colors": {
            "wing": (120, 60, 160),
            "body": (90, 40, 130),
            "eye": (255, 50, 50),
            "wing_membrane": (150, 90, 190),
        },
    },
    "gargoyle": {
        "size": (64, 64),
        "output": "assets/monsters/gargoyle.png",
        "colors": {
            "stone": (110, 110, 120),
            "stone_dark": (80, 80, 90),
            "stone_light": (140, 140, 150),
            "eye": (220, 180, 40),
            "horn": (90, 85, 80),
        },
        "texture_seed": 42,
    },
    "skeleton": {
        "size": (64, 64),
        "output": "assets/monsters/skeleton.png",
        "colors": {
            "bone": (230, 225, 215),
            "bone_dark": (180, 175, 165),
            "bone_light": (245, 242, 235),
            "eye": (200, 50, 30),
            "teeth": (210, 205, 195),
        },
    },
    "viper": {
        "size": (64, 64),
        "output": "assets/monsters/viper.png",
        "colors": {
            "body": (50, 160, 70),
            "body_dark": (30, 120, 45),
            "body_light": (80, 200, 100),
            "belly": (160, 200, 80),
            "eye": (240, 200, 30),
            "tongue": (200, 40, 40),
            "scale": (40, 140, 55),
        },
        "texture_seed": 77,
    },
    "dagger": {
        "size": (32, 32),
        "output": "assets/equipment/dagger.png",
        "colors": {
            "blade": (190, 200, 210),
            "blade_edge": (220, 225, 235),
            "guard": (160, 130, 50),
            "handle": (100, 70, 40),
            "pommel": (140, 110, 50),
        },
    },
    "iron_sword": {
        "size": (32, 32),
        "output": "assets/equipment/iron_sword.png",
        "colors": {
            "blade": (170, 180, 195),
            "blade_light": (210, 215, 225),
            "blade_dark": (130, 140, 155),
            "guard": (180, 160, 60),
            "handle": (90, 60, 35),
            "pommel": (180, 160, 60),
        },
    },
    "chainmail": {
        "size": (32, 32),
        "output": "assets/equipment/chainmail.png",
        "colors": {
            "metal": (160, 165, 175),
            "metal_light": (200, 205, 215),
            "metal_dark": (120, 125, 135),
            "trim": (180, 160, 60),
        },
    },
}
