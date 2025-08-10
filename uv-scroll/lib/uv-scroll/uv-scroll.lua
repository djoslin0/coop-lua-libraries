-----------------------
-- UV Scroll Library --
-----------------------

---------------------------------------------------------------------
--
--    A utility library for hooking functions to manipulate UV
--    coordinates of vertex data from specific graphics display lists.
--
--    Typical usage:
--       1. Call UvScroll.hook_scrolling_function(gfx_name, callback)
--          with the name of a display list and a function that modifies
--          UV coordinates.
--       2. The library parses the display list into vertex triangles.
--       3. Vertices that are connected via triangles are grouped into
--          "chunks" so that UV updates can be applied per connected set.
--       4. The original and current UVs for each chunk are stored so
--          the callback can adjust them over time.
--
--    The callback signature:
--       callback(input_vtx, original_uv, current_uv)
--         • input_vtx   → The vertex object being updated
--         • original_uv → {u, v} table with the vertex's starting UV
--         • current_uv  → {u, v} table with the vertex's current UV
--
--    This allows for animated scrolling effects, wavy textures, etc.
--
---------------------------------------------------------------------

---@class HookedUvScroll
---@field gfx_name string
---@field processed table
---@field callback fun(input_vtx: Vtx, original_uv: integer[], current_uv: integer[])

---@class UvScroll
local UvScroll = {
    hooked = {}  ---@type HookedUvScroll[]
}

local SHORT_MAX = 32767
local SHORT_MIN = -32768

