local MK = {}
local downs = {lctrl = false, rctrl = false, lshift = false, rshift = false, lalt = false, ralt = false}

local function isIn(key)
    for i in pairs(downs) do if i == key then return true end end
end

function MK.keypressed(key)
    if isIn(key) then downs[key] = true end
end

function MK.keyreleased(key)
    if isIn(key) then downs[key] = false end
end

function MK.isDown(key)
    return downs[key]
end

return MK