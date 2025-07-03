--------------------
-- BmFont Library --
--------------------

---------------------------------------------------------------------
--
--    A lightweight bitmap font rendering library for coop
--    with with support for BMFont .fnt files, sprite sheets,
--    kerning, and animations.
--
--    Use the following functions at load time:
--       BmFont.load_fnt(path)                  to load .fnt definitions
--       BmFont.load_sheet(sheet_string, w, h)  to load monospaced sprite sheets
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

    local prev_color = djui_hud_get_color()
    local prev_rotation = djui_hud_get_rotation()
    local prev_font = override_font

    override_font = font

    ---@class TextAnimOutput
    local text_anim_output = {
        offset   = { x = 0, y = 0 },
        color    = { r = prev_color.r, g = prev_color.g, b = prev_color.b, a = prev_color.a },
        scale    = { x = 1, y = 1 },
        rotation = { rotation = prev_rotation.rotation, pivot_x = prev_rotation.pivotX, pivot_y = prev_rotation.pivotY }
    }
    local aoffset = text_anim_output.offset
    local ascale = text_anim_output.scale
    local acolor = text_anim_output.color
    local arotation = text_anim_output.rotation

    BmFontPrivate._process_text(message, scale,
        function(ch, ox, s, index, length)
            if anim_function then
                -- reset anim
                aoffset.x, aoffset.y = 0, 0
                ascale.x, ascale.y = 1, 1
                acolor.r, acolor.g, acolor.b, acolor.a = prev_color.r, prev_color.g, prev_color.b, prev_color.a
                arotation.rotation, arotation.pivot_x, arotation.pivot_y = prev_rotation.rotation, prev_rotation.pivotX, prev_rotation.pivotY

                anim_function(index, length, text_anim_output)

                djui_hud_set_color(acolor.r, acolor.g, acolor.b, acolor.a)
                djui_hud_set_rotation(arotation.rotation, arotation.pivot_x, arotation.pivot_y)
            end
            local ar = ch.height / ch.width
            djui_hud_render_texture_tile(
                font.texture,
                x + ox + ch.xoffset * s + aoffset.x,
                y      + ch.yoffset * s + aoffset.y,
                s * ar * ascale.x, s * ascale.y,
                ch.x, ch.y, ch.width, ch.height
            )
        end
    )

    djui_hud_set_color(prev_color.r, prev_color.g, prev_color.b, prev_color.a)
    djui_hud_set_rotation(prev_rotation.rotation, prev_rotation.pivotX, prev_rotation.pivotY)
    override_font = prev_font
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
    local prev_override_font = override_font
    override_font = font
    x = x - djui_hud_measure_text(message) * scale
    override_font = prev_override_font

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
    local prev_override_font = override_font
    override_font = font
    x = x - djui_hud_measure_text(message) * scale * 0.5
    override_font = prev_override_font

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
function BmFont.load_sheet(font_filename, tile_width, tile_height)
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
    }

    local fnt_string = require(font_filename)

    local x, y = 0, 0
    for _, code in utf8.codes(fnt_string) do
        ---char id=34 x=487 y=474 width=22 height=18 xoffset=11 yoffset=15 xadvance=20 page=0 chnl=15
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
function BmFont.load_fnt(font_filename)
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
    }

    local fnt_string = require(font_filename)

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
