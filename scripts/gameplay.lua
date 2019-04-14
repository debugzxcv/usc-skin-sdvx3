-- The following code slightly simplifies the render/update code, making it easier to explain in the comments
-- It replaces a few of the functions built into USC and changes behaviour slightly
-- Ideally, this should be in the common.lua file, but the rest of the skin does not support it
-- I'll be further refactoring and documenting the default skin and making it more easy to
--  modify for those who either don't know how to skin well or just want to change a few images
--  or behaviours of the default to better suit them.
-- Skinning should be easy and fun!

local RECT_FILL = "fill"
local RECT_STROKE = "stroke"
local RECT_FILL_STROKE = RECT_FILL .. RECT_STROKE

gfx._ImageAlpha = 1

gfx._FillColor = gfx.FillColor
gfx._StrokeColor = gfx.StrokeColor
gfx._SetImageTint = gfx.SetImageTint

-- we aren't even gonna overwrite it here, it's just dead to us
gfx.SetImageTint = nil

function gfx.FillColor(r, g, b, a)
    r = math.floor(r or 255)
    g = math.floor(g or 255)
    b = math.floor(b or 255)
    a = math.floor(a or 255)

    gfx._ImageAlpha = a / 255
    gfx._FillColor(r, g, b, a)
    gfx._SetImageTint(r, g, b)
end

function gfx.StrokeColor(r, g, b)
    r = math.floor(r or 255)
    g = math.floor(g or 255)
    b = math.floor(b or 255)

    gfx._StrokeColor(r, g, b)
end

function gfx.DrawRect(kind, x, y, w, h)
    local doFill = kind == RECT_FILL or kind == RECT_FILL_STROKE
    local doStroke = kind == RECT_STROKE or kind == RECT_FILL_STROKE

    local doImage = not (doFill or doStroke)

    gfx.BeginPath()

    if doImage then
        gfx.ImageRect(x, y, w, h, kind, gfx._ImageAlpha, 0)
    else
        gfx.Rect(x, y, w, h)
        if doFill then gfx.Fill() end
        if doStroke then gfx.Stroke() end
    end
end

local buttonStates = { }
local buttonsInOrder = {
    game.BUTTON_BTA,
    game.BUTTON_BTB,
    game.BUTTON_BTC,
    game.BUTTON_BTD,

    game.BUTTON_FXL,
    game.BUTTON_FXR,

    game.BUTTON_STA,
}

function UpdateButtonStatesAfterProcessed()
    for i = 1, 6 do
        local button = buttonsInOrder[i]
        buttonStates[button] = game.GetButton(button)
    end
end

function game.GetButtonPressed(button)
    return game.GetButton(button) and not buttonStates[button]
end
-- -------------------------------------------------------------------------- --
-- game.IsUserInputActive:                                                    --
-- Used to determine if (valid) controller input is happening.                --
-- Valid meaning that laser motion will not return true unless the laser is   --
--  active in gameplay as well.                                               --
-- This restriction is not applied to buttons.                                --
-- The player may press their buttons whenever and the function returns true. --
-- Lane starts at 1 and ends with 8.                                          --
function game.IsUserInputActive(lane)
    if lane < 7 then
        return game.GetButton(buttonsInOrder[lane])
    end
    return gameplay.IsLaserHeld(lane - 7)
end
-- -------------------------------------------------------------------------- --
-- gfx.FillLaserColor:                                                        --
-- Sets the current fill color to the laser color of the given index.         --
-- An optional alpha value may be given as well.                              --
-- Index may be 1 or 2.                                                       --
function gfx.FillLaserColor(index, alpha)
    alpha = math.floor(alpha or 255)
    local r, g, b = game.GetLaserColor(index - 1)
    gfx.FillColor(r, g, b, alpha)
end
-- -------------------------------------------------------------------------- --
function load_number_image(path)
    local images = {}
    for i = 0, 9 do
        images[i + 1] = gfx.CreateSkinImage(string.format("%s/%d.png", path, i), 0)
    end
    return images
end
-- -------------------------------------------------------------------------- --
function draw_number(x, y, alpha, num, digits, images, is_dim)
    local tw, th = gfx.ImageSize(images[1])
    x = x + (tw * (digits - 1)) / 2
    y = y - th / 2
    for i = 1, digits do
        local mul = 10 ^ (i - 1)
        local digit = math.floor(num / mul) % 10
        local a = alpha
        if is_dim and num < mul then
            a = 0
        end
        gfx.BeginPath()
        gfx.ImageRect(x, y, tw, th, images[digit + 1], a, 0)
        x = x - tw
    end
