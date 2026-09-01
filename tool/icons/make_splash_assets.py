#!/usr/bin/env python3
"""Gera os assets de splash (Android/iOS) a partir do arquivo ORIGINAL do ícone.

Uso:
    python tool/icons/make_splash_assets.py <caminho-do-icone>

O asset � tratado como fonte EXATA — nada � redesenhado, apenas redimensionado
(LANCZOS) para os tamanhos exigidos pelas plataformas:

- Android (splash pr�-Android 12): drawable-{mdpi..xxxhdpi}/splash_icon.png
  (200dp : 200/300/400/600/800 px)
- iOS: Assets.xcassets/LaunchImage.imageset (200pt : 200/400/600 px)

Nenhum arquivo original � alterado.
"""

import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# 240dp de tamanho visual da marca na splash (presença forte, sem ocupar a
# tela inteira; o Android 12+ não usa esta camada — ver "splash_placeholder").
ANDROID_DP = 240
ANDROID = {
    "mdpi": ANDROID_DP,      # 240 px
    "hdpi": ANDROID_DP * 3 // 2,    # 360 px
    "xhdpi": ANDROID_DP * 2,        # 480 px
    "xxhdpi": ANDROID_DP * 3,       # 720 px
    "xxxhdpi": ANDROID_DP * 4,      # 960 px
}
IOS = {"LaunchImage.png": 240, "LaunchImage@2x.png": 480, "LaunchImage@3x.png": 720}


def main():
    if len(sys.argv) < 2:
        print("uso: make_splash_assets.py <icone>")
        return 1
    src = sys.argv[1]
    im = Image.open(src).convert("RGB")
    print(f"fonte: {src} ({im.size[0]}x{im.size[1]})")

    for dpi, px in ANDROID.items():
        out = os.path.join(ROOT, f"android/app/src/main/res/drawable-{dpi}", "splash_icon.png")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        im.resize((px, px), Image.LANCZOS).save(out)
        print(f"android {dpi}: {out} ({px}px)")

    crop_dir = os.path.join(ROOT, "ios/Runner/Assets.xcassets/LaunchImage.imageset")
    for name, px in IOS.items():
        out = os.path.join(crop_dir, name)
        im.resize((px, px), Image.LANCZOS).save(out)
        print(f"ios {name}: {out} ({px}px)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
