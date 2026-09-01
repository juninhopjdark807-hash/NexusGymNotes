#!/usr/bin/env python3
"""Generate launcher icon assets from tool/icons/app_icon_nexus_gen.png.

Aplica o mesmo ícone em Android (mipmap-*), iOS (AppIcon.appiconset) e Web,
e gera um preview com as máscaras reais do sistema (Android circular,
iOS cantos arredondados).
"""
import json
import os
import sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(HERE, "app_icon_nexus_gen.png")
PREVIEW = os.path.join(HERE, "app_icon_launcher_preview.png")


def load_master(source=SRC, size=1024):
    im = Image.open(source).convert("RGB")
    if im.size != (size, size):
        im = im.resize((size, size), Image.LANCZOS)
    im.save(os.path.join(HERE, "app_icon_master.png"))
    return im


def save_android(master):
    sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for dpi, s in sizes.items():
        path = os.path.join(ROOT, "android", "app", "src", "main", "res",
                            f"mipmap-{dpi}", "ic_launcher.png")
        master.resize((s, s), Image.LANCZOS).save(path)
        print("android", dpi, s)


def save_ios(master):
    d = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets",
                     "AppIcon.appiconset")
    meta = json.load(open(os.path.join(d, "Contents.json")))
    for img in meta["images"]:
        fn = img.get("filename")
        if not fn:
            continue
        size = float(img["size"].split("x")[0])
        scale = int(img["scale"].rstrip("x"))
        s = int(round(size * scale))
        master.resize((s, s), Image.LANCZOS).save(os.path.join(d, fn))
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


def preview(master, out=PREVIEW):
    bg = (13, 13, 15, 255)
    W, H = 860, 560
    img = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)

    def label(x, y, s):
        d.text((x, y), s, font=font, fill=(214, 212, 228), anchor="ma")

    def masked(size, shape, radius=0.22):
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

    sq = master.resize((420, 420), Image.LANCZOS)
    img.paste(sq, (12, 12))
    label(222, 452, "1024px — fonte")
    a = masked(220, "circle")
    img.paste(a, (456, 12), a)
    label(566, 254, "Android — máscara circular")
    b = masked(200, "rounded")
    img.paste(b, (456, 300), b)
    label(556, 522, "iOS — cantos do sistema")
    x0 = 700
    for s in [96, 48, 32]:
        icon = master.resize((s, s), Image.LANCZOS)
        img.paste(icon, (x0, 12 if s == 96 else (120 if s == 48 else 190)))
    img.save(out)
    print("preview", out, img.size)


def main():
    master = load_master()
    save_android(master)
    save_ios(master)
    save_web(master)
    preview(master)


if __name__ == "__main__":
    main()
