"""Generate the Windows app icon (.ico) from the brand logo.

Crops the pictogram (left chevrons, without the "GROUPE SABA" text),
squares it on a transparent canvas with padding, and writes a
multi-resolution .ico used by the Windows runner.

Usage:
    python tool/generate_windows_icon.py
"""

from PIL import Image

SRC = "assets/cropped-logo-saba-1-1-1.png"
DST = "windows/runner/resources/app_icon.ico"

# Pictogram region of the source logo (text excluded), found by analyzing
# the alpha channel. The chevron pictogram occupies the top-left area; the
# "GROUPE SABA" text sits in the lower band (y >= ~440), so we crop above it.
PICTOGRAM_BOX = (22, 8, 438, 438)

# Relative padding added around the pictogram inside the square icon.
PADDING_RATIO = 0.08

ICON_SIZES = [16, 24, 32, 48, 64, 128, 256]


def main() -> None:
    logo = Image.open(SRC).convert("RGBA")
    picto = logo.crop(PICTOGRAM_BOX)

    # Tighten to actual non-transparent content inside the crop.
    bbox = picto.getbbox()
    if bbox:
        picto = picto.crop(bbox)

    w, h = picto.size
    side = max(w, h)
    pad = int(side * PADDING_RATIO)
    canvas_side = side + pad * 2

    canvas = Image.new("RGBA", (canvas_side, canvas_side), (0, 0, 0, 0))
    offset = ((canvas_side - w) // 2, (canvas_side - h) // 2)
    canvas.paste(picto, offset, picto)

    canvas.save(DST, format="ICO", sizes=[(s, s) for s in ICON_SIZES])
    print(f"Wrote {DST} ({canvas_side}x{canvas_side} source, sizes={ICON_SIZES})")


if __name__ == "__main__":
    main()
