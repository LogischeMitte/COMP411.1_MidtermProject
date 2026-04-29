push = require 'lib.push'
Gamestate = require 'lib.hump.gamestate'

require 'states.Menu'
require 'states.Play'
require 'states.Pause'
require 'states.Win'
require 'states.GameOver'
require 'states.HighScore'
require 'objects.Player'
require 'objects.Bullet'
require 'objects.Enemy'
require 'objects.Boss'
require 'objects.Boss2'
require 'objects.Sound'

VIRTUAL_WIDTH = 320
VIRTUAL_HEIGHT = 180
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

local themes = {
    forest = {
        'assets/sprites/bg_layer1.png',
        'assets/sprites/bg_layer2.png',
        'assets/sprites/bg_layer3.png'
    },
    cave = {
        'assets/sprites/bg_layer1_dark.png',
        'assets/sprites/bg_layer2_dark.png',
        'assets/sprites/bg_layer3_dark.png'
    }
}

gCurrentTheme = 'forest'
local bgLayers = {}
local bgScrolls = {0, 0, 0}
local BG_SPEEDS = {15, 45, 90}

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('The Dimensional Traveler')

    music = love.audio.newSource('assets/sounds/gameBackgroundMusic.wav', 'stream')
    music:setLooping(true)
    music:setVolume(0.1)
    music:play()


    gFonts = {
        small  = love.graphics.newFont(8),
        medium = love.graphics.newFont(16),
        large  = love.graphics.newFont(32)
    }

    bgLayers[1] = love.graphics.newImage('assets/sprites/bg_layer1.png')
    bgLayers[2] = love.graphics.newImage('assets/sprites/bg_layer2.png')
    bgLayers[3] = love.graphics.newImage('assets/sprites/bg_layer3.png')

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable  = true,
        vsync      = true
    })

    Sound.load()

    Gamestate.switch(Menu)
end

function loadBackgrounds(themeName)
    gCurrentTheme = themeName
    for i = 1, 3 do
        bgLayers[i] = love.graphics.newImage(themes[themeName][i])
        bgScrolls[i] = 0
    end
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)
    local moveDir = 0
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        moveDir = 1
    elseif love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        moveDir = -1
    end

    for i = 1, 3 do
        local imgWidth = bgLayers[i]:getWidth()
        bgScrolls[i] = (bgScrolls[i] + (BG_SPEEDS[i] * moveDir) * dt) % imgWidth
    end

    Gamestate.update(dt)
end

function love.keypressed(key)
    Gamestate.keypressed(key)
end

function love.draw()
    push:start()
        love.graphics.setColor(1, 1, 1, 1)
        for i = 1, 3 do
            local img = bgLayers[i]
            local x = -bgScrolls[i]
            love.graphics.draw(img, x, 0)
            love.graphics.draw(img, x + img:getWidth(), 0)
        end
        Gamestate.draw()
    push:finish()
end