end

-- -------------------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --
--                  The actual gameplay script starts here!                   --
-- -------------------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --
-- Global data used by many things:                                           --
local resx, resy -- The resolution of the window
local portrait -- whether the window is in portrait orientation
local desw, desh -- The resolution of the deisign
local scale -- the scale to get from design to actual units
-- -------------------------------------------------------------------------- --
-- All images used by the script:                                             --
local jacketFallback = gfx.CreateSkinImage("song_select/jacket_loading.png", 0)
local bottomFill = gfx.CreateSkinImage("console/console.png", 0)
local topFill = gfx.CreateSkinImage("fill_top.png", 0)
local critAnim = gfx.CreateSkinImage("crit_anim.png", 0)
local critBar = gfx.CreateSkinImage("crit_bar.png", 0)
local critConsole = gfx.CreateSkinImage("crit_console.png", 0)
local laserCursor = gfx.CreateSkinImage("pointer.png", 0)
local laserCursorOverlay = gfx.CreateSkinImage("pointer_overlay.png", 0)
local scoreEarly = gfx.CreateSkinImage("score_early.png", 0)
local scoreLate = gfx.CreateSkinImage("score_late.png", 0)
local numberImages = load_number_image("number")

local ioConsoleDetails = {
    gfx.CreateSkinImage("console/detail_left.png", 0),
    gfx.CreateSkinImage("console/detail_right.png", 0),
}

local consoleAnimImages = {
    gfx.CreateSkinImage("console/glow_bta.png", 0),
    gfx.CreateSkinImage("console/glow_btb.png", 0),
    gfx.CreateSkinImage("console/glow_btc.png", 0),
    gfx.CreateSkinImage("console/glow_btd.png", 0),

    gfx.CreateSkinImage("console/glow_fxl.png", 0),
    gfx.CreateSkinImage("console/glow_fxr.png", 0),

    gfx.CreateSkinImage("console/glow_voll.png", 0),
    gfx.CreateSkinImage("console/glow_volr.png", 0),
}
-- -------------------------------------------------------------------------- --
-- Timers, used for animations:                                               --
local introTimer = 2
local outroTimer = 0

local alertTimers = {-2,-2}

local earlateTimer = 0
local critAnimTimer = 0

local consoleAnimSpeed = 10
local consoleAnimTimers = { 0, 0, 0, 0, 0, 0, 0, 0 }
-- -------------------------------------------------------------------------- --
-- Miscelaneous, currently unsorted:                                          --
local score = 0
local jacket = nil
local critLinePos = { 0.95, 0.75 };
local late = false
local clearTexts = {"TRACK FAILED", "TRACK COMPLETE", "TRACK COMPLETE", "FULL COMBO", "PERFECT" }
-- -------------------------------------------------------------------------- --
-- ResetLayoutInformation:                                                    --
-- Resets the layout values used by the skin.                                 --
function ResetLayoutInformation()
    resx, resy = game.GetResolution()
    portrait = resy > resx
    desw = portrait and 720 or 1280
    desh = desw * (resy / resx)
    scale = resx / desw
end
-- -------------------------------------------------------------------------- --
-- render:                                                                    --
-- The primary & final render call.                                           --
-- Use this to render basically anything that isn't the crit line or the      --
--  intro/outro transitions.                                                  --
function render(deltaTime)
    -- make sure that our transform is cleared, clean working space
    -- TODO: this shouldn't be necessary!!!
    gfx.ResetTransform()

    -- While the intro timer is running, we fade in from black
    if introTimer > 0 then
        gfx.FillColor(0, 0, 0, math.floor(255 * math.min(introTimer, 1)))
        gfx.DrawRect(RECT_FILL, 0, 0, resx, resy)
    end

    gfx.Scale(scale, scale)
    local yshift = 0

    -- In portrait, we draw a banner across the top
    -- The rest of the UI needs to be drawn below that banner
    -- TODO: this isn't how it'll work in the long run, I don't think
    if portrait then yshift = draw_banner(deltaTime) end

    -- gfx.Translate(0, yshift - 150 * math.max(introTimer - 1, 0))
    gfx.Translate(0, yshift)
    draw_song_info(deltaTime)
    draw_score(deltaTime)
    -- gfx.Translate(0, -yshift + 150 * math.max(introTimer - 1, 0))
    gfx.Translate(0, -yshift)
    draw_status(deltaTime)
    draw_gauge(deltaTime)
    draw_earlate(deltaTime)
    draw_combo(deltaTime)
    draw_alerts(deltaTime)
