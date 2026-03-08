---------------------------
-- SpriteSheet3d Library --
-- v1.0                  --
---------------------------

---------------------------------------------------------------------
--
--    A library for rendering animated sprite sheets in 3D space.
--    Given any sprite sheet texture and a tile layout, it creates
--    per-tile display lists with correct UVs, and swaps them at
--    runtime via a geo ASM callback driven by oAnimState.
--
--    Usage:
--       local tex = SpriteSheet3d.load(name, cols, rows)
--       SpriteSheet3d.apply(obj, tex)
--       obj.oAnimState = frame
--
--    Per-object tinting:
--       SpriteSheet3d.set_color(obj, r, g, b, a)
--
--    Query helpers:
--       SpriteSheet3d.get_tile_count(obj) -> integer
--
--    Tile display lists are shared across objects that use the
--    same texture; only a small per-object color DL is allocated
--    and freed automatically on object unload.
--
---------------------------------------------------------------------

local SpriteSheet3d = {}

--- @class SpriteSheet
--- @field tiles Gfx[]
--- @field tile_count integer

--------------
-- Localize --
--------------

local gfx_get_from_name   = gfx_get_from_name
local gfx_get_length      = gfx_get_length
local gfx_create          = gfx_create
local gfx_copy            = gfx_copy
local gfx_get_command     = gfx_get_command
local gfx_set_command     = gfx_set_command
local gfx_delete          = gfx_delete
local vtx_get_from_name   = vtx_get_from_name
local vtx_get_count       = vtx_get_count
local vtx_create          = vtx_create
local vtx_copy            = vtx_copy
local vtx_get_vertex      = vtx_get_vertex
local get_texture_info    = get_texture_info
local geo_get_current_object = geo_get_current_object
local cast_graph_node     = cast_graph_node

--------------
-- Internal --
--------------

-- Cache of texture_name -> duplicated Gfx display list
local sTextureDisplayLists = {}

-- Cache of object pointer string -> Gfx display list to use
local sObjectDisplayLists = {}

-- Cached display list graph node (from the GEO_DISPLAY_LIST after the GEO_ASM)
local sDisplayListColorNode = nil
local sDisplayListTileNode = nil

--- @param obj Object
--- @param loaded_texture SpriteSheet|nil
local function update_obj_texture(obj, loaded_texture)
    if not obj or not loaded_texture then return end
    local display_lists = sObjectDisplayLists[obj._pointer]
    if not display_lists then return end
    display_lists.tiles = loaded_texture.tiles
    display_lists.tile_count = loaded_texture.tile_count
end

--- @param v number|integer
--- @return integer
local function clamp_u8(v)
    v = v // 1
    if v < 0 then
        return 0
    elseif v > 255 then
        return 255
    end
    return v
end

---------
-- API --
---------

SpriteSheet3d.model = smlua_model_util_get_id("spritesheet3d_geo")

--- @param texture_name string -- name of the texture registered via DynOS/TEX_*
--- @param tiles_x integer|nil -- columns in the sprite sheet (default 1)
--- @param tiles_y integer|nil -- rows in the sprite sheet (default 1)
--- @return SpriteSheet|nil
function SpriteSheet3d.load(texture_name, tiles_x, tiles_y)
    if not texture_name then return end

    -- Default to 1x1 tiles if not specified
    tiles_x = tiles_x or 1
    tiles_y = tiles_y or 1

    -- load the texture
    local texture_info = get_texture_info(texture_name)
    if not texture_info then return end

    -- If the texture was already loaded, return the existing display lists for this texture
    local cached = sTextureDisplayLists[texture_name]
    if cached then
        return cached
    end

    local allocate_vertices = tiles_x > 1 or tiles_y > 1

    -- load the tile templates
    local template_gfx = gfx_get_from_name("spritesheet3d_dl")
    local template_gfx_length = gfx_get_length(template_gfx)
    local template_vtx = vtx_get_from_name("spritesheet3d_vtx")
    local template_vtx_count = vtx_get_count(template_vtx)

    local tile_dls = { }
    for tile_y = 1, tiles_y do
        for tile_x = 1, tiles_x do
            -- create gfx and copy from template
            local gfx_name = "spritesheet3d_dl_" .. texture_name .. "_" .. tile_x .. "_" .. tile_y
            local gfx = gfx_create(gfx_name, template_gfx_length)
            gfx_copy(gfx, template_gfx, template_gfx_length)

            -- Swap the texture image command (index 6: gsDPSetTextureImage)
            local cmd_texture = gfx_get_command(gfx, 6)
            gfx_set_command(cmd_texture, "gsDPSetTextureImage(G_IM_FMT_RGBA, G_IM_SIZ_16b_LOAD_BLOCK, 1, %t)", texture_info.texture)

            if allocate_vertices then
                -- Create a new vertex buffer for this tile and copy from the template
                local vtx_name = "spritesheet3d_vtx_" .. texture_name .. "_" .. tile_x .. "_" .. tile_y
                local vtx = vtx_create(vtx_name, template_vtx_count)
                vtx_copy(vtx, template_vtx, template_vtx_count)

                -- Calculate and set the UVs
                local vert0 = vtx_get_vertex(vtx, 0)
                local vert1 = vtx_get_vertex(vtx, 1)
                local vert2 = vtx_get_vertex(vtx, 2)
                local vert3 = vtx_get_vertex(vtx, 3)

                local u_lo = ((tile_x - 1) / tiles_x) * 8192 - 15
                local v_lo = ((tile_y - 1) / tiles_y) * 8192 - 15
                local u_hi = ((tile_x - 0) / tiles_x) * 8192 - 15
                local v_hi = ((tile_y - 0) / tiles_y) * 8192 - 15

                vert0.tu = u_lo ; vert0.tv = v_hi
                vert1.tu = u_lo ; vert1.tv = v_lo
                vert2.tu = u_hi ; vert2.tv = v_lo
                vert3.tu = u_hi ; vert3.tv = v_hi

                -- Swap the vertex command (index 11: gsSPVertex)
                local cmd_vertex = gfx_get_command(gfx, 11)
                gfx_set_command(cmd_vertex, "gsSPVertex(%v, %i, 0)", vtx, template_vtx_count)
            end

            table.insert(tile_dls, gfx)
        end
    end

    -- Cache and return the display lists for this texture
    local tile_count = #tile_dls
    local loaded = { tiles = tile_dls, tile_count = tile_count }
    sTextureDisplayLists[texture_name] = loaded
    return loaded
