# SpriteSheet3d Library Guide

**SpriteSheet3d** is a library for rendering animated sprite sheets in 3D world space. Given any texture and a tile grid layout, it generates per-tile display lists with correct UVs and swaps them at runtime via a geo ASM callback driven by `oAnimState`.

![](image.gif?raw=true)

**Requires <ins>sm64coopdx v1.4</ins> or above**

<br />

---

<br />

## Installation

1. [Download the libraries](https://github.com/djoslin0/coop-lua-libraries/archive/refs/heads/main.zip)

2. Copy the `lib` folder from `spritesheet3d/lib` into your mod's folder.
e.g. `your_mod_folder/lib`

3. Copy `spritesheet3d_geo.bin` from `spritesheet3d/actors` into your mod's `actors` folder.
e.g. `your_mod_folder/actors/spritesheet3d_geo.bin`

4. Place your sprite sheet texture files in your mod's `textures` folder.
e.g. `your_mod_folder/textures/my_texture.png`

5. Require or import the module at the top of your script:

```lua
local SpriteSheet3d = require("/lib/spritesheet3d")
```

6. Load a sprite sheet and apply it to an object:

```lua
local tex = SpriteSheet3d.load("my_texture", 4, 4)  -- 4 columns, 4 rows = 16 frames

spawn_non_sync_object(id_bhvExample, SpriteSheet3d.model, x, y, z, function(obj)
    SpriteSheet3d.apply(obj, tex)
end)
```

7. Advance the animation by setting `oAnimState` in your behavior loop:

```lua
local function bhv_loop(obj)
    obj.oAnimState = obj.oTimer // 2  -- advance one frame every 2 game frames
end
```

<br />

---

<br />

## Adding Textures

Place your sprite sheet `.png` file in your mod's `textures` folder:
- `your_mod_folder/textures/my_texture.png`

The name passed to `SpriteSheet3d.load()` must match the filename **without** the extension.

```lua
local tex = SpriteSheet3d.load("my_texture", 4, 4)
```

<br />

---

<br />

## Core Functions

#### `SpriteSheet3d.load(texture_name, tiles_x?, tiles_y?)`

Loads a sprite sheet texture and builds a display list for each tile. Returns a `SpriteSheet` object that can be reused across many objects.

- `texture_name`: the name of the texture as registered via DynOS / `TEX_*`
- `tiles_x` (optional): number of columns in the sheet (default `1`)
- `tiles_y` (optional): number of rows in the sheet (default `1`)

```lua
-- 4x4 grid = 16 frames
local tex = SpriteSheet3d.load("s3d_explosion", 4, 4)
```

Tiles are indexed left-to-right, top-to-bottom. Display lists for a given texture are cached and shared — calling `load` twice with the same name returns the same data without re-allocating.

<br />

#### `SpriteSheet3d.apply(obj, loaded_texture)`

Attaches a loaded sprite sheet to an in-game object and sets its model to the built-in `spritesheet3d_geo`.

- `obj`: the `Object` to apply the sprite sheet to
- `loaded_texture`: a `SpriteSheet` returned by `SpriteSheet3d.load()`

```lua
SpriteSheet3d.apply(obj, tex)
```

Once applied, set `obj.oAnimState` to the zero-based tile index you want to display. The library automatically wraps the value by `tile_count`.

```lua
obj.oAnimState = 3  -- show tile index 3
```

<br />

#### `SpriteSheet3d.set_color(obj, r, g, b, a)`

Tints the sprite with an RGBA environment color. Values are clamped to 0–255.

- `obj`: an `Object` that has had `SpriteSheet3d.apply()` called on it
- `r`, `g`, `b`, `a`: color components (0–255)

```lua
-- Semi-transparent red tint
SpriteSheet3d.set_color(obj, 255, 64, 64, 200)
```

<br />

#### `SpriteSheet3d.get_tile_count(obj)`

Returns the total number of tiles for the sprite sheet currently applied to `obj`, or `0` if no sprite sheet has been applied.

```lua
local count = SpriteSheet3d.get_tile_count(obj)
```

Useful for ping-pong or looping logic that needs to know the frame range:

```lua
local count = SpriteSheet3d.get_tile_count(obj)
local cycle = (count - 1) * 2
local pos = obj.oTimer % cycle
obj.oAnimState = pos < count and pos or cycle - pos
```

<br />

---

<br />

## Animation

The only thing you need to drive an animation is `obj.oAnimState`. Set it to the zero-based tile index each frame in your behavior loop — the library handles the rest.

**Linear** — play through frames at a fixed rate:

```lua
local frames_per_tile = 2
obj.oAnimState = obj.oTimer // frames_per_tile
```

**Ping-pong** — play forward then backward:

```lua
local count = SpriteSheet3d.get_tile_count(obj)
local cycle = (count - 1) * 2
local pos = obj.oTimer % cycle
obj.oAnimState = pos < count and pos or cycle - pos
```

**Random** — jump to a new tile every N frames:

```lua
local change_every = 10
if obj.oTimer % change_every == 0 then
    obj.oAnimState = math.random(0, SpriteSheet3d.get_tile_count(obj) - 1)
end
```

**Billboarding** — to make the quad always face the camera, call this after spawning:

```lua
obj_set_billboard(obj)
```

<br />

---

<br />

## Example Mod

An example mod is located [here](example-mod), if you wish to see it running. It spawns three objects near Mario, each demonstrating a different animation style (linear, ping-pong, and random) with optional color tinting.
