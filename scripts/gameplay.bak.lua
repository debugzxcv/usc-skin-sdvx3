local score = 0
local combo = 0
local jacket = nil
local resx,resy = game.GetResolution()
local portrait = resy > resx
local desw = 1280 --design width
if portrait then desw = 720 end
local critLinePos = { 0.95, 0.73 };
local desh = desw * (resy / resx) --design height
local scale = resx / desw
local songInfoWidth = 400
local jacketWidth = 75
local late = false
local earlateTimer = 0;
local earlateColors = { {255,255,0}, {0,255,255} }
local alertTimers = {-2,-2}
local title = nil
local artist = nil
local jacketFallback = gfx.CreateSkinImage("song_select/loading.png", 0)
local bottomFill = gfx.CreateSkinImage("fill_bottom.png",0)
local topFill = gfx.CreateSkinImage("fill_top.png",0)
local diffNames = {"NOV", "ADV", "EXH", "INF"}
local introTimer = 2
local outroTimer = 0
local clearTexts = {"TRACK FAILED", "TRACK COMPLETE", "TRACK COMPLETE", "FULL COMBO", "PERFECT" }
local yshift = 0
local scoreEarly = gfx.CreateSkinImage("score_early.png", 0)
local scoreLate = gfx.CreateSkinImage("score_late.png", 0)

local comboScale = 1.0
local comboTime = 0
local comboBottom = gfx.CreateSkinImage("chain/chain.png", 0)
local comboDigits = {}
for i = 0, 10 do
    comboDigits[i + 1] = gfx.CreateSkinImage(string.format("chain/%d.png", i), 0)
end

local songBack = gfx.CreateSkinImage("song_back.png", 0)
local scoreBack = gfx.CreateSkinImage("score_back.png", 0)

draw_stat = function(x,y,w,h, name, value, format,r,g,b)
  gfx.Save()
  gfx.Translate(x,y)
  gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_TOP)
  gfx.FontSize(h)
  gfx.Text(name .. ":",0, 0)
  gfx.TextAlign(gfx.TEXT_ALIGN_RIGHT + gfx.TEXT_ALIGN_TOP)
  gfx.Text(string.format(format, value),w, 0)
  gfx.BeginPath()
  gfx.MoveTo(0,h)
  gfx.LineTo(w,h)
  if r then gfx.StrokeColor(r,g,b)
  else gfx.StrokeColor(200,200,200) end
  gfx.StrokeWidth(1)
  gfx.Stroke()
  gfx.Restore()
  return y + h + 5
end

drawSongInfo = function(deltaTime)
    if jacket == nil or jacket == jacketFallback then
        jacket = gfx.LoadImageJob(gameplay.jacketPath, jacketFallback)
    end
    gfx.Save()
    --if portrait then gfx.Scale(0.7,0.7) end

    tw, th = gfx.ImageSize(songBack)
    gfx.BeginPath()
    gfx.ImageRect(-20, -110, tw, th, songBack, 1, 0)

    gfx.BeginPath()
    gfx.ImageRect(22, -85, jacketWidth, jacketWidth, jacket, 1, 0)

    -- gfx.BeginPath()
    -- gfx.LoadSkinFont("segoeui.ttf")
    -- gfx.Translate(5,5) --upper left margin
    -- gfx.FillColor(20,20,20,200);
    -- gfx.Rect(0,0,songInfoWidth,100)
    -- gfx.Fill()

    --begin diff/level
    -- gfx.BeginPath()
    -- gfx.Rect(0,85,60,15)
    -- gfx.FillColor(0,0,0,200)
    -- gfx.Fill()
    gfx.BeginPath()
    gfx.FillColor(255,255,255)
    draw_stat(22, -8, 75, 13, diffNames[gameplay.difficulty + 1], gameplay.level, "%02d")
    --end diff/level

    -- gfx.TextAlign(gfx.TEXT_ALIGN_LEFT)
    -- gfx.FontSize(30)
    -- local textX = jacketWidth + 10
    -- titleWidth = songInfoWidth - jacketWidth - 20
    -- gfx.Save()
    -- x1,y1,x2,y2 = gfx.TextBounds(0,0,gameplay.title)
    -- textscale = math.min(titleWidth / x2, 1)
    -- gfx.Translate(textX, 30)
    -- gfx.Scale(textscale, textscale)
    -- gfx.Text(gameplay.title, 0, 0)
    -- gfx.Restore()
    -- x1,y1,x2,y2 = gfx.TextBounds(0,0,gameplay.artist)
    -- textscale = math.min(titleWidth / x2, 1)
    -- gfx.Save()
    -- gfx.Translate(textX, 60)
    -- gfx.Scale(textscale, textscale)
    -- gfx.Text(gameplay.artist, 0, 0)
    -- gfx.Restore()
    local title = gameplay.title .. " / " .. gameplay.artist
    local titleWidth = 520
    gfx.Save()
    gfx.TextAlign(gfx.TEXT_ALIGN_CENTER)
    gfx.FontSize(16)
    x1, y1, x2, y2 = gfx.TextBounds(0, 0, title)
    local textScale = math.min(titleWidth / x2, 1)
    gfx.Translate(360, -290)
    gfx.Scale(textScale, 1)
    gfx.Text(title, 0, 0)
    gfx.Restore()

    gfx.FillColor(255,255,255)
    gfx.FontSize(16)
    gfx.Text(string.format("%.0f", gameplay.bpm), 208, -9)

    gfx.Text(string.format("%.1f", gameplay.hispeed), 208, 9)

    gfx.BeginPath()
    gfx.FillColor(242, 146, 54)
    gfx.Rect(128, -31, 140 * gameplay.progress, 3)
    gfx.Fill()

    if game.GetButton(game.BUTTON_STA) then
      gfx.BeginPath()
    --   gfx.FillColor(20,20,20,200);
    --   gfx.Rect(100,100, songInfoWidth - 100, 20)
    --   gfx.Fill()
      gfx.FillColor(255,255,255)
      gfx.Text(string.format("HiSpeed: %.0f x %.1f = %.0f",
      gameplay.bpm, gameplay.hispeed, gameplay.bpm * gameplay.hispeed),
      0, 115)
    end
    gfx.Restore()
