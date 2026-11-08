"""Generates the 3D-scale sprites for the 3D version of Chronicles of the Signal.
Run from the project root:  python tools/make_assets_3d.py
Everything it writes is original and generated (no licence issue). Replace the PNGs
in assets3d/sprites/ with hand-made art later, keeping the same layouts:

  player_3d.png, fixer_3d.png : 5 columns x 4 rows of 48x80 cells.
                                columns = [idle, walk1..walk4]
                                rows    = [down(front), left, right, up(back)]
  drone_3d.png                : 2 frames of 56x40 side by side
  enforcer_3d.png             : 2 walk frames of 56x80 side by side
  terminal_3d.png             : 2 frames of 40x56 (locked, hacked)

Scale: 1 sprite pixel = 2.5 cm in the 3D scene, so an 80 px character is 2 m tall and
renders 1:1 on the 480x270 pixel viewport."""
import os
from PIL import Image, ImageDraw

CW, CH = 48, 80
OUT = (6, 4, 16, 255)
os.makedirs("assets3d/sprites", exist_ok=True)


def c(rgb, a=255):
    return (rgb[0], rgb[1], rgb[2], a)


RUNNER = dict(
    skin=(224, 170, 140), hair=(255, 70, 150), hair2=(190, 40, 110), visor=(0, 240, 255),
    coat=(22, 32, 62), coat_dark=(12, 18, 38), edge=(0, 230, 255), pants=(16, 18, 34),
    boots=(8, 8, 18), hood=False,
)
FIXER = dict(
    skin=(205, 150, 120), hair=(225, 225, 235), hair2=(160, 160, 175), visor=(120, 255, 90),
    coat=(96, 24, 56), coat_dark=(58, 12, 36), edge=(255, 170, 50), pants=(30, 14, 28),
    boots=(14, 8, 16), hood=True,
)


def outline(im):
    """1 px dark outline around the sprite, the classic pixel-art silhouette."""
    px = im.load()
    out = im.copy()
    op = out.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < im.width and 0 <= ny < im.height and px[nx, ny][3] > 0:
                        op[x, y] = OUT
                        break
    return out


def rect(d, x0, y0, x1, y1, fill, edge=None):
    d.rectangle([x0, y0, x1, y1], fill=c(fill), outline=c(edge) if edge else None)


