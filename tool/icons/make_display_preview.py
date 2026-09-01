#!/usr/bin/env python3
"""Prévia de validação visual (splash + header) — usa APENAS os assets reais:
- "icone" na splash (fundo dark, ~78% do menor lado, sem máscara/círculo)
- "iconeinicio.png" como marca do header (48px / 40px compact, com NEXUS GYM
  centralizado verticalmente e tagline alinhada ao "N" pela mesma coluna)

Não é asset do app; é apenas referência para conferência.
"""

import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ICONE = os.path.join(ROOT, "icone")
MARCA = os.path.join(ROOT, "iconeinicio.png")
OUT = os.path.join(ROOT, "tool/icons/display_preview.png")

SPLASH_BG = (11, 11, 13)          # #0B0B0D
APP_BG = (13, 13, 15)             # #0D0D0F
SURFACE2 = (35, 38, 43)           # #23262B
STROKE = (44, 48, 56)             # #2C3038
TEXT = (230, 230, 230)            # #E6E6E6
TEXT_DIM = (154, 154, 163)        # #9A9AA3
ACCENT = (108, 92, 255)           # #6C5CFF
ACCENT2 = (154, 140, 255)         # #9A8CFF

FONT_DISPLAY = os.path.join(ROOT, "assets/fonts/SpaceGrotesk.ttf")
FONT_BODY = os.path.join(ROOT, "assets/fonts/Inter.ttf")


def font(path, size, weight=None):
    try:
        f = ImageFont.truetype(path, size)
        if weight:
            try:
                f.set_variation_by_name(weight)
            except Exception:
                pass
        return f
    except Exception:
        return ImageFont.load_default()


def draw_text(d, xy, s, f, fill, spacing=0.0):
    if spacing <= 0:
        d.text(xy, s, font=f, fill=fill)
        return
    x, y = xy
    for ch in s:
        w = d.textlength(ch, font=f)
        d.text((x, y), ch, font=f, fill=fill)
        x += w + spacing


def text_w(s, f, spacing=0.0):
    total = 0.0
    for ch in s:
        total += f.getlength(ch) + spacing
    return total - (spacing if s else 0.0)


def radial_glow(size, color, peak=0.10):
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    steps = 48
    max_r = int(size / 2)
    for i in range(steps, 0, -1):
        r = int(max_r * i / steps)
        a = int(255 * peak * (1 - i / steps) ** 1.6)
        gd.ellipse((size / 2 - r, size / 2 - r, size / 2 + r, size / 2 + r),
                   fill=color + (a,))
    return glow.filter(ImageFilter.GaussianBlur(size * 0.12))


