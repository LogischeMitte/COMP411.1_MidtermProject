Enemy = {}
Enemy.__index = Enemy

local FRAME_W    = 64
local FRAME_H    = 64
local NUM_FRAMES = 4
local DRAW_W     = 32
local DRAW_H     = 32

local sheet = nil
local quads  = {}

local function loadSheet()
    if sheet then return end
    sheet = love.graphics.newImage('assets/sprites/enemywalkingandshooting.png')
    local sw, sh = sheet:getDimensions()
    for i = 0, NUM_FRAMES - 1 do
        quads[i + 1] = love.graphics.newQuad(i * FRAME_W, 0, FRAME_W, FRAME_H, sw, sh)
    end
end

function Enemy.create(x, y)
    local self = setmetatable({}, Enemy)
    self.x = x
    self.y = y
    self.width    = 16
    self.height   = 32
    self.fireTimer = 0
    self.fireRate  = 2
    self.speed     = 40
    self.health    = 3
    self.dead      = false
    self.direction = -1

    self.animFrame = 1
    self.animTimer = 0
    self.animFPS   = 10

    loadSheet()
    return self
end

function Enemy:collidesWith(bullet)
    return bullet.x < self.x + self.width
       and bullet.x + bullet.width > self.x
       and bullet.y < self.y + self.height
       and bullet.y + bullet.height > self.y
end

function Enemy:update(dt, player, bullets)
    if self.dead then return end

    --- Taking Damage
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        if bullet.fromPlayer and self:collidesWith(bullet) then
            bullet.dead = true
            self.health = self.health - 1
            Sound.play('enemy_damage')
            if self.health <= 0 then
                self.dead = true
                player.score = player.score + 100
                return
            end
        end
    end

    --- Attack & movement
    if self:canSeePlayer(player) then
        self.fireTimer = self.fireTimer + dt
        if self.fireTimer >= self.fireRate then
            local dir = player.x < self.x and -1 or 1
            local eBullet = Bullet.create(self.x + self.width / 2, self.y + self.height / 2 - 12, dir)
            eBullet.fromPlayer = false
            table.insert(bullets, eBullet)
            self.fireTimer = 0
        end

        if player.x < self.x then
            self.x = self.x - self.speed * dt
            self.direction = -1
        else
            self.x = self.x + self.speed * dt
            self.direction = 1
        end
    end

    --- Animation
    self.animTimer = self.animTimer + dt
    local frameDur = 1 / self.animFPS
    while self.animTimer >= frameDur do
        self.animTimer = self.animTimer - frameDur
        self.animFrame = (self.animFrame % NUM_FRAMES) + 1
    end
end

function Enemy:canSeePlayer(player)
    return math.abs(player.x - self.x) < 300
end

function Enemy:draw()
    if not sheet then return end

    local scaleX = DRAW_W / FRAME_W
    local scaleY = DRAW_H / FRAME_H


    local drawX = self.x + self.width / 2 - DRAW_W / 2
    local drawY = self.y + self.height - DRAW_H

    love.graphics.setColor(1, 1, 1)
    if self.direction == -1 then
        love.graphics.draw(sheet, quads[self.animFrame],
            drawX + DRAW_W, drawY, 0, -scaleX, scaleY)
    else
        love.graphics.draw(sheet, quads[self.animFrame],
            drawX, drawY, 0, scaleX, scaleY)
    end
    love.graphics.setColor(1, 1, 1)
end

return Enemy
