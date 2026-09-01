#!/usr/bin/env python3
"""Convert the approved icon design into real app-icon assets.

Fixes the usual "it doesn't look the same in the app" problem:
- removes the AI-generated white rounded frame (launchers/masks do that job);
- produces a true square canvas (covers corners) so Android/iOS/web masks
  don't clip into the artwork or show white wedges;
- renders every required size from a single 1024px master.

Usage: python make_app_icons.py [v1|v2]
"""
import json
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
SRC = {
    "v1": os.path.join(HERE, "app_icon_v1.png"),
    "v2": os.path.join(HERE, "app_icon_v2.png"),
}
MASTER = os.path.join(HERE, "app_icon_final.png")
PREVIEW = os.path.join(HERE, "app_icon_preview.png")


def remove_white_frame(src, out=MASTER, size=1024):
    """Replace the white rounded-corner wedges with the dark background."""
    im = Image.open(src).convert("RGB")
    w, h = im.size
    px = im.load()
    box = 210  # corner radius + margin (white wedge lives inside this box)

    def fill_corner(x0, y0, sx, sy):
        # find first dark pixel along the diagonal -> background colour sample
        for d in range(4, box):
            x, y = x0 + sx * d, y0 + sy * d
            if 0 <= x < w and 0 <= y < h and px[x, y][0] < 80:
                col = px[x, y]
                break
        else:
            col = (15, 15, 17)
        # repaint white + antialiased light pixels in the corner wedge
        for dy in range(box):
            for dx in range(box):
                x, y = x0 + sx * (dx if sx > 0 else dx), y0 + sy * (dy if sy > 0 else dy)
                x = x0 + sx * dx
                y = y0 + sy * dy
                if not (0 <= x < w and 0 <= y < h):
                    continue
                r, g, b = px[x, y]
                if r > 100:
                    px[x, y] = col

    fill_corner(0, 0, 1, 1)         # top-left
    fill_corner(w - 1, 0, -1, 1)    # top-right
    fill_corner(0, h - 1, 1, -1)    # bottom-left
    fill_corner(w - 1, h - 1, -1, -1)

    im2 = im.resize((size, size), Image.LANCZOS)
    im2.save(out)
    c = im2.load()
    print("master corners after fill:",
          c[2, 2], c[size - 3, 2], c[2, size - 3], c[size - 3, size - 3])
    return im2


def save_android(master):
    sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for dpi, s in sizes.items():
        path = os.path.join(ROOT, "android", "app", "src", "main", "res",
                            f"mipmap-{dpi}", "ic_launcher.png")
        master.resize((s, s), Image.LANCZOS).save(path)
        print("android", dpi, s)


def save_ios(master):
    d = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    meta = json.load(open(os.path.join(d, "Contents.json")))
    for img in meta["images"]:
        fn = img.get("filename")
        if not fn:
            continue
        size = float(img["size"].split("x")[0])
        scale = int(img["scale"].rstrip("x"))
        s = int(round(size * scale))
        master.resize((s, s), Image.LANCZOS).convert("RGB").save(os.path.join(d, fn))
        print("ios", fn, s)


def save_web(master):
    targets = [
        ("web/favicon.png", 32),
        ("web/icons/Icon-192.png", 192),
        ("web/icons/Icon-512.png", 512),
        ("web/icons/Icon-maskable-192.png", 192),
        ("web/icons/Icon-maskable-512.png", 512),
    ]
    for rel, s in targets:
        p = os.path.join(ROOT, rel)
        master.resize((s, s), Image.LANCZOS).save(p)
        print("web", rel, s)


def contact_sheet(master, out=PREVIEW):
    bg = (13, 13, 15, 255)
    W, H = 860, 560
    img = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
    except Exception:
        font = ImageFont.load_default()

    def label(x, y, s):
        d.text((x, y), s, font=font, fill=(214, 212, 228), anchor="ma")

    def masked(size, shape, radius=0.22):
        pad = 0
        canvas = Image.new("RGBA", (size, size), bg)
        mask = Image.new("L", (size, size), 0)
        md = ImageDraw.Draw(mask)
        if shape == "circle":
            md.ellipse([0, 0, size, size], fill=255)
        else:
            md.rounded_rectangle([0, 0, size, size],
                                 radius=int(size * radius), fill=255)
        icon = master.resize((size, size), Image.LANCZOS)
        canvas.paste(icon, (0, 0), mask)
        return canvas

    # 1) full square master (400)
    sq = master.resize((400, 400), Image.LANCZOS)
    img.paste(sq, (12, 12))
    label(212, 434, "1024px (fonte, cantos escuros)")

    # 2) Android circular 220
    a = masked(220, "circle")
    img.paste(a, (444, 12), a)
    label(554, 254, "Android — máscara circular")

    # 3) iOS rounded 200
    b = masked(200, "rounded")
    img.paste(b, (444, 300), b)
    label(544, 522, "iOS — cantos do sistema")

    # 4) sizes 96 / 48 / 32
    x0 = 700
    yy = 12
    for s in [96, 48, 32]:
        icon = master.resize((s, s), Image.LANCZOS)
        img.paste(icon, (x0, yy))
        label(x0 + s // 2, yy + s + 14, f"{s}px")
        yy += s + 34

    img.save(out)
    print("preview", out, img.size)


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else "v1"
    src = SRC[which]
    master = remove_white_frame(src)
    save_android(master)
    save_ios(master)
    save_web(master)
    contact_sheet(master)


if __name__ == "__main__":
    main()
