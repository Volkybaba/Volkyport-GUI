-- Load the timer module
local Timer = require "timer"

-- Screen dimensions
local screenWidth, screenHeight

-- Background image (our own Volkyport background)
local bgImage

-- Black hole effect
local blackhole = {}

-- Wait for signal
local fileCheckInterval = 0.5  -- Check every 0.5 seconds
local timeSinceLastCheck = -2.25  -- wait 2.0 seconds before checking for the file
local fileFound = false

-- Screen initialization
local function initializeScreen()
    screenWidth, screenHeight = love.graphics.getDimensions()
end

local function initializeBlackHole()
    blackhole = {
        x = screenWidth / 2,
        y = screenHeight / 2,
        radius = 0,
        maxRadius = math.sqrt(screenWidth^2 + screenHeight^2),
        color = {0, 0, 0}
    }

    -- Expand the black hole on startup
    Timer.after(0.3, function()
        Timer.tween(0.5, blackhole, {radius = blackhole.maxRadius}, 'in-cubic')
    end)
end

local function startBlackHoleClose()
    -- Wait 0.5 seconds, then run the black hole animation
    Timer.after(0.5, function()
        Timer.tween(0.5, blackhole, {radius = 0}, 'out-cubic')

        -- After the black hole animation, delete the file and quit
        Timer.after(0.5, function()
            -- Detect the path where main.lua is located
            local mainPath = love.filesystem.getSource()
            local filePath = mainPath .. "/stopsplash"  -- Construct full path to 'stopsplash'

            print("Attempting to delete file at path: " .. filePath)

            -- Use os.remove directly
            local success, err = os.remove(filePath)
            if success then
                print("File 'stopsplash' deleted successfully.")
            else
                print("Failed to delete file: ", err)
            end

            -- Quit the game
            love.event.quit()
        end)
    end)
end

function love.load()
    local desktopWidth, desktopHeight = love.window.getDesktopDimensions()
    love.window.setMode(desktopWidth, desktopHeight, {fullscreen = true, fullscreentype = "desktop"})
    love.graphics.setDefaultFilter("linear", "linear")
    initializeScreen()
    initializeBlackHole()
    bgImage = love.graphics.newImage("assets/background.png")
end

-- Draw the background image, fitted to the screen (whole image visible)
local function drawBackground()
    local iw, ih = bgImage:getDimensions()
    local scale = math.min(screenWidth / iw, screenHeight / ih)
    local dw, dh = iw * scale, ih * scale
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(bgImage, (screenWidth - dw) / 2, (screenHeight - dh) / 2, 0, scale, scale)
end

-- Draw the black hole effect
local function drawBlackHole()
    love.graphics.setColor(blackhole.color)

    -- Use a stencil to create the black hole effect
    love.graphics.stencil(function()
        love.graphics.circle("fill", blackhole.x, blackhole.y, blackhole.radius)
    end, "replace", 1)

    -- Enable the stencil test to draw outside the circle
    love.graphics.setStencilTest("less", 1)

    -- Draw the black screen
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Reset the stencil test
    love.graphics.setStencilTest()
end

function love.draw()
    drawBackground()
    drawBlackHole()
end

local function checkFileSignal(dt)
    timeSinceLastCheck = timeSinceLastCheck + dt

    if timeSinceLastCheck >= fileCheckInterval then
        timeSinceLastCheck = 0  -- Reset the timer

        if love.filesystem.getInfo("stopsplash") then
            fileFound = true
            startBlackHoleClose()  -- Start the black hole animation when file is found
        end
    end
end

-- Update game state
function love.update(dt)
    Timer.update(dt)
    checkFileSignal(dt)  -- Clean file check call
end
