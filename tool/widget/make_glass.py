"""Draws the frosted-glass background of the home-screen widget per theme.

Usage: python3 tool/widget/make_glass.py

Writes android/app/src/main/res/drawable-nodpi/widget_glass_<theme>.jpg:
coloured light blurred behind a grained frost, a faint eight-pointed star
lattice and a sheen across the top. The colours are each theme's dark hero
gradient (lib/core/theme/theme.dart) and its gold, so keep them in step.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'android/app/src/main/res/drawable-nodpi')

# theme: (heroDarkStart, heroDarkEnd, darkAccentGold)
THEMES = {
    'navy': ('1E3A5F', '0F1D33', 'E3C06A'),
    'emerald': ('1E5B47', '0E2A20', 'E3C06A'),
    'burgundy': ('6A2633', '2E1218', 'DDB06A'),
    'brown': ('5E442C', '261B12', 'E0B56A'),
    'teal': ('115E67', '08282C', 'E3C07A'),
}
W, H = 960, 520


def rgb(hexa):
    return tuple(int(hexa[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def glass(start, end, gold):
    start, end, gold = rgb(start), rgb(end), rgb(gold)
    base = Image.new('RGB', (W, H))
    d = ImageDraw.Draw(base)
    top, bottom = mix(end, (0, 0, 0), 0.15), mix(start, end, 0.45)
    for y in range(H):
        d.line([(0, y), (W, y)], fill=mix(top, bottom, y / H))
    light = mix(start, (255, 255, 255), 0.45)
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    for cx, cy, r, col, a in [
        (0.92, -0.05, 0.40, gold, 105),
        (0.05, 1.05, 0.55, light, 95),
        (0.55, 0.70, 0.28, mix(start, (255, 255, 255), 0.25), 70),
    ]:
        x, y, rr = cx * W, cy * H, r * H
        g.ellipse([x - rr, y - rr, x + rr, y + rr], fill=col + (a,))
    img = Image.alpha_composite(base.convert('RGBA'), glow.filter(ImageFilter.GaussianBlur(80)))
    img = Image.alpha_composite(img, Image.new('RGBA', (W, H), (255, 255, 255, 16)))
    grain = Image.new('RGBA', (W, H), (255, 255, 255, 0))
    grain.putalpha(Image.effect_noise((W, H), 40).convert('L').point(lambda v: max(0, v - 128) // 7))
    img = Image.alpha_composite(img, grain)
    lattice = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lattice)
    cell = 96
    for row in range(H // cell + 2):
        for col in range(W // cell + 2):
            cx, cy = col * cell, row * cell + cell / 2
            pts = []
            for i in range(16):
                rr = cell * 0.28 * (1 if i % 2 == 0 else 0.72)
                a = -math.pi / 2 + i * math.pi / 8
                pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
            ld.line(pts + [pts[0]], fill=gold + (16,), width=2)
    img = Image.alpha_composite(img, lattice)
    sheen = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sheen)
    for y in range(H // 2):
        sd.line([(0, y), (W, y)], fill=(255, 255, 255, int(40 * (1 - y / (H / 2)) ** 2)))
    return Image.alpha_composite(img, sheen).convert('RGB')


if __name__ == '__main__':
    for name, colours in THEMES.items():
        path = os.path.join(OUT, f'widget_glass_{name}.jpg')
        glass(*colours).save(path, quality=88)
        print(path)