end

drawBestDiff = function(deltaTime,x,y)
    if not gameplay.scoreReplays[1] then return end
    gfx.BeginPath()
    gfx.FontSize(40)
    difference = score - gameplay.scoreReplays[1].currentScore
    local prefix = ""
    gfx.FillColor(255,255,255)
    if difference < 0 then
        gfx.FillColor(255,50,50)
        difference = math.abs(difference)
        prefix = "-"
    end
    gfx.Text(string.format("%s%08d", prefix, difference), x, y)
end

drawScore = function(deltaTime)
    gfx.BeginPath()
    tw, th = gfx.ImageSize(scoreBack)
    gfx.BeginPath()
    gfx.ImageRect(desw - tw + 12, -110, tw, th, scoreBack, 1, 0)

    gfx.LoadSkinFont("NovaMono.ttf")
    gfx.BeginPath()
    gfx.Translate(-5,5) -- upper right margin
    gfx.FillColor(255,255,255)
    gfx.TextAlign(gfx.TEXT_ALIGN_RIGHT + gfx.TEXT_ALIGN_TOP)
    gfx.FontSize(60)
    gfx.Text(string.format("%08d", score),desw,-86)
    --drawBestDiff(deltaTime, desw, 66)
    gfx.Translate(5,-5) -- undo margin
end

drawGauge = function(deltaTime)
    local height = 1024 * scale * 0.6
    local width = 512 * scale * 0.6
    local posy = resy / 2 - height / 2
    local posx = resx - width * (1 - math.max(introTimer - 1, 0))
    if portrait then
        width = width * 0.8
        height = height * 0.8
        posy = posy + 20
        posx = resx - width * (1 - math.max(introTimer - 1, 0))
    end
    gfx.DrawGauge(gameplay.gauge, posx, posy, width, height, deltaTime)

	--draw gauge % label
	posx = posx / scale
	posx = posx + (100 * 0.7)
	height = 880 * 0.42
	posy = posy / scale
	if portrait then
		height = height * 0.8;
	end

	posy = posy + (70 * 0.6) + height - height * gameplay.gauge
	gfx.BeginPath()
	gfx.Rect(posx-35, posy-10, 40, 20)
	gfx.FillColor(0,0,0,200)
	gfx.Fill()
	gfx.FillColor(255,255,255)
	gfx.TextAlign(gfx.TEXT_ALIGN_RIGHT + gfx.TEXT_ALIGN_MIDDLE)
	gfx.FontSize(20)
	gfx.Text(string.format("%d%%", math.floor(gameplay.gauge * 100)), posx, posy )

end