end
-- -------------------------------------------------------------------------- --
-- SetUpCritTransform:                                                        --
-- Utility function which aligns the graphics transform to the center of the  --
--  crit line on screen, rotation include.                                    --
-- This function resets the graphics transform, it's up to the caller to      --
--  save the transform if needed.                                             --
function SetUpCritTransform()
    -- start us with a clean empty transform
    gfx.ResetTransform()
    -- translate and rotate accordingly
    gfx.Translate(gameplay.critLine.x, gameplay.critLine.y)
    gfx.Rotate(-gameplay.critLine.rotation)
end
-- -------------------------------------------------------------------------- --
-- GetCritLineCenteringOffset:                                                --
-- Utility function which returns the magnitude of an offset to center the    --
--  crit line on the screen based on its position and rotation.               --
function GetCritLineCenteringOffset()
    local distFromCenter = resx / 2 - gameplay.critLine.x
    local dvx = math.cos(gameplay.critLine.rotation)
    local dvy = math.sin(gameplay.critLine.rotation)
    return math.sqrt(dvx * dvx + dvy * dvy) * distFromCenter
end
-- -------------------------------------------------------------------------- --
-- render_crit_base:                                                          --
-- Called after rendering the highway and playable objects, but before        --
--  the built-in hit effects.                                                 --
-- This is the first render function to be called each frame.                 --
-- This call resets the graphics transform, it's up to the caller to          --
--  save the transform if needed.                                             --
function render_crit_base(deltaTime)
    -- Kind of a hack, but here (since this is the first render function
    --  that gets called per frame) we update the layout information.
    -- This means that the player can resize their window and
    --  not break everything
    ResetLayoutInformation()

    critAnimTimer = critAnimTimer + deltaTime
    SetUpCritTransform()

    -- Figure out how to offset the center of the crit line to remain
    --  centered on the players screen
    local xOffset = GetCritLineCenteringOffset()
    gfx.Translate(xOffset, 0)

    -- Draw a transparent black overlay below the crit line
    -- This darkens the play area as it passes
    gfx.FillColor(0, 0, 0, 200)
    gfx.DrawRect(RECT_FILL, -resx, 0, resx * 2, resy)
    gfx.FillColor(255, 255, 255)

    -- The absolute width of the crit line itself
    -- we check to see if we're playing in portrait mode and
    --  change the width accordingly
    local critWidth = resx * (portrait and 1.25 or 0.8)

    -- get the scaled dimensions of the crit line pieces
    local clw, clh = gfx.ImageSize(critAnim)
    local critAnimHeight = 9 * scale
    local critAnimWidth = critAnimHeight * (clw / clh)

    local cbw, cbh = gfx.ImageSize(critBar)
    local critBarHeight = critAnimHeight * (cbh / clh)
    local critBarWidth = critBarHeight * (cbw / cbh)

    -- render the core of the crit line
    do
        -- The crit line is made up of many small pieces scrolling outward
        -- Calculate how many pieces, starting at what offset, are require to
        --  completely fill the space with no gaps from edge to center
        local animWidth = critWidth * 0.65
        local numPieces = 1 + math.ceil(animWidth / (critAnimWidth * 2))
        local startOffset = critAnimWidth * ((critAnimTimer * 0.15) % 1)

        -- left side
        -- Use a scissor to limit the drawable area to only what should be visible
        gfx.Scissor(-animWidth / 2, -critAnimHeight / 2, animWidth / 2, critAnimHeight)
        for i = 1, numPieces do
            gfx.DrawRect(critAnim, -startOffset - critAnimWidth * (i - 1), -critAnimHeight / 2, critAnimWidth, critAnimHeight)
        end
        gfx.ResetScissor()

        -- right side
        -- exactly the same, but in reverse
        gfx.Scissor(0, -critAnimHeight / 2, animWidth / 2, critAnimHeight)
        for i = 1, numPieces do
            gfx.DrawRect(critAnim, -critAnimWidth + startOffset + critAnimWidth * (i - 1), -critAnimHeight / 2, critAnimWidth, critAnimHeight)
        end
        gfx.ResetScissor()
    end

    -- Draw the critical bar
    gfx.DrawRect(critBar, -critWidth / 2, -critBarHeight / 2 - 5 * scale, critWidth, critBarHeight)

    -- Draw back portion of the console
    if portrait then
        local ccw, cch = gfx.ImageSize(critConsole)
        local critConsoleHeight = 95 * scale
        local critConsoleWidth = critConsoleHeight * (ccw / cch)

        local critConsoleY = 95 * scale
        gfx.DrawRect(critConsole, -critConsoleWidth / 2, -critConsoleHeight / 2 + critConsoleY, critConsoleWidth, critConsoleHeight)
    end

    -- we're done, reset graphics stuffs
    gfx.FillColor(255, 255, 255)
    gfx.ResetTransform()
