local W = {}

function W.packBody(body)
    local t = {}

    t[1][1], t[1][2] = body:getPosition()
    t[2][1], t[2][2] = body:getLinearVelocity()
    t[3] = body:getLinearVelocity()
    t[4] = body:getLinearVelocity()

    return t
end

function W.unpackBody(t)
    body:setPosition( unpack(t[1]) )
    body:setLinearVelocity( unpack(t[2]) )
    body:setAngle( t[3] )
    body:setAngularVelocity( t[4] )
end

return W
