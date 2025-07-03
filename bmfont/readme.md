# BMFont Library Guide

**BmFont** is a lightweight bitmap font rendering library for coop. It supports loading BMFont (`.fnt`) files or simple sprite sheets, kerning, alignment options, and per‑glyph animations.

---

<br />

## Installation

1. [Download the libraries](https://github.com/djoslin0/coop-lua-libraries/archive/refs/heads/main.zip)

2. Copy the `lib` folder from `bmfont/lib` into your mod's folder.
e.g. `your_mod_folder/lib`

3. Require or import the module at the top of your script:

```lua
local BmFont = require("bmfont")
```

4. Load your custom font
```lua
local FONT_TT_MASTERS  = BmFont.load_fnt('bmfont-tt-masters')
local FONT_ZD          = BmFont.load_sheet('bmfont-zd', 8, 8)
```

5. Use your custom font during `HOOK_ON_HUD_RENDER` using the usual built-in functions
```lua
local function on_hud_render()
    djui_hud_set_font(FONT_TT_MASTERS)
    djui_hud_print_text('hello world', 0, 0, 1)
end
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
```

---

<br />

## Adding New Fonts

TODO

---

<br />

## Core Functions

#### `BmFont.load_fnt(font_name)`

Loads a BMFont `.fnt` definition (converted to a Lua file returning the raw text) plus its texture:

```lua
-- Returns a CustomFont object
local font = BmFont.load_fnt('bmfont-tt-masters')
```

| Field              | Description                                                     |
| ------------------ | --------------------------------------------------------------- |
| `font.chars`       | Mapping `charID -> {x,y,width,height,xoffset,yoffset,xadvance}` |
| `font.kerningMap`  | Kerning adjustments: `kerningMap[first][second] = amount`       |
| `font.common.base` | Line height / base offset                                       |
| `font.texture`     | TextureInfo object for rendering                                |

<br />

#### `BmFont.load_sheet(font_name, tileW, tileH)`

Loads a simple monospaced sprite sheet where each UTF‑8 codepoint in a given string is sequentially mapped onto tiles:

```lua
local FONT_ZD = BmFont.load_sheet('bmfont-zd', 8, 8)
```

It automatically tiles across the sheet texture, assigning `xadvance = tileW` and grouping by codepoint order.

<br />

#### `BmFont.print(font, message, x, y, scale, anim_fn?)`

Renders `message` left‑to‑right at screen position `(x,y)`:

- `font`: CustomFont from `load_fnt` or `load_sheet`
- `message`: Lua string (supports UTF‑8)
- `x, y`: screen coordinates
- `scale`: glyph scale factor
- `anim_fn` (optional): per‑glyph callback `(index, length, TextAnimOutput)` for color/offset/scale tweaks

```lua
BmFont.print(FONT_TT_MASTERS, "Hello World", 100, 50, 1)
```

<br />

#### Alignment Helpers

- `BmFont.print_left_aligned(font, message, x, y, scale, anim_fn)`
- `BmFont.print_right_aligned(font, message, x, y, scale, anim_fn)`
- `BmFont.print_center_aligned(font, message, x, y, scale, anim_fn)`

Each adjusts the `x` origin so text is aligned against `x` at left, right, or center.

---

<br />

### Text Animation

Pass a callback to `BmFont.print` to animate glyphs. The callback receives:

```lua
---@class TextAnimOutput
local o = {
  offset   = {x = 0, y = 0},    -- per‑glyph pixel offset
  color    = {r = 255, g = 255, b = 255, a = 255},
  scale    = {x = 1, y = 1},
  rotation = {rotation = 0, pivot_x = 0.5, pivot_y = 0.5},
}
```

Example: a simple wave effect:

```lua
local function wave_anim(i, len, o)
  local t = i + get_global_timer() * 4
  o.offset.y = math.sin(t) * 5
end
BmFont.print_center_aligned(FONT_ZD, "WAVE", w * 0.5, 200, 2, wave_anim)
```

---

<br />

### BmFont is a Drop-in Replacement

You can use all of the previous text rendering functions in the same way as before, but using the fonts loaded using `BmFont`.
The following functions get overridden allowing you to use custom fonts, or the built in ones.

```lua
djui_hud_set_font(YOUR_CUSTOM_FONT_HERE)
djui_hud_measure_text(text)
djui_hud_print_text(text, x, y, scale)
djui_hud_print_text_interpolated(message, prevX, prevY, prevScale, x, y, scale)
```

---

<br />

## Example Mod

And example mod is located [here](example-mod), if you wish to see it running. It includes a few text animations and fonts.