end

--- @param obj Object -- the object to attach the sprite sheet to
--- @param loaded_texture SpriteSheet|nil -- value returned by SpriteSheet3d.load()
function SpriteSheet3d.apply(obj, loaded_texture)
    if not obj or not loaded_texture then return end
    local obj_id = obj._pointer

    -- make sure its using the correct model
    if obj_has_model_extended(obj, SpriteSheet3d.model) == 0 then
        obj_set_model_extended(obj, SpriteSheet3d.model)
    end

    -- if already applied, just swap the texture
    if sObjectDisplayLists[obj_id] then
        update_obj_texture(obj, loaded_texture)
        return
    end

    -- create the per-object color display list
    local template_color_gfx = gfx_get_from_name("spritesheet3d_color_dl")
    local template_color_gfx_length = gfx_get_length(template_color_gfx)
    local color_gfx = gfx_create("spritesheet3d_color_dl_" .. obj_id, template_color_gfx_length)
    gfx_copy(color_gfx, template_color_gfx, template_color_gfx_length)

    sObjectDisplayLists[obj_id] = {
        color = color_gfx,
        tiles = loaded_texture.tiles,
        tile_count = loaded_texture.tile_count,
        env_color = { r = 255, g = 255, b = 255, a = 255 }
    }
end

--- @param obj Object
--- @return integer
function SpriteSheet3d.get_tile_count(obj)
    local obj_id = obj._pointer
    local display_lists = sObjectDisplayLists[obj_id]
    if not display_lists then return 0 end
    return display_lists.tile_count
end

--- @param obj Object
--- @param r number -- red   (0-255, clamped)
--- @param g number -- green (0-255, clamped)
--- @param b number -- blue  (0-255, clamped)
--- @param a number -- alpha (0-255, clamped)
function SpriteSheet3d.set_color(obj, r, g, b, a)
    local display_lists = sObjectDisplayLists[obj._pointer]
    if not display_lists then return end

    -- Clamp to 0-255 integer range
    r, g, b, a = clamp_u8(r), clamp_u8(g), clamp_u8(b), clamp_u8(a)

    -- Skip if the color hasn't changed
    local env = display_lists.env_color
    if env.r == r and env.g == g and env.b == b and env.a == a then return end

    -- Update the gsDPSetEnvColor command (index 0 in spritesheet3d_color_dl)
    local cmd = gfx_get_command(display_lists.color, 0)
    gfx_set_command(cmd, "gsDPSetEnvColor(%i, %i, %i, %i)", r, g, b, a)

    -- Update cached color
    env.r, env.g, env.b, env.a = r, g, b, a
end

-----------
-- Hooks --
-----------

--- @param node GraphNode -- the GEO_ASM node in spritesheet3d_geo
--- @param matStackIndex integer
function geo_spritesheet3d_update(node, matStackIndex)
    local obj = geo_get_current_object()
    if not obj then return end

    -- Cache the display list nodes on the first call
    if not sDisplayListColorNode or not sDisplayListTileNode then
        local next_node = node.next
        sDisplayListColorNode = cast_graph_node(next_node)
        sDisplayListTileNode  = cast_graph_node(next_node.next)
    end

    -- Get the display lists for this object
    local dl = sObjectDisplayLists[obj._pointer]
    if not dl then return end

    -- Select the display list based on the object's animation state
    sDisplayListColorNode.displayList = dl.color
    sDisplayListTileNode.displayList  = dl.tiles[(obj.oAnimState % dl.tile_count) + 1]
end

hook_event(HOOK_ON_OBJECT_UNLOAD, function(obj)
    local obj_id = obj._pointer
    local display_lists = sObjectDisplayLists[obj_id]
    if not display_lists then return end

    -- Delete the per-object color display list
    if display_lists.color then
        gfx_delete(display_lists.color)
    end

    -- Tile display lists are intentionally kept alive in sTextureDisplayLists
    -- since they can be reused by future objects with the same texture

    sObjectDisplayLists[obj_id] = nil
end)

-----------------------

return SpriteSheet3d