def character(p, facing, col):
    """One 48x80 frame. facing: down|up|left|right. col 0 = idle, 1..4 = walk cycle."""
    im = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    step = [0, 1, 0, -1, 0][col]          # which leg is forward
    bob = [0, 0, 1, 0, 1][col]            # body dips on the passing frames
    sway = [0, 1, 0, -1, 0][col]          # coat hem swing
    walking = col != 0
    top = 4 + bob                          # head top

    if facing in ("down", "up"):
        # ---- legs
        for i, x in enumerate((17, 26)):
            lift = 0
            if walking:
                lift = 4 if (step == 1 and i == 0) or (step == -1 and i == 1) else 0
                lift = lift if step != 0 else (2 if i == (0 if col == 2 else 1) else 0)
            rect(d, x, 56 + bob, x + 5, 73 - lift, p["pants"])
            rect(d, x - 1, 73 - lift, x + 6, 77 - lift, p["boots"])
            d.line([x - 1, 77 - lift, x + 6, 77 - lift], fill=c(p["edge"]))
        # ---- coat (long trench, hem sways)
        coat = [(14, 24 + bob), (34, 24 + bob), (37 + sway, 63 + bob), (11 + sway, 63 + bob)]
        d.polygon(coat, fill=c(p["coat"]), outline=c(p["edge"]))
        d.polygon([(14, 24 + bob), (24, 24 + bob), (24 + sway, 63 + bob), (11 + sway, 63 + bob)],
                  fill=c(p["coat_dark"]))
        d.polygon(coat, outline=c(p["edge"]))
        if facing == "down":
            d.line([24, 30 + bob, 24 + sway, 63 + bob], fill=c(p["edge"]))        # front seam
            rect(d, 20, 46 + bob, 28, 47 + bob, p["coat_dark"])                    # belt
        else:
            d.line([24, 26 + bob, 24 + sway, 63 + bob], fill=c(p["coat_dark"]))
            rect(d, 19, 32 + bob, 29, 35 + bob, p["edge"])                         # back logo
            rect(d, 21, 33 + bob, 27, 34 + bob, p["coat_dark"])
        # ---- arms (swing opposite to legs)
        swing = 2 * step
        rect(d, 9, 26 + bob + swing, 14, 46 + bob + swing, p["coat"], p["edge"])
        rect(d, 34, 26 + bob - swing, 39, 46 + bob - swing, p["coat"], p["edge"])
        rect(d, 9, 47 + bob + swing, 14, 50 + bob + swing, p["skin"])
        rect(d, 34, 47 + bob - swing, 39, 50 + bob - swing, p["skin"])
        # ---- collar + head
        rect(d, 15, 21 + bob, 33, 26 + bob, p["coat_dark"], p["edge"])
        if p["hood"]:
            d.ellipse([14, top - 1, 34, top + 20], fill=c(p["coat"]), outline=c(p["edge"]))
            if facing == "down":
                rect(d, 19, top + 8, 29, top + 18, p["skin"])
                rect(d, 19, top + 10, 29, top + 12, p["visor"])
            else:
                d.ellipse([16, top + 1, 32, top + 19], fill=c(p["coat_dark"]))
        else:
            rect(d, 17, top + 4, 31, top + 19, p["skin"])
            rect(d, 15, top, 33, top + 9, p["hair"])
            if facing == "down":
                rect(d, 15, top + 8, 18, top + 13, p["hair"])
                rect(d, 30, top + 8, 33, top + 13, p["hair"])
                rect(d, 18, top + 9, 30, top + 12, p["visor"])                      # visor
                rect(d, 21, top + 15, 27, top + 16, p["coat_dark"])                 # mouth
                d.line([16, top + 1, 30, top + 1], fill=c(p["hair2"]))
            else:
                rect(d, 15, top, 33, top + 16, p["hair"])
                rect(d, 15, top + 10, 33, top + 12, p["hair2"])
    else:
        right = facing == "right"
        dirn = 1 if right else -1
        cx = 24
        # ---- legs scissor; the far leg is drawn first and darker
        for i in (1, 0):
            offset = step * 5 * (1 if i == 0 else -1)
            x = cx - 3 + offset
            shade = p["pants"] if i == 0 else tuple(max(0, v - 8) for v in p["pants"])
            lift = 3 if walking and ((i == 0 and step == -1) or (i == 1 and step == 1)) else 0
            rect(d, x, 56 + bob, x + 5, 73 - lift, shade)
            fx = x + (2 if right else -2)
            rect(d, min(x, fx), 73 - lift, max(x + 5, fx + 5), 77 - lift, p["boots"])
        # ---- coat trailing behind the direction of travel
        back = -dirn
        flare = 5 + sway * back * 2
        coat = [(cx - 7, 24 + bob), (cx + 7, 24 + bob), (cx + 8 + back * flare, 63 + bob),
                (cx - 8 + back * flare, 63 + bob)]
        d.polygon(coat, fill=c(p["coat"]), outline=c(p["edge"]))
        d.line([cx + dirn * 6, 28 + bob, cx + dirn * 7, 62 + bob], fill=c(p["edge"]))
        rect(d, cx - 6, 46 + bob, cx + 6, 47 + bob, p["coat_dark"])
        # ---- arm swings front/back
        ax = cx - 2 + step * 4 * dirn
        rect(d, ax, 26 + bob, ax + 5, 45 + bob, p["coat_dark"], p["edge"])
        rect(d, ax, 46 + bob, ax + 5, 49 + bob, p["skin"])
        # ---- head in profile, visor on the facing side
        rect(d, cx - 8, 21 + bob, cx + 8, 26 + bob, p["coat_dark"], p["edge"])
        if p["hood"]:
            d.ellipse([cx - 10, top - 1, cx + 10, top + 20], fill=c(p["coat"]), outline=c(p["edge"]))
            fx0 = cx + 1 if right else cx - 9
            rect(d, fx0, top + 8, fx0 + 8, top + 17, p["skin"])
            vx = cx + 4 if right else cx - 9
            rect(d, vx, top + 10, vx + 5, top + 12, p["visor"])
        else:
            rect(d, cx - 7, top + 4, cx + 7, top + 19, p["skin"])
            hx0, hx1 = (cx - 9, cx + 5) if right else (cx - 5, cx + 9)
            rect(d, hx0, top, hx1, top + 14, p["hair"])
            rect(d, cx - 7, top, cx + 7, top + 6, p["hair"])
            vx = cx + 2 if right else cx - 8
            rect(d, vx, top + 9, vx + 6, top + 12, p["visor"])
            nose = cx + 8 if right else cx - 8
            rect(d, nose - (0 if right else 1), top + 13, nose + (1 if right else 0), top + 14, p["skin"])
    return outline(im)


