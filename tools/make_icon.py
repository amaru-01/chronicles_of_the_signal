"""Generates the app icon (icon.png and icon.ico) from the Runner's head.
Run from the project root:  python tools/make_icon.py
Everything is drawn from scratch, so there is no licence issue. Replace the files with real
art later; keep the names (project.godot and the Windows preset point at them)."""
from PIL import Image, ImageDraw

S = 256
img = Image.new('RGBA', (S, S), (10, 6, 28, 255))
d = ImageDraw.Draw(img)

# neon grid backdrop
for i in range(0, S, 32):
    d.line([(i, 0), (i, S)], fill=(20, 60, 80, 255), width=1)
    d.line([(0, i), (S, i)], fill=(20, 60, 80, 255), width=1)

PINK = (255, 64, 150, 255)
CYAN = (40, 230, 255, 255)
SKIN = (230, 165, 140, 255)
COAT = (14, 18, 40, 255)

# the Runner: pink hair, cyan visor, dark coat with cyan trim
d.rectangle([72, 40, 184, 112], fill=PINK)
d.rectangle([60, 64, 196, 150], fill=PINK)
d.rectangle([84, 88, 172, 150], fill=SKIN)
d.rectangle([84, 100, 172, 126], fill=CYAN)
d.rectangle([100, 150, 156, 172], fill=SKIN)
d.rectangle([48, 172, 208, 256], fill=COAT)
d.rectangle([48, 172, 208, 184], fill=CYAN)
d.rectangle([120, 184, 136, 256], fill=CYAN)

# neon frame
d.rectangle([4, 4, S - 5, S - 5], outline=PINK, width=4)
d.rectangle([12, 12, S - 13, S - 13], outline=CYAN, width=2)

img.save('icon.png')
img.save('icon.ico', sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])
print('icon.png and icon.ico written')
