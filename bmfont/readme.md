# BMFont Library Guide

**BmFont** is a lightweight bitmap font rendering library for coop. It supports loading BMFont (`.fnt`) files or simple sprite sheets, kerning, alignment options, and per‑glyph animations.

![](image.png?raw=true)

**Requires <ins>sm64coopdx v1.4</ins> or above**

<br />
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
-- ... or ...
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

<br />
---
<br />

## Adding New Fonts

1. Goto [snowb.org](https://snowb.org/), it's a tool to convert fonts to BmFonts
2. Add your font file using the `ADD FONT FILE` button
3. Copy and paste all of the characters from [djui-chars.txt](https://raw.githubusercontent.com/djoslin0/coop-lua-libraries/refs/heads/main/bmfont/djui-chars.txt) into the glyphs section of the website.
4. Uncheck `Auto Pack` and check `Fixed Size`
5. Set `Width` to `1024` and `Height` to `512` (you can use other powers of 2 if you wish)
6. Decrease `Font Size` until all of the glyphs pack into the image
7. Click `Export` at the top, export as a `.txt (BMFont TEXT)`
8. Copy the `png` file from the exported zip to `textures/bmfont-YOURFONTNAME.png`
9. Open the `txt` file from the exported zip and copy everything inside of it
10. Create a new file at `your_mod_folder/fonts/bmfont-YOURFONTNAME.lua` that contains the following:
```lua
return [[
-- PASTE THE CONTENTS OF THE TXT FILE HERE, BETWEEN THE DOUBLE BRACKETS
]]
```

Now you should be able to load your font in your script
```lua
local FONT_YOURFONTNAME = BmFont.load_fnt('bmfont-YOURFONTNAME')
```

**Note** - the name of your texture and the name of the lua file **must match**.

So if you use the font name `comic-sans`:
* you should have a lua file at `your_mod_folder/fonts/bmfont-comic-sans.lua`
* you should have a png file at `your_mod_folder/textures/bmfont-comic-sans.png`

<br />
---
<br />

## Core Functions

#### `BmFont.load_fnt(font_name)`

Loads a BMFont `.fnt` definition (converted to a Lua file returning the raw text) plus its texture:

```lua
-- Returns a CustomFont object
local font = BmFont.load_fnt('bmfont-tt-masters')
```

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

<br />
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
local function wave_anim(index, length, output)
  local t = index + get_global_timer() * 4
  output.offset.y = math.sin(t) * 5
end
BmFont.print_center_aligned(FONT_ZD, "WAVE", 200, 200, 2, wave_anim)
```

<br />
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

<br />
---
<br />

## Example Mod

And example mod is located [here](example-mod), if you wish to see it running. It includes a few text animations and fonts.