# Auction scribe artwork

## Current sixteen-pose sprites (v0.8.0)

- Original generated sources: `auction-scribe-horde-16.png` and `auction-scribe-alliance-16.png`.
- Built-in imagegen edit mode using the original scribes as reference. Full prompts: [scribes-16-prompts.txt](scribes-16-prompts.txt).
- `tools/pack-scribes.py` finds transparent gutters, aligns desk baselines and widths, and converts the poses into separate 1024 × 1024 RGBA TGA atlases with four rows and four columns. Source PNGs remain unchanged. Packed PNG copies allow inspection.
- Runtime files: `AuctionScribeHorde16.tga` and `AuctionScribeAlliance16.tga` in `ForeverWaylaid/Art`.
- Sixteen authored poses per faction, with eased adjacent-pose blending, including frame 16 to frame 1. Four seconds per idle loop; 2.88 seconds during scans. Head, writing hand and candle flame vary across the poses.
- Previous four/eight-pose source and runtime assets are retained for reference; the new scanner loads the sixteen-pose files.

## Archived eight-frame sprites (v0.5.1)

- Source: `auction-scribes-8.png` (1254 × 1254 transparent RGBA).
- Runtime: `../ForeverWaylaid/Art/AuctionScribes8.tga` (1024 × 1024 uncompressed RGBA TGA).
- Created in built-in image-generation edit mode, preserving the original faction scribes. The runtime conversion only resamples with nearest-neighbor to WoW's power-of-two texture dimensions.
- Four columns, eight orc poses across the upper two rows and eight human poses across the lower two. The runtime uses equal-height UV windows to align desk baselines despite different transparent padding between source rows.
- Eight frames run at 0.24 seconds each while idle and 0.11 seconds each during a scan.

### Eight-frame edit prompt

Use case: identity-preserve. Edit the supplied game sprite atlas into a smoother 8-frame loop PER CHARACTER, preserving exactly the same WoW Classic pixel-art orc and human scribes, faction clothing, faces, desks, props, palettes, lighting and hand-drawn pixel style the user loves. Output a transparent RGBA square 2048x2048 sprite atlas, a strict 4-column by 4-row grid of 16 equal 512x512 cells. Rows 1 and 2 contain the Horde orc's eight consecutive animation frames, read left-to-right then down. Rows 3 and 4 contain the Alliance human's eight corresponding frames. Both characters look at a propped auction ledger on their left and write with a feather quill into the open book on the desk. Add genuine in-between poses: frames 1-4 quill hand makes small progressive writing strokes across the page; frames 5-6 eyes and head subtly glance toward reference ledger while quill lifts slightly; frames 7-8 return smoothly to writing pose. Retain identical seated body, desk, books, inkpot, candle, chair and scale in EVERY cell. Fixed camera and anchoring, all subjects within equal cells with 30px clear padding and same baseline. Only writing hand, quill, eyes, slight head movement and subtle candle flame animate. Distinct but SMALL movements, no big body jumps. Eight distinct poses for each character. True transparent background outside sprites. No grid lines, labels, words, watermark, extra objects, scenery or borders. This is the actual production sprite sheet, not a mockup. Strong unmistakable Warcraft Classic aesthetic. Do not redesign the characters.

### Final layout-repair prompt

Edit this sprite atlas for production use. Preserve these exact Warcraft orc and Alliance human scribes and all sixteen poses. CRITICAL layout repair: output SQUARE canvas, strict FOUR columns by FOUR rows of equally sized SQUARE cells. Each individual sprite must be smaller inside its cell: maximum 80 percent of cell width and 80 percent cell height. At least 10 percent fully transparent margin on ALL FOUR sides of EACH sprite. No pixels touch any cell boundary. Same baseline and desk size in every cell. Top two rows = 8 orc frames; bottom two rows = 8 human frames. Read order left to right then down. Preserve gradual quill writing and glance animation; keep bodies and desks consistently anchored. Transparent RGBA background. No gridlines, lettering or labels. Layout and padding correction only, do not redesign characters. Exact 2048x2048 preferred.

## Archived four-frame sprites (restored in v0.6.0)

- Source: `auction-scribes.png` (transparent RGBA, 1774 × 887).
- Runtime: `../ForeverWaylaid/Art/AuctionScribes.tga` (1024 × 512 RGBA, uncompressed TGA).
- Generated with the built-in image-generation tool. Original output retained; runtime conversion resamples with nearest-neighbor to power-of-two dimensions required by WoW textures.
- Four animation columns; Horde orc in row one, Alliance human in row two. Runtime UV animation selects the faction row, advancing faster while scanning.

## Final generation prompt

Use case: stylized-concept. Production game UI sprite atlas for a WoW Classic-style auction scanner. Create one transparent PNG, exactly 2048x1024 landscape, a strict 4-column by 2-row grid of eight equal 512x512 cells. No gutters, no grid lines, no lettering, no labels, no watermark. Each cell has identical fixed camera, scale, desk position, and 40px safety padding; no sprite crosses cell boundaries. Crisp polished 16-bit pixel art, large legible pixels, dark outlines, warm candlelit medieval fantasy merchant desk. Top row: four consecutive looping animation frames of ONE same green-skinned male orc clerk with small tusks and a red/brown merchant tunic, seated behind a wooden desk, consulting a propped auction ledger on his left and writing with a quill into an open book centered on the desk. Bottom row: corresponding four frames of ONE same human Alliance clerk, chestnut hair, blue/gold tunic, same composition and props. This is a working merchant, not a warrior. Desk, inkpot, reference ledger and body remain absolutely fixed across all four columns. Animate only the quill hand making a small writing stroke and a subtle glance between reference ledger and writing book. Column 1 quill at start of a line; column 2 quill hand slightly right/down; column 3 quill right/up, eyes briefly at reference; column 4 quill returns smoothly toward column 1. Keep writing arm visibly different between frames but same anatomy. Both characters should read clearly at 220px displayed size. Entire non-sprite area is true alpha transparency, no shadows outside each cell, no background scenery. Deliver the atlas, not a mockup of an atlas.