def splash(w_dp=390.0, h_dp=844.0, scale=1.0):
    """Mock: asset 'icone' em min(lado)*0.78 [240..340], completo, central."""
    W, H = int(w_dp * scale), int(h_dp * scale)
    img = Image.new("RGB", (W, H), SPLASH_BG)
    icon = int(max(240.0, min(340.0, min(w_dp, h_dp) * 0.78)) * scale)
    g = radial_glow(int(icon * 1.55), ACCENT, 0.10)
    img.paste(g, ((W - g.width) // 2, (H - g.height) // 2), g)
    art = Image.open(ICONE).convert("RGBA").resize((icon, icon), Image.LANCZOS)
    img.paste(art, ((W - icon) // 2, (H - icon) // 2), art)
    return img


def header(width_dp=390.0, scale=2.0):
    """Mock fiel do header final (mesma estrutura/tokens do Flutter)."""
    compact = width_dp < 360
    W, H = int(width_dp * scale), int(340 * scale)
    img = Image.new("RGB", (W, H), APP_BG)
    d = ImageDraw.Draw(img, "RGBA")

    # glows + anel (mesmos elementos abstratos do app)
    g = radial_glow(int(460 * scale), ACCENT, 0.12)
    img.paste(g, (W - g.width + int(60 * scale), -int(110 * scale)), g)
    ring = Image.new("RGBA", (int(380 * scale),) * 2, (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    rd.ellipse((0, 0, ring.width - 2, ring.height - 2),
               outline=ACCENT + (20,), width=max(2, int(2.4 * scale)))
    img.paste(ring, (-int(150 * scale), H - int(170 * scale)), ring)

    pad_l = int(24 * scale)
    pad_t = int((compact and 12 or 16) * scale)
    mark = int((compact and 40 or 48) * scale)
    gap = int((compact and 8 or 10) * scale)
    mark_img = Image.open(MARCA).resize((mark, mark), Image.LANCZOS).convert("RGBA")
    mg = radial_glow(int(230 * scale), ACCENT, 0.11)
    img.paste(mg, (pad_l - int((62 if compact else 54) * scale),
                   pad_t - int((66 if compact else 58) * scale)), mg)

    # —— linha 1: ícone próprio + coluna de texto (mesma origem X) ——
    img.paste(mark_img, (pad_l, pad_t), mark_img)
    text_x = pad_l + mark + gap
    text_w_avail = W - text_x - int(130 * scale)  # reserva p/ badge + gaps
    logo_size = int((compact and 24 or 27) * scale)
    logo_font = font(FONT_DISPLAY, logo_size, "Bold")
    gym_font = font(FONT_DISPLAY, logo_size, "SemiBold")
    nat_w = text_w("NEXUS", logo_font, 2.0 * scale) + \
        logo_font.getlength(" ") + 2.0 * scale + \
        text_w("GYM", gym_font, 2.0 * scale)
    fit = min(1.0, text_w_avail / nat_w) if nat_w > 0 else 1.0
    ls = int(logo_size * max(0.55, fit))
    logo_font = font(FONT_DISPLAY, ls, "Bold")
    gym_font = font(FONT_DISPLAY, ls, "SemiBold")
    # título centralizado verticalmente na linha da altura do ícone
    y_logo = pad_t + (mark - ls) // 2
    x = text_x
    draw_text(d, (x, y_logo), "NEXUS", logo_font, TEXT, spacing=2.0 * scale)
    x += text_w("NEXUS", logo_font, 2.0 * scale) + \
        logo_font.getlength(" ") + 2.0 * scale
    draw_text(d, (x, y_logo), "GYM", gym_font, ACCENT, spacing=2.0 * scale)

    # —— tagline na MESMA coluna (alinhada ao N) ——
    tag_size = int((compact and 11.5 or 12.5) * scale)
    tag_font = font(FONT_BODY, tag_size, "Medium")
    tag_nat = int(d.textlength("Seu treino. Seu progresso.", font=tag_font))
    tag_fit = min(1.0, text_w_avail / tag_nat) if tag_nat > 0 else 1.0
    if tag_fit < 1.0:
        tag_size = int(tag_size * max(0.55, tag_fit))
        tag_font = font(FONT_BODY, tag_size, "Medium")
    tag_y = pad_t + mark + int((compact and 4 or 6) * scale)
    d.text((text_x, tag_y), "Seu treino. Seu progresso.", font=tag_font,
           fill=TEXT_DIM)

    # —— badge de data à direita (centrado no bloco) ——
    b_font = font(FONT_BODY, int(10.5 * scale), "Bold")
    b_h = int(31 * scale)
    b_w = int(118 * scale)
    b_x = W - pad_l - b_w
    b_y = pad_t + (mark + int((compact and 4 or 6) * scale) +
                   int(tag_size) - b_h) // 2
    d.rounded_rectangle((b_x, b_y, b_x + b_w, b_y + b_h), radius=int(10 * scale),
                        fill=SURFACE2, outline=STROKE, width=int(1.2 * scale))
    ci = int(14 * scale)
    cx, cy = b_x + int(12 * scale), b_y + (b_h - ci) // 2
    d.rounded_rectangle((cx, cy, cx + ci, cy + ci), radius=int(3 * scale),
                        outline=ACCENT2, width=max(2, int(1.4 * scale)))
    d.line((cx + ci * 0.25, cy + ci * 0.35, cx + ci * 0.75, cy + ci * 0.35),
           fill=ACCENT2, width=max(2, int(1.4 * scale)))
    d.rounded_rectangle((cx + ci * 0.32, cy + ci * 0.42, cx + ci * 0.52, cy + ci * 0.58),
                        radius=int(1 * scale), fill=ACCENT2)
    d.text((b_x + int(30 * scale), b_y + (b_h - int(10.5 * scale)) // 2 - int(1 * scale)),
           "TER · 1 SET", font=b_font, fill=TEXT_DIM)

    # —— separador + TREINOS (respiro equilibrado) ——
    sep_y = tag_y + int(tag_size) + int((compact and 11 or 16) * scale)
    sep_w = W - pad_l * 2
    for i in range(int(sep_w * 2)):
        t = i / (sep_w * 2)
        a = int(255 * (0.75 if 0.02 < t < 0.5 else 0.0))
        d.line((pad_l + i / 2, sep_y, pad_l + i / 2, sep_y), fill=STROKE + (a,), width=1)

    t_font = font(FONT_DISPLAY, int(22 * scale), "Bold")
    ty = sep_y + 1 + int((compact and 8 or 11) * scale)
    d.text((pad_l, ty), "TREINOS", font=t_font, fill=TEXT)
    bar_x = pad_l + d.textlength("TREINOS", font=t_font) + int(10 * scale)
    bar_w = W - pad_l - bar_x
    for i in range(int(bar_w * 2)):
        t = i / max(1, int(bar_w * 2))
        a = int(255 * 0.55 * max(0.0, 1 - t))
        d.line((bar_x + i / 2, ty + int(26 * scale), bar_x + i / 2, ty + int(29 * scale)),
               fill=ACCENT + (a,), width=1)

    return img


def main():
    sp_l = splash(390.0, 844.0)
    sp_s = splash(320.0, 568.0)
    hd_l = header(390.0)
    hd_s = header(320.0)
    gx, gy = 36, 36
    W = sp_l.width + gx + sp_s.width + gx + max(hd_l.width, hd_s.width) + 2 * 40
    H = max(sp_l.height, sp_s.height) + gy + max(hd_l.height, hd_s.height) + 130
    canvas = Image.new("RGB", (W, H), (8, 8, 10))
    d = ImageDraw.Draw(canvas)
    cap = font(FONT_BODY, 19, "Medium")

    x = 40
    canvas.paste(sp_l, (x, 70))
    d.text((x, 40), "SPLASH 390x844 — logo 304px (78%), completo, sem máscara",
           font=cap, fill=(170, 170, 180))
    x += sp_l.width + gx
    canvas.paste(sp_s, (x, 70))
    d.text((x, 40), "SPLASH 320x568 — logo 250px (78%), completo",
           font=cap, fill=(170, 170, 180))

    y = 70 + max(sp_l.height, sp_s.height) + gy
    x = 40
    canvas.paste(hd_l, (x, y))
    d.text((x, y - 30), "HEADER 390dp — marca 48px, tagline no \"N\"",
           font=cap, fill=(170, 170, 180))
    x += hd_l.width + gx
    canvas.paste(hd_s, (x, y))
    d.text((x, y - 30), "HEADER 320dp — marca 40px, sem overflow",
           font=cap, fill=(170, 170, 180))

    canvas.save(OUT)
    print("preview:", OUT, canvas.size)


if __name__ == "__main__":
    main()
