"""Register sprite cells and convert to WoW texture format, without redrawing.

All poses use ONE scale factor. No independent stretching or smoothing.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
for faction in ("horde", "alliance"):
    source = Image.open(root / "art" / f"auction-scribe-{faction}-pixel16.png").convert("RGBA")
    frames = []
    for n in range(16):
        col, row = n % 4, n // 4
        frame = source.crop((round(col*source.width/4), round(row*source.height/4),
                             round((col+1)*source.width/4), round((row+1)*source.height/4)))
        alpha = frame.getchannel("A").point(lambda x: 255 if x > 64 else 0)
        bounds = alpha.getbbox()
        assert bounds, n
        frames.append(frame.crop(bounds))
    scale = min(240 / max(f.width for f in frames), 240 / max(f.height for f in frames))
    sheet = Image.new("RGBA", (1024, 1024))
    for n, frame in enumerate(frames):
        size = (round(frame.width*scale), round(frame.height*scale))
        frame = frame.resize(size, Image.Resampling.NEAREST)
        sheet.paste(frame, ((n%4)*256+(256-size[0])//2, (n//4)*256+248-size[1]))
    sheet.save(root / "art" / f"auction-scribe-{faction}-pixel16-packed.png")
    sheet.save(root / "ForeverWaylaid" / "Art" / f"AuctionScribe{faction.title()}Pixel16.tga", compression=None)
    print(faction, "one scale:", scale, "cell dimensions:", [(f.width, f.height) for f in frames])