def sheet(palette, path):
    im = Image.new("RGBA", (CW * 5, CH * 4), (0, 0, 0, 0))
    for row, facing in enumerate(["down", "left", "right", "up"]):
        for col in range(5):
            im.paste(character(palette, facing, col), (col * CW, row * CH))
    im.save(path)


def drone(path):
    pink, glow = (255, 60, 90), (255, 190, 200)
    im = Image.new("RGBA", (112, 40), (0, 0, 0, 0))
    for f in range(2):
        ox = f * 56
        fr = Image.new("RGBA", (56, 40), (0, 0, 0, 0))
        d = ImageDraw.Draw(fr)
        wob = f * 2
        # legs hanging
        d.line([16, 26, 8 + wob, 37], fill=c((70, 90, 130)), width=2)
        d.line([40, 26, 48 - wob, 37], fill=c((70, 90, 130)), width=2)
        d.line([8 + wob, 37, 5 + wob, 38], fill=c((0, 230, 255)), width=1)
        d.line([48 - wob, 37, 51 - wob, 38], fill=c((0, 230, 255)), width=1)
        # rotor arm + blur
        rect(d, 6 + wob, 7, 49 - wob, 8, (120, 140, 190))
        d.line([28, 8, 28, 12], fill=c((120, 140, 190)), width=2)
        # body dome
        d.ellipse([12, 10, 44, 30], fill=c((58, 72, 108)), outline=c((0, 230, 255)))
        rect(d, 12, 22, 44, 28, (36, 46, 78))
        # visor eye
        rect(d, 18, 16, 38, 23, (30, 8, 20), pink)
        rect(d, 21 + f * 2, 18, 27 + f * 2, 21, glow if f else pink)
        rect(d, 30, 18, 34, 21, pink)
        # antenna
        d.line([40, 11, 46, 4], fill=c((0, 230, 255)))
        d.point([46, 3], fill=c(pink))
        im.paste(outline(fr), (ox, 0))
    im.save(path)


def enforcer(path):
    """Armoured riot robot, 2 frames of 56x80 (walk). Melee-proof; weak to the hack pulse."""
    red = (255, 60, 60)
    im = Image.new("RGBA", (112, 80), (0, 0, 0, 0))
    for f in range(2):
        fr = Image.new("RGBA", (56, 80), (0, 0, 0, 0))
        d = ImageDraw.Draw(fr)
        lift = 3 * f
        for i, x in enumerate((17, 33)):
            up = lift if i == 0 else 3 - lift
            rect(d, x, 56, x + 7, 73 - up, (34, 38, 58), red)
            rect(d, x - 1, 73 - up, x + 8, 78 - up, (16, 16, 28), red)
        rect(d, 11, 25, 45, 58, (52, 60, 88), red)                      # torso armour
        rect(d, 14, 28, 42, 34, (70, 80, 112))                           # chest plate highlight
        rect(d, 24, 38, 32, 46, (60, 10, 14), red)                       # core light
        rect(d, 26, 40, 30, 44, red)
        rect(d, 4, 22, 16, 36, (66, 76, 108), red)                       # shoulder guards
        rect(d, 40, 22, 52, 36, (66, 76, 108), red)
        rect(d, 5, 36, 13, 58, (40, 46, 70), red)                        # arms
        rect(d, 43, 36, 51, 58, (40, 46, 70), red)
        rect(d, 47, 54, 51, 74, (30, 30, 44), (255, 170, 40))            # stun baton
        d.line([49, 74, 49, 78], fill=c((255, 170, 40)), width=2)
        d.ellipse([17, 4, 39, 26], fill=c((58, 66, 96)), outline=c(red))  # helmet
        rect(d, 20, 12, 36, 18, (24, 6, 10), red)                        # visor slit
        rect(d, 22 + f * 3, 14, 28 + f * 3, 16, (255, 200, 200))
        im.paste(outline(fr), (f * 56, 0))
    im.save(path)


