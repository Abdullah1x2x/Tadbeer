"""Builds Android's notification icon from the launcher foreground.

Android draws the small icon from its alpha alone, so a coloured icon shows as
a blank square. This keeps the solid arch and book (dropping the soft shadows)
in white, at each density.

Run from the repo root: python3 tool/brand/notification_icon.py
"""

from PIL import Image

RES = "android/app/src/main/res"
SOURCE = f"{RES}/drawable-xxxhdpi/ic_launcher_foreground.png"
SIZES = {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}

# Below this the alpha is shadow or glow, not the drawing.
SOLID = 200

alpha = Image.open(SOURCE).getchannel("A").point(lambda a: 255 if a >= SOLID else 0)
box = alpha.getbbox()
glyph = alpha.crop(box)
# Square, with the 2dp margin of 24dp Android asks for.
side = round(max(glyph.size) * 24 / 20)
mask = Image.new("L", (side, side), 0)
mask.paste(glyph, ((side - glyph.width) // 2, (side - glyph.height) // 2))

for density, px in SIZES.items():
    icon = Image.new("RGBA", (px, px), (255, 255, 255, 0))
    icon.putalpha(mask.resize((px, px), Image.LANCZOS))
    icon.save(f"{RES}/drawable-{density}/ic_stat_tadbeer.png")
