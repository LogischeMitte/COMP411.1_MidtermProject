GameOver = {}

function GameOver:enter(previousScore)
    self.previousScore = previousScore or 0
    self.selection = 1
    self.options = {'Retry', 'Main Menu'}

    --- Save high score
    local scores = HighScore.loadScores()
    table.insert(scores, self.previousScore)
    --- Sort and keep top 3 scores
    table.sort(scores, function(a, b) return a > b end)

    while #scores > 3 do
        table.remove(scores)
    end
    --- Save updated scores
    HighScore.saveScores(scores)
end

function GameOver:update(dt)
end

function GameOver:keypressed(key)
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

function GameOver:draw()
    love.graphics.clear(0.1, 0, 0)
    love.graphics.setFont(gFonts.large)
    love.graphics.printf('Game Over', 0, 40, VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(gFonts.small)
    love.graphics.printf('Score: ' .. self.previousScore, 0, 90, VIRTUAL_WIDTH, 'center')

    local text = self.selection == 1 and 'Retry' or 'Main Menu'
    love.graphics.printf(text, 0, 130, VIRTUAL_WIDTH, 'center')
end

return GameOver