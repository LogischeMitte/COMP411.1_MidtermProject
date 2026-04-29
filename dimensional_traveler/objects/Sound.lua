Sound = {}

local sources = {}

function Sound.load()
    sources.fire          = love.audio.newSource('assets/sounds/fire.wav',          'static')
    sources.player_damage = love.audio.newSource('assets/sounds/player_damage.wav', 'static')
    sources.boss_damage   = love.audio.newSource('assets/sounds/boss_damage.wav',   'static')
    sources.boss_phase2   = love.audio.newSource('assets/sounds/boss_phase2.wav',   'static')
    sources.enemy_damage  = love.audio.newSource('assets/sounds/enemy_damage.wav',  'static')
end

function Sound.play(name)
    local src = sources[name]
    if src then
        src:stop()
        src:play()
    end
end

return Sound
