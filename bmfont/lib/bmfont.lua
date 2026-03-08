--------------------
-- BmFont Library --
-- v1.2           --
--------------------

---------------------------------------------------------------------
--
--    A lightweight bitmap font rendering library for coop
--    with support for BMFont .fnt files, sprite sheets,
--    kerning, and animations.
--
--    Use the following functions at load time:
--       BmFont.load_fnt(path, base_scale?)                  to load .fnt definitions
--       BmFont.load_sheet(sheet_string, w, h, base_scale?)  to load monospaced sprite sheets
--
--    Use the following functions in `HOOK_ON_HUD_RENDER`
--       BmFont.print(font, message, x, y, scale, anim_fn)
--       BmFont.print_left_aligned(...)         for left-aligned text
--       BmFont.print_right_aligned(...)        for right-aligned text
--       BmFont.print_center_aligned(...)       for center-aligned text
--
--    It also acts as a drop-in replacement for the existing fonts,
--    so these fonts will also work with the following built-in functions
--       djui_hud_set_font(YOUR_CUSTOM_FONT_HERE)
--       djui_hud_measure_text(text)
--       djui_hud_print_text(text, x, y, scale)
--       djui_hud_print_text_interpolated(message, prevX, prevY, prevScale, x, y, scale)
--
---------------------------------------------------------------------

local BmFont = {}

local BmFontPrivate = require('bmfont-private')
local _process_text = BmFontPrivate._process_text

-------------------------------------------------------------------
-- module-level state for BmFont.print

local _print_font          = nil
local _print_anim_fn       = nil
local _print_prev_color    = nil
local _print_prev_rotation = nil
local _print_length        = 0

---@class TextAnimOutput
local _anim_offset   = { x = 0, y = 0 }
local _anim_color    = { r = 255, g = 255, b = 255, a = 255 }
local _anim_scale    = { x = 1, y = 1 }
local _anim_rotation = { rotation = 0, pivot_x = 0, pivot_y = 0 }
local _text_anim_output = {
    offset   = _anim_offset,
    color    = _anim_color,
    scale    = _anim_scale,
    rotation = _anim_rotation,
}

local function _print_glyph_no_anim(ch, ox, s, i, l, sx, sy)
    local ar = ch.height / ch.width
    djui_hud_render_texture_tile(
        _print_font.texture,
        sx + ox + ch.xoffset * s,
        sy +      ch.yoffset * s,
        s * ar, s,
        ch.x, ch.y, ch.width, ch.height
    )
end

local function _print_glyph_anim(ch, ox, s, index, _len, sx, sy)
    local pc = _print_prev_color
    local pr = _print_prev_rotation
    _anim_offset.x, _anim_offset.y = 0, 0
    _anim_scale.x,  _anim_scale.y  = 1, 1
    _anim_color.r, _anim_color.g, _anim_color.b, _anim_color.a = pc.r, pc.g, pc.b, pc.a
    _anim_rotation.rotation = pr.rotation
    _anim_rotation.pivot_x  = pr.pivotX
    _anim_rotation.pivot_y  = pr.pivotY

    _print_anim_fn(index, _print_length, _text_anim_output)

    djui_hud_set_color(_anim_color.r, _anim_color.g, _anim_color.b, _anim_color.a)
    djui_hud_set_rotation(_anim_rotation.rotation, _anim_rotation.pivot_x, _anim_rotation.pivot_y)

    local ar = ch.height / ch.width
    djui_hud_render_texture_tile(
        _print_font.texture,
        sx + ox + ch.xoffset * s + _anim_offset.x,
        sy +      ch.yoffset * s + _anim_offset.y,
        s * ar * _anim_scale.x, s * _anim_scale.y,
        ch.x, ch.y, ch.width, ch.height
    )
end

-------------------------------------------------------------------

--- @alias TextAnimCallback fun(index: integer, length: integer, output: TextAnimOutput)

--- @param font CustomFont
--- @param message string
--- @param x number
--- @param y number
--- @param scale number
--- @param anim_function TextAnimCallback?
function BmFont.print(font, message, x, y, scale, anim_function)
    if font == nil then return end
    if type(message) ~= "string" then return end

    local prev_color    = djui_hud_get_color()
    local prev_rotation = djui_hud_get_rotation()
    local prev_font     = djui_hud_get_font()

    djui_hud_set_font(font)
    _print_font = font

    local scaled = font.base_scale * scale
    if anim_function then
        _print_anim_fn       = anim_function
        _print_prev_color    = prev_color
        _print_prev_rotation = prev_rotation
        _print_length        = utf8.len(message)
        _process_text(message, scaled, _print_glyph_anim, x, y)
        _print_anim_fn       = nil
        _print_prev_color    = nil
        _print_prev_rotation = nil
        _print_length        = 0
    else
        _process_text(message, scaled, _print_glyph_no_anim, x, y)
    end

    djui_hud_set_color(prev_color.r, prev_color.g, prev_color.b, prev_color.a)
    djui_hud_set_rotation(prev_rotation.rotation, prev_rotation.pivotX, prev_rotation.pivotY)
    djui_hud_set_font(prev_font)
    _print_font = nil
end

--- @param font CustomFont
--- @param message string
--- @param x number
--- @param y number
--- @param scale number
--- @param anim_function TextAnimCallback?
function BmFont.print_left_aligned(font, message, x, y, scale, anim_function)
    if not font then return end
    BmFont.print(font, message, x, y, scale, anim_function)
