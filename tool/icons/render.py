#!/usr/bin/env python3
"""Render tool/icons/spec.json as a badge sheet, mimicking the approved reference.

The spec is the single source of truth: the same primitives are later compiled
into the Flutter CustomPainter, so what renders here is what ships.
"""
import json
import math
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = json.load(open(os.path.join(HERE, "spec.json"), encoding="utf-8"))
OUT = os.path.join(HERE, "preview.png")

BG = (13, 13, 15, 255)
FILL = (20, 17, 42, 255)
RING = (108, 92, 255, 255)
INK = (232, 228, 255, 255)
LABEL = (220, 220, 228, 255)

TOP = ["peito", "costas", "pernas"]
GRID = ["ombros", "biceps", "triceps", "abdomen", "gluteos",
        "posterior", "gluteos", "panturrilha", "cardio", "outros"]


def _bez(p0, p1, p2, p3=None, n=32):
    pts = []
    for i in range(n + 1):
        t = i / n
        if p3 is None:
            x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
            y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
        else:
            x = ((1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0]
                 + 3 * (1 - t) * t ** 2 * p2[0] + t ** 3 * p3[0])
            y = ((1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1]
                 + 3 * (1 - t) * t ** 2 * p2[1] + t ** 3 * p3[1])
        pts.append((x, y))
    return pts


def polylines(prim):
    """Flatten spec primitives into a list of polylines (0-100 coords)."""
    out = []
    for p in prim:
        t = p["t"]
        if t == "line":
            x1, y1, x2, y2 = p["p"]
            out.append([(x1, y1), (x2, y2)])
        elif t == "circle":
            cx, cy, r = p["p"]
            pts = [(cx + r * math.cos(i / 40 * 2 * math.pi),
                    cy + r * math.sin(i / 40 * 2 * math.pi)) for i in range(41)]
            out.append(pts)
        elif t == "rrect":
            x, y, w, h, r = p["p"]
            seg = 8
            def arc(ax, ay, a0, a1):
                return [(ax + r * math.cos(a0 + (a1 - a0) * i / seg),
                         ay + r * math.sin(a0 + (a1 - a0) * i / seg))
                        for i in range(seg + 1)]
            pts = []
            pts += arc(x + r, y + r, math.pi, 1.5 * math.pi)
            pts += arc(x + w - r, y + r, 1.5 * math.pi, 2 * math.pi)
            pts += arc(x + w - r, y + h - r, 0, 0.5 * math.pi)
            pts += arc(x + r, y + h - r, 0.5 * math.pi, math.pi)
            out.append(pts)
        elif t == "path":
            d = p["d"]
            pts = [tuple(d[0][1:])]
            for cmd in d[1:]:
                cur = pts[-1]
                if cmd[0] == "L":
                    pts.append(tuple(cmd[1:]))
                elif cmd[0] == "Q":
                    pts += _bez(cur, tuple(cmd[1:3]), tuple(cmd[3:5]))[1:]
                elif cmd[0] == "C":
                    pts += _bez(cur, tuple(cmd[1:3]), tuple(cmd[3:5]),
                                tuple(cmd[5:7]))[1:]
            out.append(pts)
    return out


def draw_icon(name, icon_size, sw):
    canvas = int(round(icon_size)) + 4
    img = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    scale = icon_size / 100.0
    off = 2
    width = max(1, int(round(sw)))
    for poly in polylines(SPEC[name]):
        pts = [(off + x * scale, off + y * scale) for x, y in poly]
        d.line(pts, fill=INK, width=width, joint="curve")
    return img


def badge(name, size):
    pad = 6
    total = size + pad * 2
    img = Image.new("RGBA", (total, total), BG)
    d = ImageDraw.Draw(img)

    # soft purple glow
    glow = Image.new("RGBA", (total, total), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([pad - 10, pad - 10, pad + size + 10, pad + size + 10],
               outline=(108, 92, 255, 60), width=12)
    gd.ellipse([pad - 5, pad - 5, pad + size + 5, pad + size + 5],
               outline=(108, 92, 255, 100), width=6)
    img = Image.alpha_composite(img, glow)

    d = ImageDraw.Draw(img)
    d.ellipse([pad, pad, pad + size, pad + size], fill=FILL)
    d.ellipse([pad, pad, pad + size, pad + size],
              outline=RING, width=max(2, int(round(size * 0.045))))

    icon_size = size * 0.64
    sw = max(1.5, icon_size * 0.05)
    ic = draw_icon(name, icon_size, sw)
    img.alpha_composite(ic, (pad, pad))
    return img


def main():
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 20)
    big, small = 168, 150
    label_h = 30
    pad = 8

    w = max(3 * big + 2 * pad, 5 * small + 4 * pad) + 24
    h = 12 + big + label_h + 10 + 2 * (small + label_h) + 12
    img = Image.new("RGBA", (w, h), BG)
    d = ImageDraw.Draw(img)

    x = 12 + big // 2
    y = 12 + big // 2
    for name in TOP:
        b = badge(name, big)
        img.alpha_composite(b, (int(x - b.width / 2), int(y - b.height / 2)))
        d.text((x, y + big / 2 + 6), name.upper(), font=font, fill=LABEL, anchor="ma")
        x += big + pad

    y = 12 + big + label_h + 10 + small // 2
    x = 12 + small // 2
    for i, name in enumerate(GRID):
        b = badge(name, small)
        img.alpha_composite(b, (int(x - b.width / 2), int(y - b.height / 2)))
        d.text((x, y + small / 2 + 4), name.upper(), font=font, fill=LABEL, anchor="ma")
        if (i + 1) % 5 == 0:
            y += small + label_h + 6
            x = 12 + small // 2
        else:
            x += small + pad

    img.convert("RGB").save(OUT)
    print("saved", OUT, img.size)


if __name__ == "__main__":
    main()
