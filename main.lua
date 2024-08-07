player = {}
gravity = 100
jumpForce = -100
obstacles = {}
ground = {}
GameState = 
{
    idle = 1,
    running = 2,
    paused = 3,
    over = 4
}
currentGameState = GameState.idle
gameFont = love.graphics.newFont(20)
initialPositionY = 0

function love.load()
    love.window.setMode( 256, 320 )
    initialPositionY = love.graphics.getHeight() / 2
    
    player.x = love.graphics.getWidth() / 2
    player.y = initialPositionY
    player.w = 24
    player.h = 24
    player.velocityY = 0

    spawnTime = 0
    score = 0

    ground.x = 0
    ground.y = love.graphics.getHeight() - 32
    ground.h = 32
    ground.w = 256
end

function love.update(dt)
    if currentGameState == GameState.idle then
      
    elseif currentGameState == GameState.running then
        onRunningState(dt)
    elseif currentGameState == GameState.paused then

    elseif currentGameState == GameState.over then
        player.velocityY = player.velocityY + gravity * dt
        player.y = player.y + player.velocityY * dt
        if player.y > ground.y - 32 then
            player.y = ground.y - 24        
        end
    end    
end

function onRunningState(dt)
    player.velocityY = player.velocityY + gravity * dt
    player.y = player.y + player.velocityY * dt

    if player.y < 0 then
        player.y = 0
    end

    if player.y + player.h >= love.graphics.getHeight() then
        player.y = love.graphics.getHeight() - player.h
    end

    spawnTime = spawnTime + dt

    if spawnTime >= 4 then -- numero pequeno
        local obstacle = createObstacle()
        table.insert(obstacles, obstacle)
        spawnTime = 0
    end
    
    for i = 1, #obstacles do
        local obstacle = obstacles[i]

        local obstacleTopHeight = 32 * (obstacle.holeIndex - 1)
        if obstacleTopHeight > 0 then
            if checkCollision(player.x, player.y, player.w, player.h, obstacle.x, obstacle.y, 32, obstacleTopHeight) then
                currentGameState = GameState.over
            end
        end
        
        local holeMaxCell = obstacle.holeIndex + obstacle.holeSize - 1
        local obstacleBottomBase = obstacle.y + (holeMaxCell * 32)
        if 32 * (obstacle.cells - holeMaxCell) > 0 then
            if checkCollision(player.x, player.y, player.w, player.h, obstacle.x, obstacle.y + (holeMaxCell * 32), 32, 32 * (obstacle.cells - holeMaxCell)) then
                currentGameState = GameState.over
            end
        end

        if not obstacle.passedThrough and obstacle.x + 32 < player.x then
            score = score + 1
            obstacle.passedThrough = true
        end
    
    end


    for i = #obstacles, 1, -1 do
        local obstacle = obstacles[i]
        obstacle.x = obstacle.x + -32 * dt

        if obstacle.x + 32 < 0 then
            table.remove(obstacles, i)
        end
    end

    if checkCollision(player.x, player.y, player.w, player.h, ground.x, ground.y, ground.w, ground.h) then
        currentGameState = GameState.over
    end
end

function love.draw()
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", ground.x, ground.y, ground.w, ground.h)

    for i = 1, #obstacles do
        local obstacle = obstacles[i] -- cacheando
        love.graphics.setColor(0, 1, 0)
        local holeMaxCell = obstacle.holeIndex + obstacle.holeSize - 1
        love.graphics.rectangle("fill", obstacle.x, obstacle.y, 32, 32 * (obstacle.holeIndex - 1))
        love.graphics.rectangle("fill", obstacle.x, obstacle.y + (holeMaxCell * 32), 32, 32 * (obstacle.cells - holeMaxCell))
    end

    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    if currentGameState == GameState.idle then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameFont)
        love.graphics.printf("Press space to begin or esc to quit!", 0, love.graphics.getHeight()/2 - 20, love.graphics.getWidth(), "center")
    elseif currentGameState == GameState.running then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Score: " .. score, love.graphics.getWidth() / 2 - 40, 5)
    elseif currentGameState == GameState.paused then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() / 2 - 45, love.graphics.getWidth(), 80)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameFont)
        love.graphics.printf("Paused, press space to continue, enter to restart or esc to quit!", 0, love.graphics.getHeight()/2 - 40, love.graphics.getWidth(), "center")
    elseif currentGameState == GameState.over then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Score: " .. score, love.graphics.getWidth() / 2 - 40, 5)
        
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), 80)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameFont)
        love.graphics.printf("Press esc to quit or enter restart!", 0, love.graphics.getHeight()/2 - 20, love.graphics.getWidth(), "center")
    end
end

function love.keypressed(key)
    if currentGameState == GameState.idle then
        if key == "space"  then
            currentGameState = GameState.running
        elseif key == 'escape' then
            love.event.quit()
        end
    elseif currentGameState == GameState.running then
        if key == "space"  then
            player.velocityY = jumpForce
        elseif key == 'escape' then
            currentGameState = GameState.paused
        end
    elseif currentGameState == GameState.paused then
        if key == 'space' then
            currentGameState = GameState.running
        elseif key == 'return' then
            currentGameState = GameState.idle
        elseif key == 'escape' then
            love.event.quit()
        end
    elseif currentGameState == GameState.over then
        if key == 'return' then
            resetLevel()
        elseif key == 'escape' then
            love.event.quit()
        end
    end
end

function createObstacle()
    local obstacle = {}
    obstacle.x = love.graphics.getWidth()
    obstacle.y = 0
    obstacle.cells = 10
    obstacle.holeSize = 3
    obstacle.holeIndex = love.math.random(1, obstacle.cells - obstacle.holeSize - 1)
    obstacle.passedThrough = false
    return obstacle
end

function checkCollision(xa, ya, wa, ha, xb, yb, wb, hb)
    local maxXa = xa + wa
    local maxYa = ya + ha
    local maxXb = xb + wb
    local maxYb = yb + hb

    local collisionX = maxXa >= xb and maxXb >= xa
    local collisionY = maxYa >= yb and maxYb >= ya

    return collisionX and collisionY
end

function resetLevel()
    score = 0
    spawnTime = 0
    player.y = initialPositionY
    player.velocityY = 0
    for i = #obstacles, 1, -1 do
        local obstacle = obstacles[i]
        table.remove(obstacles, i)
    end
    currentGameState = GameState.idle
end