end
-- -------------------------------------------------------------------------- --
-- render_crit_overlay:                                                       --
-- Called after rendering built-int crit line effects.                        --
-- Use this to render laser cursors or an IO Console in portrait mode!        --
-- This call resets the graphics transform, it's up to the caller to          --
--  save the transform if needed.                                             --
function render_crit_overlay(deltaTime)
    SetUpCritTransform()

    -- Figure out how to offset the center of the crit line to remain
    --  centered on the players screen.
    local xOffset = GetCritLineCenteringOffset()

    -- When in portrait, we can draw the console at the bottom
    if portrait then
        -- We're going to make temporary modifications to the transform
        gfx.Save()
        gfx.Translate(xOffset * 0.5, 0)

        local bfw, bfh = gfx.ImageSize(bottomFill)

        local distBetweenKnobs = 0.446
        local distCritVertical = -0.125

        local ioFillTx = bfw / 2
        local ioFillTy = bfh * distCritVertical -- 0.098

        -- The total dimensions for the console image
        local io_x, io_y, io_w, io_h = -ioFillTx, -ioFillTy, bfw, bfh

        -- Adjust the transform accordingly first
        local consoleFillScale = (resx * 0.525) / (bfw * distBetweenKnobs)
        gfx.Scale(consoleFillScale, consoleFillScale);

        -- Actually draw the fill
        gfx.FillColor(255, 255, 255)
        gfx.DrawRect(bottomFill, io_x, io_y, io_w, io_h)

        -- Then draw the details which need to be colored to match the lasers
        -- for i = 1, 2 do
        --     gfx.FillLaserColor(i)
        --     gfx.DrawRect(ioConsoleDetails[i], io_x, io_y, io_w, io_h)
        -- end

        -- Draw the button press animations by overlaying transparent images
        gfx.GlobalCompositeOperation(gfx.BLEND_OP_LIGHTER)
        for i = 1, 6 do
            -- While a button is held, increment a timer
            -- If not held, that timer is set back to 0
            if game.GetButton(buttonsInOrder[i]) then
                consoleAnimTimers[i] = consoleAnimTimers[i] + deltaTime * consoleAnimSpeed * 3.14 * 2
            else
                consoleAnimTimers[i] = 0
            end

            -- If the timer is active, flash based on a sin wave
            local timer = consoleAnimTimers[i]
            if timer ~= 0 then
                local image = consoleAnimImages[i]
                local alpha = (math.sin(timer) * 0.5 + 0.5) * 0.5 + 0.25
                gfx.FillColor(255, 255, 255, alpha * 255);
                gfx.DrawRect(image, io_x, io_y, io_w, io_h)
            end
        end
        gfx.GlobalCompositeOperation(gfx.BLEND_OP_SOURCE_OVER)

        -- Undo those modifications
        gfx.Restore();
    end

    local cw, ch = gfx.ImageSize(laserCursor)
    local cursorWidth = 60 * scale
    local cursorHeight = cursorWidth * (ch / cw)

    -- draw each laser cursor
    for i = 1, 2 do
        local cursor = gameplay.critLine.cursors[i - 1]
        local pos, skew = cursor.pos, cursor.skew

        -- Add a kinda-perspective effect with a horizontal skew
        gfx.SkewX(skew)

        -- Draw the colored background with the appropriate laser color
        gfx.FillLaserColor(i, cursor.alpha * 255)
        gfx.DrawRect(laserCursor, pos - cursorWidth / 2, -cursorHeight / 2, cursorWidth, cursorHeight)
        -- Draw the uncolored overlay on top of the color
        gfx.FillColor(255, 255, 255, cursor.alpha * 255)
        gfx.DrawRect(laserCursorOverlay, pos - cursorWidth / 2, -cursorHeight / 2, cursorWidth, cursorHeight)
        -- Un-skew
        gfx.SkewX(-skew)
    end

    -- We're done, reset graphics stuffs
    gfx.FillColor(255, 255, 255)
    gfx.ResetTransform()
