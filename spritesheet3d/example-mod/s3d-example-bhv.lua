---------------------------------------------------------------------
-- Example behavior for SpriteSheet3d objects.
--
-- The key idea: set obj.oAnimState to the tile index you want to
-- display. The library's geo callback picks it up automatically.
--
-- Three animation styles are demonstrated here, selected by
-- obj.oBehParams (set when the object is spawned in main.lua).
---------------------------------------------------------------------

local SpriteSheet3d = require('/lib/spritesheet3d')

--- Called once when the object is created.
local function bhv_init(obj)
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj.header.gfx.skipInViewCheck = true

    -- Billboarding makes the quad always face the camera.
    -- Only the explosion demo uses it; the others stay world-aligned
    -- so you can see that they are real 3D quads.
    if obj.oBehParams == 0 then
        obj_set_billboard(obj)
    end
end

--- Called every frame. Advances the animation by setting oAnimState.
local function bhv_loop(obj)

    -------------------------------------------------------
    -- Style 0: Linear playback
    -- Advance one tile every N frames. Once it reaches
    -- the last tile it wraps around (the library mods by
    -- tile_count automatically).
    -------------------------------------------------------
    if obj.oBehParams == 0 then
        local frames_per_tile = 2
        obj.oAnimState = obj.oTimer // frames_per_tile

    -------------------------------------------------------
    -- Style 1: Ping-pong + color tinting
    -- Plays 0 -> last -> 0 -> last ... and tints the sprite
    -- with a cycling RGB color via set_color().
    -------------------------------------------------------
    elseif obj.oBehParams == 1 then
        local tile_count   = SpriteSheet3d.get_tile_count(obj)
        local frame_index  = obj.oTimer  -- 1 frame per tile

        -- Ping-pong: map frame_index into 0..count-1..0..
        local cycle_length = (tile_count - 1) * 2
        local pos = frame_index % cycle_length
        if pos >= tile_count then
            pos = cycle_length - pos
        end
        obj.oAnimState = pos

    -------------------------------------------------------
    -- Style 2: Random frame
    -- Every N frames, jump to a random tile and tint the sprite
    -------------------------------------------------------
    elseif obj.oBehParams == 2 then
        local change_every = 10  -- frames between switches
        if obj.oTimer % change_every == 0 then
            local tile_count = SpriteSheet3d.get_tile_count(obj)
            obj.oAnimState = math.random(0, tile_count - 1)

            -- Cycle through colors using sine waves
            local t = obj.oTimer * 0.2
            SpriteSheet3d.set_color(obj,
                math.sin(t * 1.0) * 127 + 128,  -- red
                math.sin(t * 1.1) * 127 + 128,  -- green
                math.sin(t * 1.2) * 127 + 128,  -- blue
                255)                            -- alpha
        end
    end
end

id_bhvS3dExample = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, false, bhv_init, bhv_loop)