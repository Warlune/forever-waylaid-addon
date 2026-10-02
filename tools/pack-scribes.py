"""Pack generated poses into WoW textures; no repainting or synthesized poses.

Requires Pillow. Source PNGs are retained unchanged. Align the desk bottoms and
normalize their widths, preserving each pose's aspect ratio and alpha channel.
"""
from pathlib import Path
from collections import deque
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CELL = 256

def gutters(image, horizontal):
    """Locate transparent gutters near the requested grid, allowing AI padding drift."""
    alpha = image.getchannel("A")
    length = image.width if horizontal else image.height
    cuts = [0]
    for n in range(1, 4):
        nominal = length * n / 4
        candidates = range(round(nominal-length/24), round(nominal+length/24))
        scores = {}
        for position in candidates:
            strip = alpha.crop((position, 0, position+1, image.height) if horizontal
                               else (0, position, image.width, position+1))
            scores[position] = sum(strip.histogram()[33:])
        minimum = min(scores.values())
        best = [p for p in candidates if scores[p] == minimum]
        cuts.append(best[len(best)//2])
    return cuts + [length]

def subject_bounds(frame):
    # Ignore tiny detached edge pixels from a neighboring cell when measuring
    # the desk. The source art itself is not repainted or masked.
    alpha = frame.getchannel("A")
    pixels = alpha.load()
    unseen = {(x, y) for y in range(frame.height) for x in range(frame.width) if pixels[x, y] > 32}
    largest = []
    while unseen:
        start = unseen.pop()
        todo = deque([start])
        component = [start]
        while todo:
            x, y = todo.popleft()
            for point in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if point in unseen:
                    unseen.remove(point); todo.append(point); component.append(point)
        if len(component) > len(largest):
            largest = component
    assert largest, "Empty sprite cell"
    xs, ys = zip(*largest)
    return min(xs), min(ys), max(xs)+1, max(ys)+1

for faction in ("horde", "alliance"):
    source = Image.open(ROOT / "art" / f"auction-scribe-{faction}-16.png").convert("RGBA")
    sheet = Image.new("RGBA", (CELL * 4, CELL * 4))
    boxes = []
    rows = gutters(source, False)
    columns = [gutters(source.crop((0, rows[r], source.width, rows[r+1])), True) for r in range(4)]
    for index in range(16):
        col, row = index % 4, index // 4
        frame = source.crop((columns[row][col], rows[row], columns[row][col+1], rows[row+1]))
        bounds = subject_bounds(frame)
        assert bounds, f"Missing {faction} frame {index}"
        # Include the soft edge around the visible silhouette.
        x0, y0, x1, y1 = bounds
        bounds = (max(0, x0-2), max(0, y0-2), min(frame.width, x1+2), min(frame.height, y1+2))
        frame = frame.crop(bounds)
        size = (240, round(frame.height * 240 / frame.width))
        assert size[1] <= 244, f"Unexpected pose proportions: {size}"
        frame = frame.resize(size, Image.Resampling.LANCZOS)
        sheet.paste(frame, (col * CELL + 8, row * CELL + 248 - size[1]))
        boxes.append(bounds)
    output = ROOT / "WaylaidForever" / "Art" / f"AuctionScribe{faction.title()}16.tga"
    sheet.save(output, compression=None)
    # Exact same atlas in PNG for inspection and future asset tooling.
    sheet.save(ROOT / "art" / f"auction-scribe-{faction}-16-packed.png")
    print(f"Packed {faction}: 16 poses, 1024x1024 RGBA, aligned desk baselines")