end
-- -------------------------------------------------------------------------- --
-- draw_banner:                                                               --
-- Renders the banner across the top of the screen in portrait.               --
-- This function expects no graphics transform except the design scale.       --
function draw_banner(deltaTime)
    local bannerWidth, bannerHeight = gfx.ImageSize(topFill)
    local actualHeight = desw * (bannerHeight / bannerWidth)

    gfx.FillColor(255, 255, 255)
    gfx.DrawRect(topFill, 0, 0, desw, actualHeight)

    return actualHeight
end
-- -------------------------------------------------------------------------- --
-- draw_stat:                                                                 --
-- Draws a formatted name + value combination at x, y over w, h area.         --
function draw_stat(x, y, w, h, name, value, format, r, g, b)
    gfx.Save()

    -- Translate from the parent transform, wherever that may be
    gfx.Translate(x, y)

    -- Draw the `name` top-left aligned at `h` size
    gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_TOP)
    gfx.FontSize(h)
    gfx.Text(name .. ":", 0, 0) -- 0, 0, is x, y after translation

    -- Realign the text and draw the value, formatted
    gfx.TextAlign(gfx.TEXT_ALIGN_RIGHT + gfx.TEXT_ALIGN_TOP)
    gfx.Text(string.format(format, value), w, 0)
    -- This draws an underline beneath the text
    -- The line goes from 0, h to w, h
    gfx.BeginPath()
    gfx.MoveTo(0, h)
    gfx.LineTo(w, h) -- only defines the line, does NOT draw it yet

    -- If a color is provided, set it
    if r then gfx.StrokeColor(r, g, b)
    -- otherwise, default to a light grey
    else gfx.StrokeColor(200, 200, 200) end

    -- Stroke out the line
    gfx.StrokeWidth(1)
    gfx.Stroke()
    -- Undo our transform changes
    gfx.Restore()

    -- Return the next `y` position, for easier vertical stacking
    return y + h + 5
end
-- -------------------------------------------------------------------------- --
-- draw_song_info:                                                            --
-- Draws current song information at the top left of the screen.              --
-- This function expects no graphics transform except the design scale.       --
local songBack = gfx.CreateSkinImage("song_back.png", 0)
local numberDot = gfx.CreateSkinImage("number/dot.png", 0)
local diffImages = {
    gfx.CreateSkinImage("diff/novice.png", 0),
    gfx.CreateSkinImage("diff/advanced.png", 0),
    gfx.CreateSkinImage("diff/exhaust.png", 0),
    gfx.CreateSkinImage("diff/gravity.png", 0)
}

function draw_song_info(deltaTime)
    local jacketWidth = 75

    -- Check to see if there's a jacket to draw, and attempt to load one if not
    if jacket == nil or jacket == jacketFallback then
        jacket = gfx.LoadImageJob(gameplay.jacketPath, jacketFallback)
    end
    gfx.Save()

    if not portrait then
        gfx.Translate(0, 112)
    end

    -- Ensure the font has been loaded
    gfx.LoadSkinFont("segoeui.ttf")

    -- Draw the background
    tw, th = gfx.ImageSize(songBack)
    gfx.FillColor(255,255,255)
    gfx.BeginPath()
    gfx.ImageRect(-20, -110, tw, th, songBack, 1, 0)

    -- Draw the jacket
    gfx.BeginPath()
    gfx.ImageRect(22, -85, jacketWidth, jacketWidth, jacket, 1, 0)

    -- Draw level name
    gfx.BeginPath()
    tw, th = gfx.ImageSize(diffImages[gameplay.difficulty + 1])
    gfx.ImageRect(22, -4, tw, th, diffImages[gameplay.difficulty + 1], 1, 0)

    -- Draw level number
    draw_number(78, 0, 1.0, gameplay.level, 2, numberImages, false)

    -- Draw the song title, scaled to fit as best as possible
    local title = gameplay.title .. " / " .. gameplay.artist
    local titleWidth = 520
    gfx.Save()
    gfx.TextAlign(gfx.TEXT_ALIGN_CENTER)
    gfx.FontSize(18)
    x1, y1, x2, y2 = gfx.TextBounds(0, 0, title)
    local textScale = math.min(titleWidth / x2, 1)
    gfx.Translate(desw / 2, portrait and -290 or -90)
    gfx.Scale(textScale, 1)
    gfx.Text(title, 0, 0)
    gfx.Restore()

    -- Draw the BPM
    gfx.FillColor(255,255,255)
    draw_number(220, -15, 1.0, gameplay.bpm, 3, numberImages, false)

    -- Draw the hi-speed
    gfx.FontSize(16)
    draw_number(213 + 20, 2, 1.0, math.floor((gameplay.hispeed + 0.05) * 10) % 10, 1, numberImages, false)
    tw, th = gfx.ImageSize(numberDot)
    gfx.BeginPath()
    gfx.ImageRect(213 + 8, -4, tw, th, numberDot, 1, 0)
    draw_number(213, 2, 1.0, math.floor(gameplay.hispeed), 1, numberImages, false)
    -- gfx.Text(string.format("%.1f", gameplay.hispeed), 208, 9)

    -- Fill the progress bar
    gfx.BeginPath()
    gfx.FillColor(242, 146, 54)
    gfx.Rect(128, -31, 140 * gameplay.progress, 3)
    gfx.Fill()

    -- When the player is holding Start, the hispeed can be changed
    -- Shows the current hispeed values
    if game.GetButton(game.BUTTON_STA) then
      gfx.BeginPath()
      gfx.FillColor(255,255,255)
      gfx.Text(string.format("HiSpeed: %.0f x %.1f = %.0f",
      gameplay.bpm, gameplay.hispeed, gameplay.bpm * gameplay.hispeed),
      0, 115)
    end
    gfx.Restore()
