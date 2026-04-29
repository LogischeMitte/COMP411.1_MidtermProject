Bullet = {}
Bullet.__index = Bullet

function Bullet.create(x, y, dir)
    local self = setmetatable({}, Bullet)
    self.x = x
    self.y = y
    self.dx = 240 * dir
    self.width = 4
    self.height = 4
    self.dead = false
    self.fromPlayer = false
    return self
end

function Bullet:update(dt)
    self.x = self.x + self.dx * dt
    if self.x < 0 or self.x > VIRTUAL_WIDTH then
        self.dead = true
    end
end

function Bullet:draw()
    if self.fromPlayer then
        love.graphics.setColor(0.2, 0.5, 1)
    else
        love.graphics.setColor(1, 0.15, 0.15)
    end
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
end

return Bullet