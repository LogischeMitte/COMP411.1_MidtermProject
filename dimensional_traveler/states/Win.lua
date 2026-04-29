Win = {}

function Win:enter(score)
    self.score = score or 0
    self.selection = 1
    self.options = {'Retry', 'Main Menu'}

    --- Save high score
    local scores = HighScore.loadScores()
    table.insert(scores, self.score)
    --- Sort and keep top 3 scores
    table.sort(scores, function(a, b) return a > b end)

    while #scores > 3 do
        table.remove(scores)
    end
    --- Save updated scores
    HighScore.saveScores(scores)
end

function Win:keypressed(key)
    if key == 'up' or key == 'w' or key == 'down' or key == 's' then
        self.selection = 3 - self.selection
    elseif key == 'return' or key == 'enter' then
        if self.selection == 1 then
            Gamestate.switch(Play)
        else
            Gamestate.switch(Menu)
        end
    end
end

function Win:draw()
    love.graphics.clear(0.05, 0.15, 0.1)
    love.graphics.setFont(gFonts.large)
    love.graphics.printf('You Win!', 0, 32, VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(gFonts.medium)
    love.graphics.printf('Score: ' .. self.score, 0, 80, VIRTUAL_WIDTH, 'center')

    for i, option in ipairs(self.options) do
        local y = 120 + i * 22
        love.graphics.setColor(i == self.selection and {0.6, 1, 0.6} or {1, 1, 1})
        love.graphics.printf(option, 0, y, VIRTUAL_WIDTH, 'center')
    end
    love.graphics.setColor(1, 1, 1)
end