end
-- -------------------------------------------------------------------------- --
-- draw_best_diff:                                                            --
-- If there are other saved scores, this displays the difference between      --
--  the current play and your best.                                           --
function draw_best_diff(deltaTime, x, y)
    -- Don't do anything if there's nothing to do
    if not gameplay.scoreReplays[1] then return end

    -- Calculate the difference between current and best play
    local difference = score - gameplay.scoreReplays[1].currentScore
    local prefix = " " -- used to properly display negative values

    gfx.BeginPath()
    gfx.FontSize(40)

    gfx.FillColor(255, 255, 255)
    if difference < 0 then
        -- If we're behind the best score, separate the minus sign and change the color
        gfx.FillColor(255, 50, 50)
        difference = math.abs(difference)
        prefix = "-"
    end

    -- %08d formats a number to 8 characters
    -- This includes the minus sign, so we do that separately
    gfx.LoadSkinFont("NovaMono.ttf")
    gfx.FontSize(48)
    gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_TOP)
    gfx.Text(string.format("%s%08d", prefix, difference), x, y)
end
-- -------------------------------------------------------------------------- --
-- draw_score:                                                                --
local scoreBack = gfx.CreateSkinImage("score_back.png", 0)
local scoreNumberLarge = load_number_image("score_l")
local scoreNumberSmall = load_number_image("score_s")

function draw_score(deltaTime)
    tw, th = gfx.ImageSize(scoreBack)
    gfx.FillColor(255, 255, 255)
    gfx.BeginPath()
    gfx.ImageRect(desw - tw + 12, portrait and -110 or 0, tw, th, scoreBack, 1, 0)

    gfx.FillColor(255, 255, 255)
    draw_number(desw - 188, portrait and -46 or 64, 1.0, math.floor(score / 1000), 5, scoreNumberLarge, false)
    draw_number(desw - 56, portrait and -42 or 68, 1.0, score, 3, scoreNumberSmall, false)
end
-- -------------------------------------------------------------------------- --
-- draw_gauge:                                                                --
local gaugeNumBack = gfx.CreateSkinImage("gauge_num_back.png", 0)
gfx.SetGaugeColor(0,  47, 244, 255) --Normal gauge fail
gfx.SetGaugeColor(1, 252,  76, 171) --Normal gauge clear
gfx.SetGaugeColor(2, 255, 255, 255) --Hard gauge low (<30%)
gfx.SetGaugeColor(3, 255, 255, 255) --Hard gauge high (>30%)

