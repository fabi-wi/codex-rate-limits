# README hero — v0.2.4

Asset: `readme-hero-v0.2.4.png`

Mode: built-in imagegen, with highest available quality requested in the prompt. The tool exposes no separate quality parameter. Native output: 1672 × 941 pixels; preserved without upscaling.

This is an illustrative product image with example usage values, not a captured account screenshot. The original README banner was the visual reference.

## Initial prompt

```text
Use case: precise-object-edit
Asset type: high-resolution GitHub README hero banner for Codex Rate Limits.
Input image 1: edit target and visual identity reference. Update this existing banner to the current app design, preserving its warm orange-to-purple macOS wallpaper atmosphere, left-hand product title and feature list, and prominent straight-on app popover on the right. Output only the finished banner, never a browser or GitHub page.
Rendering: use the highest available generation quality and maximum text fidelity. Aim for 3840 x 2160, 16:9 landscape. Crisp, production-ready, restrained premium macOS product graphic, readable at GitHub README width. Keep generous outer margins.

Keep the left copy verbatim, beautifully typeset in a clean SF-style sans serif:
"Codex"
"Rate Limits"
"A clean macOS menu-bar companion"
"for tracking Codex usage"
"Track Week & 5-Hour Limits"
"Live usage updates"
"Native macOS menu-bar UI"
"Unofficial open-source companion app"
Retain the small feature icons, updating the concentric-rings icon to green.

Replace the right app interface with a faithful, clean current macOS popover mockup. One continuous translucent native glass surface, softly rounded system-like corners, a single subtle rim, a natural soft shadow, and a small top-center attachment pointer. Absolutely no overlapping rounded rectangles or mismatched corner masks. Use a slightly darker frosted backdrop so white UI text is exceptionally legible.

Popover header:
"Codex Rate Limits"
"Available usage windows"
a small green status dot followed by "Live", plus a quiet circular close button at the upper right.
Below the header, two concentric availability rings with neutral translucent tracks and round arc ends, BOTH vivid system green. Outer ring is 87% full and inner ring is 64% full, starting at 12 o'clock clockwise. Center text: "64%" and a smaller "remaining".

Below the rings show BOTH complete usage rows, in this order, with clear spacing and one subtle divider:
Row 1: green dot, "Week Limit", right-aligned "87%".
Subtitle: "7-day usage window".
Green progress bar filled to exactly 87%.
Below it, left "87% remaining", right "13% used".
One compact line: "resets in 5d 23h 03m 47s".
Row 2: green dot, "5 Hour Limit", right-aligned "64%".
Subtitle: "5-hour usage window".
Green progress bar filled to exactly 64%.
Below it, left "64% remaining", right "36% used".
One compact line: "resets in 02h 18m 09s".

CRITICAL UI constraints: In each countdown line, the words "resets in" and the d/h/m/s value must share exactly the same small font family, size, weight, and muted light color, immediately next to one another on one baseline. No separate days/hours/minutes/seconds captions, no large colored countdown numbers, no tiles. All rings, progress bars, and usage dots are green because both values are above 50%; do not retain the old blue ring or blue progress bar. All percentages, ring extents, and progress bars must agree. Preserve both rows entirely; do not crop out the 5-hour row.
Keep the graphic elegant and uncluttered, without extraneous decorations, computer hardware, invented controls, logos, endorsements, watermarks, version labels, or extra copy. Spell all specified text exactly.
```

## Final correction prompt

```text
Use case: precise-object-edit.
Input image 1: edit target, the newly generated Codex Rate Limits hero banner.
Make exactly one targeted correction: fix the TWO GREEN CIRCULAR PROGRESS ARCS so their geometry agrees with their existing numeric values.

OUTER ring is the WEEKLY value, 87% remaining. Its green arc starts at the top (12 o'clock) and travels CLOCKWISE through 3, 6, and 9 o'clock, ending at approximately 10:26 on the clock face. This green arc covers 313.2 degrees. The only gray missing arc is the small upper-left gap from about 10:26 back to 12 o'clock, covering 46.8 degrees.

INNER ring is the 5-HOUR value, 64% remaining. Its green arc starts at the top (12 o'clock) and travels CLOCKWISE through 3 and 6 o'clock, ending at approximately 7:41 on the clock face. This green arc covers 230.4 degrees. The gray missing arc occupies the upper-left and left side from approximately 7:41 back to 12 o'clock, covering 129.6 degrees.

The OUTER green arc must therefore be substantially LONGER/more complete than the INNER green arc. Keep round caps and both existing ring diameters and thicknesses. The center still says "64%" and "remaining".

Preserve EVERYTHING ELSE exactly: all typography, every word and number, 87% and 64% progress bars, both complete usage rows, compact countdowns, glass popover, feature list, orange-purple background, composition and margins. No new text, no new shapes, no changed stats, no crop. Highest available quality, maximum sharpness and text fidelity. Preserve the wide 16:9 banner format; high-resolution output preferred.
```
