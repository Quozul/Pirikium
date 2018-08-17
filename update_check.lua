local request = require "luajit-request"
require "clib/utility"

function versionWeight(numVer)
    local preTypes = {"dev", "alpha", "beta", "rc", "release"}

    if not numVer:match("-") then numVer = numVer .. "-release" end -- add missing pre-release type

    print(("\nVersion: %s"):format(numVer))

    numVer = numVer:split("-") -- {version number, pre-release number}
    preVer = numVer[2]:split(".") -- {pre-release type, pre-release version}
    numVer = numVer[1]:split(".") -- {major, minor, patch}

    for index, value in pairs(numVer) do if tonumber(value or 0) > 255 then error("Maximum version value reached!") end end
    if tonumber(preVer[2] or 0) > 255 then error("Maximum version value reached!") end

    -- string.format("%02d", Values["test"].Int)
    local major, minor, patch = string.format("%03d", numVer[1]), string.format("%03d", numVer[2] or 0), string.format("%03d", numVer[3] or 0)

    print( ("Major: %s.  Minor: %s.  Patch: %s."):format(major, minor, patch) )

    local preMajor, preMinor = table.find(preTypes, preVer[1]) or 4, string.format("%03d", preVer[2] or 0)
    print( ("Release type: %s, worth %s.  Minor: %s.\n"):format(preVer[1], preMajor, preMinor) )

    return tonumber(
        "0x" ..
        string.format("%02x", major) ..
        string.format("%02x", minor) ..
        string.format("%02x", patch)
    ), tonumber(
        "0x" ..
        string.format("%02x", major) ..
        string.format("%02x", minor) ..
        string.format("%02x", patch) .. "." ..
        string.format("%02x", preMajor) ..
        string.format("%02x", preMinor)
    )
end

local response = request.send("https://github.com/Quozul/Pirikium/raw/master/version")
if response then
    love.thread.getChannel( "update_channel" ):push(
        {
            online_ver = versionWeight(response.body),
            current_ver = versionWeight( love.filesystem.read("version") ),
        }
)
end