function draw_gauge(deltaTime)
    local height = 1024 * scale * 0.5
    local width = 512 * scale * 0.5
    local posy = resy / 2 - height / 2 + 60
    local posx = resx - width
    if portrait then
        posy = posy - 90
        posx = resx - width
    end
    gfx.DrawGauge(gameplay.gauge, posx, posy, width, height, deltaTime)

	--draw gauge % label
	posx = posx / scale
	posx = posx + (135 * 0.5)
    -- 630 = 0% position
    height = 630 * 0.5
	posy = posy / scale

    local tw, th = gfx.ImageSize(gaugeNumBack)
    -- 80 = 100% position
    posy = posy + (95 * 0.5) + height - height * gameplay.gauge
    -- Draw the background
    gfx.BeginPath()
    gfx.FillColor(255, 255, 255)
    gfx.ImageRect(posx - 44, posy - 10, tw, th, gaugeNumBack, 1, 0)

    gfx.BeginPath()
    gfx.FillColor(250, 228, 112)
    draw_number(posx - 24, posy + 4, 1.0, math.floor(gameplay.gauge * 100), 3, numberImages, true)
	-- gfx.TextAlign(gfx.TEXT_ALIGN_RIGHT + gfx.TEXT_ALIGN_MIDDLE)
	-- gfx.FontSize(18)
	-- gfx.Text(string.format("%d", math.floor(gameplay.gauge * 100)), posx, posy + 4)
end
-- -------------------------------------------------------------------------- --
-- draw_combo:                                                                --
local comboBottom = gfx.CreateSkinImage("chain/chain.png", 0)
local comboDigits = load_number_image("chain")
local comboTimer = 0
local combo = 0
local maxCombo = 0
function draw_combo(deltaTime)
    if combo == 0 then return end
    comboTimer = comboTimer + deltaTime
    local posx = desw / 2
    local posy = desh * critLinePos[1] - 100
    if portrait then posy = desh * critLinePos[2] - 150 end
    if gameplay.comboState == 2 then
        gfx.FillColor(255,200,0) --puc
    elseif gameplay.comboState == 1 then
        gfx.FillColor(255,200,0) --uc
    else
        gfx.FillColor(255,255,255) --regular
    end
    local alpha = math.floor(comboTimer * 20) % 2
    alpha = (alpha * 100 + 155) / 255

    -- \_ chain _/
    tw, th = gfx.ImageSize(comboBottom)
    gfx.BeginPath()
    gfx.ImageRect(posx - tw / 2, posy - th / 2, tw, th, comboBottom, alpha, 0)

    tw, th = gfx.ImageSize(comboDigits[1])
    posy = posy - th

    local digit = combo % 10
    gfx.BeginPath()
    gfx.ImageRect(posx + tw, posy - th / 2, tw, th, comboDigits[digit + 1], alpha, 0)

    digit = math.floor(combo / 10) % 10
    gfx.BeginPath()
    gfx.ImageRect(posx, posy - th / 2, tw, th, comboDigits[digit + 1], combo >= 10 and alpha or 0.2, 0)

    digit = math.floor(combo / 100) % 10
    gfx.BeginPath()
    gfx.ImageRect(posx - tw, posy - th / 2, tw, th, comboDigits[digit + 1], combo >= 100 and alpha or 0.2, 0)

    digit = math.floor(combo / 1000) % 10
    gfx.BeginPath()
    gfx.ImageRect(posx - tw * 2, posy - th / 2, tw, th, comboDigits[digit + 1], combo >= 1000 and alpha or 0.2, 0)

    -- Draw max combo
    gfx.FillColor(255, 255, 255)
    draw_number(desw - 222, portrait and 315 or 110, 1.0, maxCombo, 4, numberImages, false)
end
-- -------------------------------------------------------------------------- --
-- draw_earlate:                                                              --
function draw_earlate(deltaTime)
    earlateTimer = math.max(earlateTimer - deltaTime,0)
    if earlateTimer == 0 then return nil end
    local alpha = math.floor(earlateTimer * 20) % 2
    alpha = (alpha * 100 + 155) / 255
    gfx.BeginPath()

    local xpos = desw / 2
    local ypos = desh * critLinePos[1] - 450
    if portrait then ypos = desh * critLinePos[2] - 450 end
    if late then
        tw, th = gfx.ImageSize(scoreLate)
        gfx.ImageRect(xpos - tw / 2, ypos - th / 2, tw, th, scoreLate, alpha, 0)
    else
        tw, th = gfx.ImageSize(scoreEarly)
        gfx.ImageRect(xpos - tw / 2, ypos - th / 2, tw, th, scoreEarly, alpha, 0)
    end
