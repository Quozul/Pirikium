local button = {}
button.__index = button
local anim = .5

tx, ty = 0, 0

width, height = love.window.getMode()

function NewButton(type, x, y, w, h, click, text, color, style, value)
    if style == nil then style = {} end

    local b = {}
    b.type = type
    b.x, b.y = x, y
    b.w, b.h = w, h
    b.click = click
    b.defaultText = text or ""
    b.text = b.defaultText
    if type == "key input" then
        b.text = b.defaultText .. ": " .. value
    end
    b.r, b.g, b.b = unpack(color)
    b.timeIn = 0
    b.style = style
    b.alpha = .5
    b.trans = NewTransition(0, 0, 0, style.easing)
    b.isDown = false
    b.border = 1
    b.value = value

    return setmetatable(b, button)
end

function SetSounds(hover, click)
    hover_sound = hover
    click_sound = click
end

function SetTranslation(x, y)
    tx, ty = x or 0, y or 0
end

function button:isIn()
    return between(love.mouse.getX() - tx, self.x, self.x + self.w) and between(love.mouse.getY() - ty, self.y, self.y + self.h)
end

function button:update(dt)
    if self:isIn() and self.trans:isDone() and self.alpha < anim then
        if self.style.easing then
            self.alpha = anim
            self.trans = NewTransition(0, self.w, anim, self.style.easing)
        
            hover_sound:stop()
            hover_sound:play()
        end
    elseif not self:isIn() and self.trans and self.trans:isDone() then
        self.alpha = self.alpha - dt
    end
    
    if self.trans then
        self.trans:update(dt)
    end
    
    if self.isDown then
        self.border = math.min(self.border + dt * 2, 2)
    else
        self.border = math.max(self.border - dt, 1)
    end
end

function button:draw() -- also act as update
    local font = love.graphics.getFont()

    --[[local shape = {
        self.x + 5, self.y + 5,
        self.x + 5, self.y,
        self.x + self.w - 5, self.y,
        self.x + self.w - 5, self.y + 5,
        self.x + self.w, self.y + 5,
        self.x + self.w, self.y + self.h - 5,
        self.x + self.w - 5, self.y + self.h - 5,
        self.x + self.w - 5, self.y + self.h,
        self.x + 5, self.y + self.h,
        self.x + 5, self.y + self.h - 5,
        self.x, self.y + self.h - 5,
        self.x, self.y + 5
    }]]
    
    love.graphics.setColor(self.r / 255, self.g / 255, self.b / 255, 1)
       
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 5)
    --love.graphics.polygon("fill", unpack(shape))
    
    local time = self.trans:GetProgress()
        
    if time ~= 0 then
        love.graphics.setColor(self.r / 255 - self.alpha / 4, self.g / 255 - self.alpha / 4, self.b / 255 - self.alpha / 4, self.alpha)
        
        if self.style.shape == "sharp" then
            --love.graphics.polygon("fill",
            --    self.x, self.y + self.h,
            --    self.x, self.y,
            --    self.x + math.min(time + math.min(time, self.h / 2), self.w), self.y,
            --    self.x + math.min(time, self.w), self.y + self.h
            --)
            love.graphics.rectangle("fill", self.x, self.y, time, self.h, 5)
        else
            love.graphics.rectangle("fill", self.x, self.y, time, self.h)
        end
    end
    
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(self.border)
    --love.graphics.polygon("line", unpack(shape))
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 5)

    love.graphics.setColor(0, 0, 0)
    love.graphics.print(self.text, self.x + self.w / 2 - font:getWidth(self.text) / 2,  self.y + self.h / 2 - font:getHeight(self.text) / 2)
end

function button:mousepressed(x, y, button)
    if button == 1 and self.type ~= "group" then
        if self:isIn() then
            click_sound:play()
            self.isDown = true
            
            if self.type == "key input" then
                self.text = "..."
            end
        end
    end
end

function button:mousereleased(x, y, button)
    if button == 1 and self.type == "button" then
        self.isDown = false
        if self:isIn() then
            self.click()
        end
    end
end

function button:keypressed( key, scancode, isrepeat )
    if self.type == "key input" and self.isDown then
        self.isDown = false
        self.value = key
        self.text = self.defaultText .. ": " .. self.value
        self.click(key)
    end
end

function button:getPos()
    return self.x, self.y
end