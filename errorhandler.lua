-- based on 0x25a0's (https://love2d.org/forums/viewtopic.php?t=83881)

function love.errhand(error_message)
    local app_name = "Pirikium"
    local version = love.filesystem.read("version"):gsub("\n", "")
    local github_url = "https://www.github.com/Quozul/Pirikium" -- no trailing slash
    local email = "quozul@outlook.com"
    local edition = love.system.getOS()

    local dialog_message = [[%s crashed with the following error message:

%s

Would you like to report this crash so that it can be fixed?]]
    
    local titles = {"Oh no!", "The game has ran into an error!", "Bad news!", "An error occured...", "Something went wrong!", "What have you done?"}
    local title = titles[love.math.random(#titles)]
    local full_error = debug.traceback(error_message or "")
    local message = string.format(dialog_message, app_name, full_error)
    local buttons = {"No", "Yes, on GitHub", "Yes, by email", "Yes, copy it"}

    if not love.filesystem.getInfo("logs") then love.filesystem.createDirectory("logs") end
    love.filesystem.write(
        string.format("logs/crash_%s.txt", removeDecimal(love.timer.getTime())),
        string.format(
            "%s Here are the logs:\n---\n%s\n---\n[CRASH %.1f] Crash with the following error:\n\n---\n%s\n\n---\nVersion: %s\nSystem: %s\n",
            title, console.getLog(), getFormattedTime()[2], full_error, version, edition
        )
    )

    local pressedbutton = love.window.showMessageBox(title, message, buttons)

    local function url_encode(text)
        -- This is not complete. Depending on your issue text, you might need to
        -- expand it!
        text = string.gsub(text, "\n", "%%0A")
        text = string.gsub(text, " ", "%%20")
        text = string.gsub(text, "#", "%%23")
        return text
    end

    local issuebody = [[%s crashed with the following error message:

%s

[If you can, describe what you've been doing when the error occurred]

---
Version: %s
System: %s]]

    if pressedbutton == 2 then
        -- Surround traceback in ``` to get a Markdown code block
        full_error = table.concat({"```",full_error,"```"}, "\n")
        issuebody = string.format(issuebody, app_name, full_error, version, edition)
        issuebody = url_encode(issuebody)

        local subject = string.format("Crash in %s %s", app_name, version)
        local url = string.format("%s/issues/new?title=%s&body=%s", github_url, subject, issuebody)
        love.system.openURL(url)
    elseif pressedbutton == 3 then
        issuebody = string.format(issuebody, app_name, full_error, version, edition)
        issuebody = url_encode(issuebody)

        local subject = string.format("Crash in %s %s", app_name, version)
        local url = string.format("mailto:%s?subject=%s&body=%s", email, subject, issuebody)
        love.system.openURL(url)
    elseif pressedbutton == 4 then
        love.system.setClipboardText(full_error .. ("\n\nVersion: %s\nSystem: %s"):format(version, edition))
    end
end