def lever(path):
    """Wall lever, 2 frames of 40x56 (off, on)."""
    im = Image.new("RGBA", (80, 56), (0, 0, 0, 0))
    for f in range(2):
        fr = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
        d = ImageDraw.Draw(fr)
        accent = (150, 150, 190) if f == 0 else (255, 60, 220)
        rect(d, 6, 36, 34, 54, (18, 20, 40), accent)                      # base box
        rect(d, 10, 40, 30, 48, (8, 10, 24))                              # slot
        tilt = -10 if f == 0 else 10
        d.line([20, 44, 20 + tilt, 14], fill=c(accent), width=3)          # handle
        d.ellipse([20 + tilt - 5, 8, 20 + tilt + 5, 18], fill=c(accent))  # knob
        rect(d, 17, 50, 23, 52, accent)
        im.paste(outline(fr), (f * 40, 0))
    im.save(path)


def stalker(path):
    """Grid wraith, 2 frames of 40x64: translucent, tapering into tendrils."""
    im = Image.new("RGBA", (80, 64), (0, 0, 0, 0))
    for f in range(2):
        fr = Image.new("RGBA", (40, 64), (0, 0, 0, 0))
        d = ImageDraw.Draw(fr)
        body = (90, 40, 200, 235)
        d.polygon([(20, 4), (31, 14), (33, 34), (28, 50), (12, 50), (7, 34), (9, 14)], fill=body, outline=c((0, 240, 255)))
        for i, x in enumerate((10, 16, 22, 28)):
            sway = (2 if (i + f) % 2 else -2)
            d.line([x, 48, x + sway, 60], fill=c((0, 200, 255)), width=3)
        d.ellipse([12, 14, 18, 20], fill=c((255, 255, 255)))
        d.ellipse([22, 14, 28, 20], fill=c((255, 255, 255)))
        d.rectangle([14, 16, 16, 18], fill=c((255, 40, 120)))
        d.rectangle([24, 16, 26, 18], fill=c((255, 40, 120)))
        d.arc([13, 24, 27, 34], 20, 160, fill=c((10, 4, 30)), width=2)            # grim mouth
        for y in (30, 38, 44):
            d.line([10, y, 30, y], fill=c((140, 90, 255)))                          # data stripes
        im.paste(outline(fr), (f * 40, 0))
    im.save(path)


def sentry(path):
    """Physical-world turret, 2 frames of 48x64 (idle, firing)."""
    im = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
    for f in range(2):
        fr = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
        d = ImageDraw.Draw(fr)
        orange = (255, 140, 30)
        rect(d, 8, 50, 40, 62, (30, 32, 48), orange)                              # base
        rect(d, 18, 36, 30, 50, (44, 50, 72), orange)                             # stem
        d.ellipse([8, 8, 40, 42], fill=c((58, 66, 96)), outline=c(orange))        # head dome
        d.ellipse([16, 16, 32, 32], fill=c((20, 6, 6)), outline=c((255, 60, 60))) # lens housing
        glow = (255, 220, 200) if f else (255, 60, 60)
        d.ellipse([20, 20, 28, 28], fill=c(glow))                                  # lens
        if f:
            d.ellipse([14, 14, 34, 34], outline=c((255, 120, 60)))                 # muzzle flare
        rect(d, 4, 30, 8, 38, (44, 50, 72), orange)                                # side pods
        rect(d, 40, 30, 44, 38, (44, 50, 72), orange)
        im.paste(outline(fr), (f * 48, 0))
    im.save(path)


