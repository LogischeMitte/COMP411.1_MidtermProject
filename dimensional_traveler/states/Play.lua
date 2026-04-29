Play = {}

local function getLevelData()
    return {
        [1] = {
            theme      = 'forest',
            enemies    = {{x = 180, y = VIRTUAL_HEIGHT - 50}, {x = 260, y = VIRTUAL_HEIGHT - 50}},
            bossType   = 'Boss',
            bossX      = 240,
            bossY      = VIRTUAL_HEIGHT - 80,
            bossScore  = 300,
            nextLevel  = 2,
        },
        [2] = {
            theme      = 'cave',
            enemies    = {
                {x = 160, y = VIRTUAL_HEIGHT - 50},
                {x = 220, y = VIRTUAL_HEIGHT - 50},
                {x = 280, y = VIRTUAL_HEIGHT - 50},
            },
            bossType   = 'Boss2',
            bossX      = 250,
            bossY      = VIRTUAL_HEIGHT - 88,
            bossScore  = 600,
            nextLevel  = nil,
        },
    }
end


function Play:enter(previousState, levelNum, carriedPlayer)
    if previousState == Pause then
        return
    end

    self.level = levelNum or 1
    local data = getLevelData()[self.level]

    -- Switch background theme
    loadBackgrounds(data.theme)

    -- Reuse the player from the previous level
    if carriedPlayer then
        self.player = carriedPlayer
        self.player.x = 40
        self.player.y = VIRTUAL_HEIGHT - 50
        self.player.startX = 40
        self.player.startY = VIRTUAL_HEIGHT - 50
        self.player.floorY = VIRTUAL_HEIGHT - 50
        self.player.healthLevel = self.player.maxHealth
        self.player.isInvincible = false
        self.player.invincibleTimer = 0
        self.player.dy = 0
        self.player.isGrounded = true
    else
        self.player = Player.create(40, VIRTUAL_HEIGHT - 50)
    end

    -- Spawn enemies
    self.bullets = {}
    self.enemies = {}
    for _, eData in ipairs(data.enemies) do
        table.insert(self.enemies, Enemy.create(eData.x, eData.y))
    end

    -- Spawn boss
    if data.bossType == 'Boss2' then
        self.boss = Boss2.create(data.bossX, data.bossY)
    else
        self.boss = Boss.create(data.bossX, data.bossY)
    end

    self.bossScore = data.bossScore
    self.nextLevel = data.nextLevel

    self.levelBanner = 'Level ' .. self.level
    self.levelBannerTimer = 2.5

    self.uiHealthBar = love.graphics.newImage('assets/sprites/health_bar.png')
    self.uiLifeIcon  = love.graphics.newImage('assets/sprites/life.png')
end

function Play:keypressed(key)
    if key == 'p' then
        Gamestate.switch(Pause, self)

    elseif key == 'escape' then
        Gamestate.switch(Menu)

    elseif key == 'space' then
        local shootDir = self.player.direction or 1

        if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
            shootDir = -1
        elseif love.keyboard.isDown('d') or love.keyboard.isDown('right') then
            shootDir = 1
        end

        local spawnX = self.player.x
        if shootDir == 1 then
            spawnX = self.player.x + self.player.width
        end

        local newBullet = Bullet.create(spawnX, self.player.y + self.player.height / 2, shootDir)
        newBullet.fromPlayer = true
        table.insert(self.bullets, newBullet)
        self.player:notifyShooting()
        Sound.play('fire')
    end
end

function Play:update(dt)
    if self.levelBannerTimer and self.levelBannerTimer > 0 then
        self.levelBannerTimer = self.levelBannerTimer - dt
    end

    --- Player
    self.player:update(dt)

    --- Bullets
    for i = #self.bullets, 1, -1 do
        local bullet = self.bullets[i]
        bullet:update(dt)

        if not bullet.fromPlayer then
            local playerTopY = self.player.y
            if self.player.isCrouching then
                playerTopY = self.player.y + (self.player.height - self.player.currentHitboxHeight)
            end

            if bullet.x < self.player.x + self.player.width and
               bullet.x + bullet.width > self.player.x and
               bullet.y < playerTopY + self.player.currentHitboxHeight and
               bullet.y + bullet.height > playerTopY then

                self.player:takeDamage()
                table.remove(self.bullets, i)
            elseif bullet.dead then
                table.remove(self.bullets, i)
            end
        else
            if bullet.dead then
                table.remove(self.bullets, i)
            end
        end
    end

    --- Enemies
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        enemy:update(dt, self.player, self.bullets)

        if self.player.x < enemy.x + enemy.width and
           self.player.x + self.player.width > enemy.x and
           self.player.y < enemy.y + enemy.height and
           self.player.y + self.player.currentHitboxHeight > enemy.y then

            self.player:takeDamage()
        end

        if enemy.dead then
            table.remove(self.enemies, i)
        end
    end

    --- Boss
    self.boss:update(dt, self.player, self.bullets)

    if self.player.x < self.boss.x + self.boss.width and
       self.player.x + self.player.width > self.boss.x and
       self.player.y < self.boss.y + self.boss.height and
       self.player.y + self.player.currentHitboxHeight > self.boss.y then

        self.player:takeDamage()
    end

    --- Boss defeated
    if self.boss.health <= 0 then
        self.player.score = self.player.score + self.bossScore

        if self.nextLevel then
            Gamestate.switch(Play, nil, self.nextLevel, self.player)
        else
            Gamestate.switch(Win, self.player.score)
        end
    end
end

function Play:draw()
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end

    self.boss:draw()
    self.player:draw()

    for _, bullet in ipairs(self.bullets) do
        bullet:draw()
    end

    self:drawHUD()

    -- Level banner
    if self.levelBannerTimer and self.levelBannerTimer > 0 then
        local alpha = math.min(1, self.levelBannerTimer)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.setFont(gFonts.large)
        love.graphics.printf(self.levelBanner, 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function Play:drawHUD()
    local startX = 8
    local startY = 8

    --- Health bar
    if self.uiHealthBar then
        local barWidth  = self.uiHealthBar:getWidth()
        local barHeight = self.uiHealthBar:getHeight()
        local healthPct = self.player.healthLevel / self.player.maxHealth
        local currentWidth = barWidth * healthPct

        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.rectangle('fill', startX, startY, barWidth, barHeight)

        if currentWidth > 0 then
            local healthQuad = love.graphics.newQuad(0, 0, currentWidth, barHeight, barWidth, barHeight)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(self.uiHealthBar, healthQuad, startX, startY)
        end
    end

    --- Lives
    love.graphics.setFont(gFonts.small)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print('Lives:', 8, 32)

    if self.uiLifeIcon then
        for i = 1, self.player.lives do
            love.graphics.draw(self.uiLifeIcon, 40 + (i - 1) * 16, 28)
        end
    end

    --- Score
    love.graphics.setColor(1, 1, 1)
    love.graphics.print('Score: ' .. self.player.score, 8, 48)

    --- Level indicator
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf('Level ' .. self.level, 0, 8, VIRTUAL_WIDTH - 8, 'right')
    love.graphics.setColor(1, 1, 1)
end