drawCombo = function(deltaTime)
    if combo == 0 then return end
    comboTimer = comboTimer + deltaTime
    local alpha = math.floor(comboTimer * 20) % 2
    alpha = (alpha * 100 + 155) / 255
    --game.Log(string.format("deltaTime: %f", deltaTime * 1000), game.LOGGER_NORMAL)

    local posx = desw / 2
    local posy = desh * critLinePos[1] - 100
    if portrait then posy = desh * critLinePos[2] - 150 end
    -- gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_MIDDLE)
    -- if gameplay.comboState == 2 then
    --     gfx.FillColor(100,255,0) --puc
    -- elseif gameplay.comboState == 1 then
    --     gfx.FillColor(255,200,0) --uc
    -- else
    --     gfx.FillColor(255,255,255) --regular
    -- end
    -- gfx.LoadSkinFont("NovaMono.ttf")
    -- gfx.FontSize(70 * math.max(comboScale, 1))
    -- comboScale = comboScale - deltaTime * 3
    -- gfx.Text(tostring(combo), posx, posy)

    -- \_ chain _/
    tw, th = gfx.ImageSize(comboBottom)
    gfx.BeginPath()
    gfx.ImageRect(posx - tw / 2, posy - th / 2, tw, th, comboBottom, alpha, 0)

    tw, th = gfx.ImageSize(comboDigits[1])
    posy = posy - th


    -- math.floor(combo / 1000) % 10
    local digit = combo % 10
    gfx.BeginPath()
    gfx.ImageRect(posx + tw, posy - th / 2, tw, th, comboDigits[digit + 1], alpha, 0)

    digit = math.floor(combo / 10) % 10
    gfx.BeginPath()
    gfx.ImageRect(posx, posy - th / 2, tw, th, comboDigits[digit + 1], alpha, 0)

    digit = math.floor(combo / 100) % 10
    gfx.BeginPath()
    gfx.ImageRect(posx - tw, posy - th / 2, tw, th, comboDigits[digit + 1], alpha, 0)

    digit = math.floor(combo / 1000) % 10
    gfx.BeginPath()
    gfx.ImageRect(posx - tw * 2, posy - th / 2, tw, th, comboDigits[digit + 1], alpha, 0)
end

drawEarlate = function(deltaTime)
    earlateTimer = math.max(earlateTimer - deltaTime,0)
    if earlateTimer == 0 then return nil end
    local alpha = math.floor(earlateTimer * 20) % 2
    alpha = (alpha * 100 + 155) / 255
    gfx.BeginPath()

    -- gfx.FontSize(35)
    -- gfx.TextAlign(gfx.TEXT_ALIGN_CENTER, gfx.TEXT_ALIGN_MIDDLE)
    -- local ypos = desh * critLinePos[1] - 150
    -- if portrait then ypos = desh * critLinePos[2] - 150 end
    -- if late then
    --     gfx.FillColor(0,255,255, alpha)
    --     gfx.Text("LATE", desw / 2, ypos)
    -- else
    --     gfx.FillColor(255,0,255, alpha)
    --     gfx.Text("EARLY", desw / 2, ypos)
    -- end

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



drawFill = function(deltaTime)
    bw,bh = gfx.ImageSize(bottomFill)
    bottomAspect = bh/bw
    bottomHeight = desw * bottomAspect
    gfx.Translate(0, (bottomHeight + 100) * math.max(introTimer - 1, 0))
    gfx.Rect(0, desh * critLinePos[2] + bottomHeight - 20, desw, 100)
    gfx.ImageRect(0, desh * critLinePos[2],  desw, bottomHeight, bottomFill, 1,0)
    gfx.Translate(0, (bottomHeight + 100) * -math.max(introTimer - 1, 0))


    gfx.BeginPath()
    tw,th = gfx.ImageSize(topFill)
    topAspect = th/tw
    topHeight = desw * topAspect
    local ar = desh/desw
    ar = ar - 1
    ar = ar / (16/9 - 1)
    ar = 1 - ar
    local yoff = ar * topHeight
    local retoff = ar * 20
    if ar < 0 then yoff = 0 end
    yoff = yoff + bottomHeight * math.max(introTimer - 1, 0)
    gfx.ImageRect(0,-yoff,desw, topHeight, topFill, 1, 0)
    gfx.BeginPath()
    return topHeight - yoff - retoff
end

drawAlerts = function(deltaTime)
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

render = function(deltaTime)
    if introTimer > 0 then
        gfx.BeginPath()
        gfx.Rect(0,0,resx,resy)
        gfx.FillColor(0,0,0, math.floor(255 * math.min(introTimer, 1)))
        gfx.Fill()
    end
    gfx.Scale(scale,scale)
    if portrait then yshift = drawFill(deltaTime) end
    gfx.Translate(0, yshift - 150 * math.max(introTimer - 1, 0))
    drawSongInfo(deltaTime)
    drawScore(deltaTime)
    gfx.Translate(0, -yshift + 150 * math.max(introTimer - 1, 0))
    drawGauge(deltaTime)
    drawEarlate(deltaTime)
    drawCombo(deltaTime)
    drawAlerts(deltaTime)
end

render_intro = function(deltaTime)
    if not game.GetButton(game.BUTTON_STA) then
        introTimer = introTimer - deltaTime
    end
    introTimer = math.max(introTimer, 0)
    return introTimer <= 0
end

render_outro = function(deltaTime, clearState)
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

update_score = function(newScore)
    score = newScore
end

update_combo = function(newCombo)
    combo = newCombo
    comboScale = 1.5
    comboTimer = 0
end

near_hit = function(wasLate) --for updating early/late display
    late = wasLate
    earlateTimer = 0.75
end

laser_alert = function(isRight) --for starting laser alert animations
    if isRight and alertTimers[2] < -1.5 then alertTimers[2] = 1.5
    elseif alertTimers[1] < -1.5 then alertTimers[1] = 1.5
    end
end