def curator(path):
    """The Curator, 4 frames of 96x128: [physical a, physical b, digital a, digital b]."""
    im = Image.new("RGBA", (96 * 4, 128), (0, 0, 0, 0))
    forms = [((255, 190, 60), (255, 60, 150), (46, 12, 34)), ((0, 240, 255), (200, 120, 255), (10, 22, 56))]
    for form, (accent, core, robe) in enumerate(forms):
        for f in range(2):
            fr = Image.new("RGBA", (96, 128), (0, 0, 0, 0))
            d = ImageDraw.Draw(fr)
            bob = 3 * f
            # halo
            d.ellipse([22, 2 + bob, 74, 22 + bob], outline=c(accent), width=3)
            # robe: a tall tapering cloak with no legs (it floats)
            d.polygon([(48, 18 + bob), (68, 34 + bob), (80, 96 + bob), (62, 118 + bob + f), (34, 118 + bob - f), (16, 96 + bob), (28, 34 + bob)],
                      fill=c(robe), outline=c(accent))
            d.polygon([(48, 18 + bob), (58, 34 + bob), (54, 112 + bob), (42, 112 + bob), (38, 34 + bob)], fill=c(tuple(max(0, v - 14) for v in robe)))
            # hood and face void
            d.ellipse([34, 18 + bob, 62, 50 + bob], fill=c((6, 4, 14)), outline=c(accent))
            d.ellipse([40, 30 + bob, 46, 36 + bob], fill=c(core))
            d.ellipse([50, 30 + bob, 56, 36 + bob], fill=c(core))
            # chest core
            d.ellipse([38, 58 + bob, 58, 78 + bob], fill=c((10, 4, 18)), outline=c(core), width=2)
            d.ellipse([43, 63 + bob, 53, 73 + bob], fill=c(core if f == 0 else (255, 255, 255)))
            # drifting hands
            d.ellipse([6, 62 + bob - f * 4, 20, 76 + bob - f * 4], fill=c(accent))
            d.ellipse([76, 62 + bob + f * 4, 90, 76 + bob + f * 4], fill=c(accent))
            # data runes on the hem
            for i in range(5):
                d.line([26 + i * 9, 100 + bob, 26 + i * 9, 106 + bob], fill=c(accent))
            im.paste(outline(fr), ((form * 2 + f) * 96, 0))
    im.save(path)


def terminal(path):
    im = Image.new("RGBA", (80, 56), (0, 0, 0, 0))
    for f in range(2):
        ox = f * 40
        fr = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
        d = ImageDraw.Draw(fr)
        accent = (255, 60, 90) if f == 0 else (0, 240, 255)
        rect(d, 8, 50, 32, 54, (20, 20, 36), accent)                              # foot
        rect(d, 11, 24, 29, 50, (24, 28, 52), accent)                             # column
        rect(d, 5, 4, 35, 30, (14, 16, 32), accent)                               # monitor
        rect(d, 8, 7, 32, 27, (6, 10, 24))                                        # screen
        for i, w in enumerate((18, 12, 16, 8)):
            rect(d, 10, 9 + i * 4, 10 + w, 10 + i * 4, accent)
        if f == 1:
            rect(d, 24, 22, 30, 25, (0, 240, 255))                                # "granted" tick
        for i in range(3):
            rect(d, 13 + i * 5, 38, 16 + i * 5, 40, accent)                       # keys
        d.line([20, 4, 20, 0], fill=c(accent))
        im.paste(outline(fr), (ox, 0))
    im.save(path)


if __name__ == "__main__":
    sheet(RUNNER, "assets3d/sprites/player_3d.png")
    sheet(FIXER, "assets3d/sprites/fixer_3d.png")
    drone("assets3d/sprites/drone_3d.png")
    enforcer("assets3d/sprites/enforcer_3d.png")
    stalker("assets3d/sprites/stalker_3d.png")
    sentry("assets3d/sprites/sentry_3d.png")
    curator("assets3d/sprites/curator_3d.png")
    lever("assets3d/sprites/lever_3d.png")
    terminal("assets3d/sprites/terminal_3d.png")
    print("wrote assets3d/sprites/*.png")