end

--- @param font CustomFont
--- @param message string
--- @param x number
--- @param y number
--- @param scale number
--- @param anim_function TextAnimCallback?
function BmFont.print_right_aligned(font, message, x, y, scale, anim_function)
    if not font then return end
    local prev_font = djui_hud_get_font()
    djui_hud_set_font(font)
    x = x - djui_hud_measure_text(message) * scale
    djui_hud_set_font(prev_font)

    BmFont.print(font, message, x, y, scale, anim_function)
end

--- @param font CustomFont
--- @param message string
--- @param x number
--- @param y number
--- @param scale number
--- @param anim_function TextAnimCallback?
function BmFont.print_center_aligned(font, message, x, y, scale, anim_function)
    if not font then return end
    local prev_font = djui_hud_get_font()
    djui_hud_set_font(font)
    x = x - djui_hud_measure_text(message) * scale * 0.5
    djui_hud_set_font(prev_font)

    BmFont.print(font, message, x, y, scale, anim_function)
end

-------------------------------------------------------------------

--- @param font CustomFont
local function _add_missing_alphas(font)
    local l_alphabet = 'abcdefghijklmnopqrstuvwxyz'
    local u_alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

    for i = 1, #l_alphabet do
        local lower = l_alphabet:sub(i,i)
        local upper = u_alphabet:sub(i,i)
        local lc = utf8.codepoint(lower)
        local uc = utf8.codepoint(upper)

        local lch = font.chars[lc]
        local uch = font.chars[uc]

        -- if lowercase missing but uppercase exists, point lower to upper
        if not lch and uch then
            font.chars[lc] = uch

        -- if uppercase missing but lowercase exists, point upper to lower
        elseif not uch and lch then
            font.chars[uc] = lch
        end
    end
end

--- @param font_filename string
--- @param tile_width integer
--- @param tile_height integer
--- @param base_scale number?
function BmFont.load_sheet(font_filename, tile_width, tile_height, base_scale)
    if base_scale == nil then base_scale = 1 end
    if base_scale <= 0 then base_scale = 1 end
    ---@class CustomFont
    local font = {
        info       = {},
        common     = {},
        pages      = {},     -- page id -> filename
        chars      = {},     -- char id -> char info table
        kernings   = {},     -- list of kerning entries
        kerningMap = {},     -- quick lookup: kerningMap[first][second] = amount
        charCount  = 0,
        texture    = get_texture_info(font_filename),
        right_to_left = false,
        base_scale = base_scale,
    }

    local fnt_string = require('/fonts/' .. font_filename)

    local x, y = 0, 0
    for _, code in utf8.codes(fnt_string) do
        font.chars[code] = {
            x = x,
            y = y,
            width = tile_width,
            height = tile_height,
            xoffset = 0,
            yoffset = 0,
            xadvance = tile_width,
        }
        x = x + tile_width
        if x >= font.texture.width then
            x = 0
            y = y + tile_height
        end
        font.charCount = font.charCount + 1
    end

    _add_missing_alphas(font)

    return font
end

--- @param font_filename string
--- @param base_scale number?
function BmFont.load_fnt(font_filename, base_scale)
    if base_scale == nil then base_scale = 1 end
    if base_scale <= 0 then base_scale = 1 end
    ---@class CustomFont
    local font = {
        info       = {},
        common     = {},
        pages      = {},     -- page id -> filename
        chars      = {},     -- char id -> char info table
        kernings   = {},     -- list of kerning entries
        kerningMap = {},     -- quick lookup: kerningMap[first][second] = amount
        texture    = get_texture_info(font_filename),
        right_to_left = false,
        base_scale = base_scale
    }

    local fnt_string = require('/fonts/' .. font_filename)

    for line in fnt_string:gmatch("[^\n]+") do
        line = line:gsub("\r$", "")
        local tag, rest = line:match("^(%w+)%s+(.*)")
        if tag then
            local attrs = {}
            -- first grab all quoted values
            for k, v in rest:gmatch('(%w+)="(.-)"') do
                attrs[k] = v
            end
            for k, v in rest:gmatch("(%w+)='(.-)'") do
                attrs[k] = v
            end

            -- then grab all unquoted values
            for k, v in rest:gmatch("(%w+)=([^%s]+)") do
                if attrs[k] == nil then
                    local n = tonumber(v)
                    attrs[k] = (n ~= nil) and n or v
                end
            end

            if tag == "info" then
                font.info = attrs

            elseif tag == "common" then
                font.common = attrs

            elseif tag == "page" then
                -- attrs.id, attrs.file
                font.pages[attrs.id] = attrs.file

            elseif tag == "chars" then
                -- can capture count if needed: attrs.count
                font.charCount = attrs.count

            elseif tag == "char" then
                font.chars[attrs.id] = attrs

            elseif tag == "kernings" then
                -- attrs.count
                font.kerningCount = attrs.count

            elseif tag == "kerning" then
                -- attrs.first, attrs.second, attrs.amount
                table.insert(font.kernings, attrs)
                font.kerningMap[attrs.first] = font.kerningMap[attrs.first] or {}
                font.kerningMap[attrs.first][attrs.second] = attrs.amount
            end
        end
    end

    _add_missing_alphas(font)

    return font
end

return BmFont