end
-- -------------------------------------------------------------------------- --
-- draw_alerts:                                                               --
function draw_alerts(deltaTime)
    alertTimers[1] = math.max(alertTimers[1] - deltaTime,-2)
    alertTimers[2] = math.max(alertTimers[2] - deltaTime,-2)
    if alertTimers[1] > 0 then --draw left alert
        gfx.Save()
        local posx = desw / 2 - 350
        local posy = desh * critLinePos[1] - 135
        if portrait then
            posy = desh * critLinePos[2] - 135
            posx = 65
        end
        gfx.Translate(posx,posy)
        r,g,b = game.GetLaserColor(0)
        local alertScale = (-(alertTimers[1] ^ 2.0) + (1.5 * alertTimers[1])) * 5.0
        alertScale = math.min(alertScale, 1)
        gfx.Scale(1, alertScale)
        gfx.BeginPath()
        gfx.RoundedRectVarying(-50,-50,100,100,20,0,20,0)
        gfx.StrokeColor(r,g,b)
        gfx.FillColor(20,20,20)
        gfx.StrokeWidth(2)
        gfx.Fill()
        gfx.Stroke()
        gfx.BeginPath()
        gfx.FillColor(r,g,b)
        gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_MIDDLE)
        gfx.FontSize(90)
        gfx.Text("L",0,0)
        gfx.Restore()
    end
    if alertTimers[2] > 0 then --draw right alert
        gfx.Save()
        local posx = desw / 2 + 350
        local posy = desh * critLinePos[1] - 135
        if portrait then
            posy = desh * critLinePos[2] - 135
            posx = desw - 65
        end
        gfx.Translate(posx,posy)
        r,g,b = game.GetLaserColor(1)
        local alertScale = (-(alertTimers[2] ^ 2.0) + (1.5 * alertTimers[2])) * 5.0
        alertScale = math.min(alertScale, 1)
        gfx.Scale(1, alertScale)
        gfx.BeginPath()
        gfx.RoundedRectVarying(-50,-50,100,100,0,20,0,20)
        gfx.StrokeColor(r,g,b)
        gfx.FillColor(20,20,20)
        gfx.StrokeWidth(2)
        gfx.Fill()
        gfx.Stroke()
        gfx.BeginPath()
        gfx.FillColor(r,g,b)
        gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_MIDDLE)
        gfx.FontSize(90)
        gfx.Text("R",0,0)
        gfx.Restore()
    end
end
-- -------------------------------------------------------------------------- --
-- draw_status:                                                               --
local statusBack = gfx.CreateSkinImage("status_back.png", 0)
function draw_status(deltaTime)
    -- Draw the background
    tw, th = gfx.ImageSize(statusBack)
    gfx.FillColor(255, 255, 255)
    gfx.BeginPath()
    gfx.ImageRect(0, desh / 2 - th / 2, tw, th, statusBack, 1, 0)

    draw_best_diff(deltaTime, 40, desh / 2 - 10)
end

-- -------------------------------------------------------------------------- --
-- render_intro:                                                              --
function render_intro(deltaTime)
    if not game.GetButton(game.BUTTON_STA) then
        introTimer = introTimer - deltaTime
    end
    introTimer = math.max(introTimer, 0)
    return introTimer <= 0
end
-- -------------------------------------------------------------------------- --
-- render_outro:                                                              --
function render_outro(deltaTime, clearState)
    if clearState == 0 then return true end
    gfx.ResetTransform()
    gfx.BeginPath()
    gfx.Rect(0,0,resx,resy)
    gfx.FillColor(0,0,0, math.floor(127 * math.min(outroTimer, 1)))
    gfx.Fill()
    gfx.Scale(scale,scale)
    gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_MIDDLE)
    gfx.FillColor(255,255,255, math.floor(255 * math.min(outroTimer, 1)))
    gfx.LoadSkinFont("NovaMono.ttf")
    gfx.FontSize(70)
    gfx.Text(clearTexts[clearState], desw / 2, desh / 2)
    outroTimer = outroTimer + deltaTime
    return outroTimer > 2, 1 - outroTimer
end
-- -------------------------------------------------------------------------- --
-- update_score:                                                              --
function update_score(newScore)
    score = newScore
end
-- -------------------------------------------------------------------------- --
-- update_combo:                                                              --
function update_combo(newCombo)
    combo = newCombo
    if combo > maxCombo then
        maxCombo = combo
    end
end
-- -------------------------------------------------------------------------- --
-- near_hit:                                                                  --
function near_hit(wasLate) --for updating early/late display
    late = wasLate
    earlateTimer = 0.75
end
-- -------------------------------------------------------------------------- --
-- laser_alert:                                                               --
function laser_alert(isRight) --for starting laser alert animations
    if isRight and alertTimers[2] < -1.5 then
        alertTimers[2] = 1.5
    elseif alertTimers[1] < -1.5 then
        alertTimers[1] = 1.5
    end
end