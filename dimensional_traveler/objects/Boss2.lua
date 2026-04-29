Boss2 = {}
Boss2.__index = Boss2

local IMG_W2 = 40
local IMG_H2 = 48

local sprites2 = {}

local function loadSprites2()
    if next(sprites2) then return end
    sprites2[1] = love.graphics.newImage('assets/sprites/bosschill2.png')
    sprites2[2] = love.graphics.newImage('assets/sprites/bossangry2.png')
end

function Boss2.create(x, y)
    local self = setmetatable({}, Boss2)
    self.x = x
    self.y = y
    self.width = 40
    self.height = 48
    self.health = 20
    self.maxHealth = 20
    self.phase = 1
    self.speed = 50

    self.fireTimer = 0
    self.fireRate = 1.8

    self.moveDir = -1
    self.dy = 0
    self.gravity = 800
    self.isGrounded = true
    self.floorY = y

    loadSprites2()
    return self
end

function Boss2:checkCollision(bullet)
    return self.x < bullet.x + bullet.width and
           self.x + self.width > bullet.x and
           self.y < bullet.y + bullet.height and
           self.y + self.height > bullet.y
end

function Boss2:update(dt, player, bullets)
    self:checkPhase()
    self:movePattern(dt, player)

    self.fireTimer = self.fireTimer - dt
    if self.fireTimer <= 0 then
        self.fireTimer = self.fireRate

        if self.phase == 1 then
            self:fireSingle(bullets, player)
        else
            self:fireSpread(bullets, player)
        end
    end

    -- Taking damage
    if bullets then
        for i = #bullets, 1, -1 do
            local bullet = bullets[i]
            if bullet.fromPlayer and self:checkCollision(bullet) then
                self.health = self.health - 1
                Sound.play('boss_damage')
                table.remove(bullets, i)
            end
        end
    end
end

function Boss2:checkPhase()
    if self.health <= math.floor(self.maxHealth / 2) and self.phase == 1 then
        self.phase = 2
        self.fireRate = 1.2
        self.speed = 80
        Sound.play('boss_phase2')
    end
end

function Boss2:movePattern(dt, player)
    self.x = self.x + (self.speed * self.moveDir) * dt

    if self.x <= 0 then
        self.x = 0
        self.moveDir = 1
    elseif self.x >= VIRTUAL_WIDTH - self.width then
        self.x = VIRTUAL_WIDTH - self.width
        self.moveDir = -1
    end

    if math.abs(player.x - self.x) < 50 and self.isGrounded then
        self.dy = -380
        self.isGrounded = false
        self.moveDir = (player.x < self.x) and 1 or -1
    end

    self.dy = self.dy + self.gravity * dt
    self.y = self.y + self.dy * dt

    if self.y >= self.floorY then
        self.y = self.floorY
        self.dy = 0
        self.isGrounded = true
    end
end

function Boss2:fireSingle(bullets, player)
    local dir = player.x < self.x and -1 or 1
    local b = Bullet.create(self.x + self.width / 2, self.y + self.height / 2, dir)
    b.fromPlayer = false
    table.insert(bullets, b)
end

function Boss2:fireSpread(bullets, player)
    local halfX = self.x + self.width / 2
    local halfY = self.y + self.height / 2

    local b1 = Bullet.create(halfX, halfY, -1)
    b1.fromPlayer = false
    table.insert(bullets, b1)

    local b2 = Bullet.create(halfX, halfY, 1)
    b2.fromPlayer = false
    table.insert(bullets, b2)

    local dir = player.x < self.x and -1 or 1
    local b3 = Bullet.create(halfX, self.y + 6, dir)
    b3.fromPlayer = false
    table.insert(bullets, b3)
end

function Boss2:draw()
    local img = sprites2[self.phase] or sprites2[1]

    local scaleX = self.width  / IMG_W2
    local scaleY = self.height / IMG_H2

    love.graphics.setColor(1, 1, 1)
    if self.moveDir == -1 then
        love.graphics.draw(img, self.x, self.y, 0, scaleX, scaleY)
    else
        love.graphics.draw(img, self.x + self.width, self.y, 0, -scaleX, scaleY)
    end

    -- Health bar
    local barW = self.width + 10
    local barH = 4
    local bx   = self.x - 5
    local by   = self.y - 8
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle('fill', bx, by, barW, barH)
    love.graphics.setColor(0.2, 0.9, 0.3)
    love.graphics.rectangle('fill', bx, by, barW * (self.health / self.maxHealth), barH)
    love.graphics.setColor(1, 1, 1)
end

return Boss2
