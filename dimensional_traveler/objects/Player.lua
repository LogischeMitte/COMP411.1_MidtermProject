Player = {}
Player.__index = Player


local FRAME_W    = 64      
local FRAME_H    = 64
local NUM_FRAMES = 4

local DRAW_W     = 32
local DRAW_H     = 32

local ANIM_DEF = {
    idle               = { sheet = 'idle',               fps = 6,  loop = true  },
    idle_shooting      = { sheet = 'idle_shooting',      fps = 8,  loop = true  },
    walking            = { sheet = 'walking',            fps = 10, loop = true  },
    walking_shooting   = { sheet = 'walking_shooting',   fps = 10, loop = true  },
    crouching          = { sheet = 'crouching',          fps = 6,  loop = false },
    crouching_shooting = { sheet = 'crouching_shooting', fps = 8,  loop = false },
}


local sheets = {}

local function loadSheets()
    if next(sheets) then return end 
    for _, def in pairs(ANIM_DEF) do
        if not sheets[def.sheet] then
            sheets[def.sheet] = love.graphics.newImage('assets/sprites/' .. def.sheet .. '.png')
        end
    end
end


local function buildQuads(sheet)
    local quads = {}
    local sw, sh = sheet:getDimensions()
    for i = 0, NUM_FRAMES - 1 do
        quads[i + 1] = love.graphics.newQuad(i * FRAME_W, 0, FRAME_W, FRAME_H, sw, sh)
    end
    return quads
end

function Player.create(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.width = 16
    self.height = 32
    self.maxHealth = 5
    self.healthLevel = self.maxHealth
    self.lives = 3
    self.score = 0
    self.startX = x
    self.startY = y
    self.isCrouching = false
    self.currentHitboxHeight = self.height
    self.isShooting = false
    self.shootTimer = 0        

    self.dy = 0
    self.gravity = 800
    self.jumpForce = -300
    self.isGrounded = true
    self.floorY = y
    self.direction = 1        

    self.invincibleTimer = 0
    self.isInvincible = false
    self.blinkTimer = 0

    loadSheets()
    self.quads = {}
    for _, def in pairs(ANIM_DEF) do
        if not self.quads[def.sheet] then
            self.quads[def.sheet] = buildQuads(sheets[def.sheet])
        end
    end

    self.currentAnim = 'idle'
    self.animFrame = 1
    self.animTimer = 0

    return self
end


function Player:notifyShooting()
    self.isShooting = true
    self.shootTimer = 0.25
end


local function resolveAnim(self)
    if self.isCrouching then
        return self.isShooting and 'crouching_shooting' or 'crouching'
    end

    local moving = love.keyboard.isDown('a') or love.keyboard.isDown('d') or
                   love.keyboard.isDown('left') or love.keyboard.isDown('right')


    if not self.isGrounded or moving then
        return self.isShooting and 'walking_shooting' or 'walking'
    end

    return self.isShooting and 'idle_shooting' or 'idle'
end

function Player:update(dt)
    local speed = 90
    self.x = math.max(0, math.min(VIRTUAL_WIDTH - self.width, self.x))

    --- Movement
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        self.x = self.x - speed * dt
        self.direction = -1
    elseif love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        self.x = self.x + speed * dt
        self.direction = 1
    end

    --- Jump
    if love.keyboard.isDown('w') and self.isGrounded then
        self.dy = self.jumpForce
        self.isGrounded = false
    end
    self.dy = self.dy + self.gravity * dt
    self.y  = self.y  + self.dy * dt

    if self.y >= self.floorY then
        self.y = self.floorY
        self.dy = 0
        self.isGrounded = true
    end

    --- Crouch
    if love.keyboard.isDown('s') then
        self.isCrouching = true
        self.currentHitboxHeight = self.height / 2
    else
        self.isCrouching = false
        self.currentHitboxHeight = self.height
    end

    --- Shoot timer decay
    if self.isShooting then
        self.shootTimer = self.shootTimer - dt
        if self.shootTimer <= 0 then
            self.isShooting = false
        end
    end

    --- I-frames
    if self.isInvincible then
        self.invincibleTimer = self.invincibleTimer - dt
        self.blinkTimer      = self.blinkTimer + dt
        if self.invincibleTimer <= 0 then
            self.isInvincible = false
        end
    end

    --- Animation update
    local newAnim = resolveAnim(self)
    if newAnim ~= self.currentAnim then
        self.currentAnim = newAnim
        self.animFrame   = 1
        self.animTimer   = 0
    end

    local def = ANIM_DEF[self.currentAnim]
    local frameDur = 1 / def.fps
    self.animTimer = self.animTimer + dt

    while self.animTimer >= frameDur do
        self.animTimer = self.animTimer - frameDur
        if self.animFrame < NUM_FRAMES then
            self.animFrame = self.animFrame + 1
        elseif def.loop then
            self.animFrame = 1
        end

    end
end

function Player:takeDamage()
    if not self.isInvincible then
        self.healthLevel = self.healthLevel - 1
        self.isInvincible = true
        self.invincibleTimer = 1.5
        self.blinkTimer = 0
        Sound.play('player_damage')

        if self.healthLevel <= 0 then
            self.lives = self.lives - 1
            if self.lives > 0 then
                self.x, self.y   = self.startX, self.startY
                self.healthLevel = self.maxHealth
                self.isInvincible = false
            else
                Gamestate.switch(GameOver, self.score)
            end
        end
    end
end

function Player:draw()
    -- Blink during i-frames
    if self.isInvincible and math.floor(self.blinkTimer * 10) % 2 == 0 then
        return
    end

    local def = ANIM_DEF[self.currentAnim]
    local sheet = sheets[def.sheet]
    local quad = self.quads[def.sheet][self.animFrame]

    local scaleX = DRAW_W / FRAME_W
    local scaleY = DRAW_H / FRAME_H


    local drawX = self.x + self.width / 2 - DRAW_W / 2
    local drawY

    if self.isCrouching then

        local hitboxTop = self.y + (self.height - self.currentHitboxHeight)
        drawY = hitboxTop + self.currentHitboxHeight - DRAW_H
    else
        drawY = self.y + self.height - DRAW_H
    end

    love.graphics.setColor(1, 1, 1)

    if self.direction == -1 then

        love.graphics.draw(sheet, quad,
            drawX + DRAW_W, drawY,
            0, -scaleX, scaleY)
    else
        love.graphics.draw(sheet, quad,
            drawX, drawY,
            0, scaleX, scaleY)
    end

    love.graphics.setColor(1, 1, 1)
end

return Player
