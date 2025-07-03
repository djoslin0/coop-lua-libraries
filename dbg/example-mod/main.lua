-- name: Dbg Library Example
-- description: Displays every nearby object's behavior name

-- include the Dbg library under the 'Dbg' local variable
local Dbg = require('dbg')

-----------------------------------------------------------
-- draw a line between mario's origin and his direction, --
-- and another line between his origin and his velocity  --
-----------------------------------------------------------

function line_update()
    local m = gMarioStates[0]
    local mPos = {
        x = m.pos.x,
        y = m.pos.y,
        z = m.pos.z
    }

    -- draw direction line
    local mDir = {
        x = sins(m.faceAngle.y) * 1000,
        y = 0,
        z = coss(m.faceAngle.y) * 1000,
    }

    local endpoint = {
        x = mPos.x + mDir.x,
        y = mPos.y + mDir.y,
        z = mPos.z + mDir.z,
    }

    local color = { 1, 0, 0 }
    local line_thickness = 1
    local point_size = 1

    Dbg.line(mPos, endpoint, color, line_thickness)
    Dbg.point(endpoint, color, point_size)


    -- draw velocity line

    local mVel = {
        x = m.vel.x * 10,
        y = m.vel.y * 10,
        z = m.vel.z * 10,
    }

    endpoint = {
        x = mPos.x + mVel.x,
        y = mPos.y + mVel.y,
        z = mPos.z + mVel.z,
    }

    color = { 0, 0, 1 }

    Dbg.line(mPos, endpoint, color, line_thickness)
    Dbg.point(endpoint, color, point_size)

end

hook_event(HOOK_UPDATE, line_update)

--------------------------------------------------
-- put a text label and a point on every object --
--------------------------------------------------

function label_update()
    local m = gMarioStates[0]
    local mPos = { m.pos.x, m.pos.y, m.pos.z }

    -- iterate through every object list
    for i = 0, (NUM_OBJ_LISTS - 1) do
        local obj = obj_get_first(i)

        -- iterate through every object in the list
        while obj do
            -- grab the name and the position
            local bhvName = get_behavior_name_from_id(get_id_from_behavior(obj.behavior))
            local objPos = { obj.oPosX, obj.oPosY,obj.oPosZ }

            -- find the distance to mario
            local dx, dy, dz =
                (objPos[1] - mPos[1]),
                (objPos[2] - mPos[2]),
                (objPos[3] - mPos[3])
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

            -- calculate the alpha of the color based on distance
            local alpha = 1 - math.clamp((dist * 0.01) - 10, 0, 1)
            alpha = alpha * alpha

            -- if its close enough, display a point and text at the object location
            if alpha > 0.05 then
                local color = {1, 1, 1, alpha}
                Dbg.point(objPos, color)
                Dbg.text(bhvName, objPos, color, 1)
            end

            obj = obj_get_next(obj)
        end
    end
end

hook_event(HOOK_UPDATE, label_update)