---------------------------------------------------------------------
-- Parse a display list name into a flat list of triangles
-- Each triangle is a table of 3 vertex objects.
---------------------------------------------------------------------
local function parse_gfx_name_to_triangles(name)
    local triangles = {}

    local gfx = gfx_get_from_name(name)
    if gfx == nil then return triangles end

    local vtx_count = 0
    local vtx = nil

    while gfx ~= nil do
        local op = gfx_get_op(gfx)

        if op == G_VTX then
            vtx_count = gfx_get_vertex_count(gfx)
            vtx = gfx_get_vertex_buffer(gfx)

        elseif op == G_TRI1 then
            -- Extract v0, v1, v2 indices from the packed word
            local word = gfx.w0
            local v0   = ((word >> 16) & 0xFF) // 2
            local v1   = ((word >>  8) & 0xFF) // 2
            local v2   = ((word >>  0) & 0xFF) // 2

            if vtx ~= nil and v0 < vtx_count and v1 < vtx_count and v2 < vtx_count then
                local vtx0 = vtx_get_vertex(vtx, v0)
                local vtx1 = vtx_get_vertex(vtx, v1)
                local vtx2 = vtx_get_vertex(vtx, v2)
                triangles[#triangles + 1] = { vtx0, vtx1, vtx2 }
            end

        elseif op == G_TRI2 then
            -- Extract v0, v1, v2 indices from the packed word
            for _, word in ipairs({gfx.w0, gfx.w1}) do
                local v0   = ((word >> 16) & 0xFF) // 2
                local v1   = ((word >>  8) & 0xFF) // 2
                local v2   = ((word >>  0) & 0xFF) // 2

                if vtx ~= nil and v0 < vtx_count and v1 < vtx_count and v2 < vtx_count then
                    local vtx0 = vtx_get_vertex(vtx, v0)
                    local vtx1 = vtx_get_vertex(vtx, v1)
                    local vtx2 = vtx_get_vertex(vtx, v2)
                    triangles[#triangles + 1] = { vtx0, vtx1, vtx2 }
                end
            end
        end

        gfx = gfx_get_next_command(gfx)
    end

    return triangles
end

---------------------------------------------------------------------
-- Group vertices into connected "chunks".
-- Any vertex sharing a triangle with another is considered connected.
---------------------------------------------------------------------
local function group_vertices_into_chunks(triangles)
    local chunks = {}
    local visited_vertices = {}

    -- Build adjacency: vertex -> all connected vertices
    local adjacency = {}
    for _, tri in ipairs(triangles) do
        for i = 1, 3 do
            local v1 = tri[i]
            adjacency[v1] = adjacency[v1] or {}
            for j = 1, 3 do
                if i ~= j then
                    local v2 = tri[j]
                    adjacency[v1][v2] = true
                end
            end
        end
    end

    -- Depth-first search to collect all connected vertices in one chunk
    local function dfs(v, chunk)
        visited_vertices[v] = true
        chunk[#chunk + 1] = v
        if adjacency[v] then
            for neighbor in pairs(adjacency[v]) do
                if not visited_vertices[neighbor] then
                    dfs(neighbor, chunk)
                end
            end
        end
    end

    -- Iterate over all vertices to build chunks
    for v in pairs(adjacency) do
        if not visited_vertices[v] then
            local chunk = {}
            dfs(v, chunk)
            chunks[#chunks + 1] = chunk
        end
    end

    return chunks
end

---------------------------------------------------------------------
-- Prepare chunks by storing both original and working UV copies.
-- This ensures we can reset or reapply scroll offsets easily.
---------------------------------------------------------------------
local function prepare_chunks_for_scroll(chunks)
    local prepped = {}
    for i = 1, #chunks do
        local uvs = {}
        local original_uvs = {}
        for j = 1, #chunks[i] do
            local vtx = chunks[i][j]
            uvs[j] = { vtx.tu or 0, vtx.tv or 0 }
            original_uvs[j] = { vtx.tu or 0, vtx.tv or 0 }
        end
        prepped[i] = {
            vertices = chunks[i],
            uvs = uvs,
            original_uvs = original_uvs,
        }
    end
    return prepped
end

---------------------------------------------------------------------
-- Hook a UV-scrolling callback for a specific display list name.
--
-- If a hook already exists for this name, the callback is updated.
-- Returns true on success, false if the display list or chunks could
-- not be found.
---------------------------------------------------------------------
---@param gfx_name string
---@param callback fun(input_vtx: Vtx, original_uv: integer[], current_uv: integer[])
---@return boolean
function UvScroll.hook_scrolling_function(gfx_name, callback)
    if UvScroll.hooked[gfx_name] then
        -- Already hooked, update callback only
        UvScroll.hooked[gfx_name].callback = callback
        return true
    end

    local triangles = parse_gfx_name_to_triangles(gfx_name)
    if #triangles == 0 then return false end

    local chunks = group_vertices_into_chunks(triangles)
    if #chunks == 0 then return false end

    local processed = prepare_chunks_for_scroll(chunks)

    -- Store the hooked data
    UvScroll.hooked[gfx_name] = {
        gfx_name = gfx_name,
        processed = processed,
        callback = callback,
    }

    return true
end

hook_event(HOOK_UPDATE, function()
    for _, hooked in pairs(UvScroll.hooked) do
        for _, prep in ipairs(hooked.processed) do
            local vertices = prep.vertices
            local uvs = prep.uvs
            local original_uvs = prep.original_uvs

            local min_uv = { SHORT_MAX * 100, SHORT_MAX * 100 }
            local max_uv = { SHORT_MIN * 100, SHORT_MIN * 100 }

            for i = 1, #vertices do
                local vtx = vertices[i]
                hooked.callback(vtx, original_uvs[i], uvs[i])

                for j = 1, 2 do
                    min_uv[j] = math.min(min_uv[j], uvs[i][j])
                    max_uv[j] = math.max(max_uv[j], uvs[i][j])
                end
            end

            local divisor = SHORT_MAX // 4
            local adjust_uv = {
                divisor * ((min_uv[1] + max_uv[1]) // (2 * divisor)),
                divisor * ((min_uv[2] + max_uv[2]) // (2 * divisor))
            }

            for i = 1, #vertices do
                local vtx = vertices[i]
                uvs[i][1] = uvs[i][1] - adjust_uv[1]
                uvs[i][2] = uvs[i][2] - adjust_uv[2]
                vtx.tu = uvs[i][1]
                vtx.tv = uvs[i][2]
            end
        end
    end
end)


return UvScroll
