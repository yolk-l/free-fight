"""Drawer registry - maps asset name to draw function."""
from .bat import draw as draw_bat
from .gargoyle import draw as draw_gargoyle
from .skeleton import draw as draw_skeleton
from .viper import draw as draw_viper
from .dagger import draw as draw_dagger
from .iron_sword import draw as draw_iron_sword
from .chainmail import draw as draw_chainmail

DRAWERS = {
    "bat": draw_bat,
    "gargoyle": draw_gargoyle,
    "skeleton": draw_skeleton,
    "viper": draw_viper,
    "dagger": draw_dagger,
    "iron_sword": draw_iron_sword,
    "chainmail": draw_chainmail,
}
