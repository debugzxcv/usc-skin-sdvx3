easing = require("easing")

gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")

game.LoadSkinSample("cursor_song")
game.LoadSkinSample("cursor_difficulty")

local resx, resy = game.GetResolution()

local levelFont = ImageFont.new("font-level", "0123456789")
local largeFont = ImageFont.new("font-large", "0123456789")
local bpmFont = ImageFont.new("number", "0123456789.") -- FIXME: font-default

-- Grades
---------
local noGrade = Image.skin("song_select/grade/nograde.png")
local grades = {
  {["min"] = 9900000, ["image"] = Image.skin("song_select/grade/s.png")},
  {["min"] = 9800000, ["image"] = Image.skin("song_select/grade/aaap.png")},
  {["min"] = 9700000, ["image"] = Image.skin("song_select/grade/aaa.png")},
  {["min"] = 9500000, ["image"] = Image.skin("song_select/grade/aap.png")},
  {["min"] = 9300000, ["image"] = Image.skin("song_select/grade/aa.png")},
  {["min"] = 9000000, ["image"] = Image.skin("song_select/grade/ap.png")},
  {["min"] = 8700000, ["image"] = Image.skin("song_select/grade/a.png")},
  {["min"] = 7500000, ["image"] = Image.skin("song_select/grade/b.png")},
  {["min"] = 6500000, ["image"] = Image.skin("song_select/grade/c.png")},
  {["min"] =       0, ["image"] = Image.skin("song_select/grade/d.png")},
}

function lookup_grade_image(difficulty)
  local gradeImage = noGrade
  if difficulty.scores[1] ~= nil then
		local highScore = difficulty.scores[1]
    for i, v in ipairs(grades) do
      if highScore.score >= v.min then
        gradeImage = v.image
        break
      end
    end
  end
  return { image = gradeImage, flicker = (gradeImage == grades[1].image) }
end

-- Medals
---------
local noMedal = Image.skin("song_select/medal/nomedal.png")
local medals = {
  Image.skin("song_select/medal/played.png"),
  Image.skin("song_select/medal/clear.png"),
  Image.skin("song_select/medal/hard.png"),
  Image.skin("song_select/medal/uc.png"),
  Image.skin("song_select/medal/puc.png")
}

function lookup_medal_image(difficulty)
  local medalImage = noMedal
  local flicker = false
  if difficulty.scores[1] ~= nil then
    if difficulty.topBadge ~= 0 then
      medalImage = medals[difficulty.topBadge]
      if difficulty.topBadge >= 3 then -- hard
        flicker = true
      end
    end
  end
  return { image = medalImage, flicker = flicker }
end

-- Lookup difficulty
function lookup_difficulty(diffs, diff)
  local diffIndex = nil
  for i, v in ipairs(diffs) do
    if v.difficulty + 1 == diff then
      diffIndex = i
    end
  end
  local difficulty = nil
  if diffIndex ~= nil then
    difficulty = diffs[diffIndex]
  end
  return difficulty
end

-- JacketCache class
--------------------
JacketCache = {}
JacketCache.new = function()
  local this = {
    cache = {},
    images = {
      loading = Image.skin("song_select/jacket_loading.png"),
    }
  }
  setmetatable(this, {__index = JacketCache})
  return this
end

JacketCache.get = function(this, path)
  local jacket = this.cache[path]
  if not jacket or jacket == this.images.loading.image then
    jacket = gfx.LoadImageJob(path, this.images.loading.image)
    this.cache[path] = jacket
  end
  return Image.wrap(jacket)
end


-- SongData class
-----------------
SongData = {}
SongData.new = function(jacketCache)
  local this = {
    selectedIndex = 1,
    selectedDifficulty = 0,
    memo = Memo.new(),
    jacketCache = jacketCache,
    images = {
      dataBg = Image.skin("song_select/data_bg.png"),
      cursor = Image.skin("song_select/level_cursor.png"),
      none = Image.skin("song_select/level/none.png"),
      difficulties = {
        Image.skin("song_select/level/novice.png"),
        Image.skin("song_select/level/advanced.png"),
        Image.skin("song_select/level/exhaust.png"),
        Image.skin("song_select/level/gravity.png")
      },
    }
  }

  setmetatable(this, {__index = SongData})
  return this
end

SongData.render = function(this, deltaTime)
  local song = songwheel.songs[this.selectedIndex]
  if not song then return end

  -- Lookup difficulty
  local diff = song.difficulties[this.selectedDifficulty]
  if diff == nil then diff = song.difficulties[1] end

  -- Draw the background
  this.images.dataBg:draw({ x = 360, y = 176 })

  -- Draw the jacket
  local jacket = this.jacketCache:get(diff.jacketPath)
  jacket:draw({ x = 18, y = 58, w = 200, h = 200, anchor_h = Image.ANCHOR_LEFT, anchor_v = Image.ANCHOR_TOP })

  -- Draw the title
  local title = this.memo:memoize(string.format("title_%s", song.id), function ()
    gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")
    return gfx.CreateLabel(song.title, 24, 0)
  end)
  this:draw_title_artist(title, 245, 133, 390)

  -- Draw the artist
  local artist = this.memo:memoize(string.format("artist_%s", song.id), function ()
    gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")
    return gfx.CreateLabel(song.artist, 18, 0)
  end)
  this:draw_title_artist(artist, 245, 170, 390)

  -- Draw the effector
  local effector = this.memo:memoize(string.format("eff_%s_%s", song.id, diff.id), function ()
    gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")
    return gfx.CreateLabel(diff.effector, 16, 0)
  end)
  gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_BASELINE)
  gfx.FillColor(255, 255, 255, 255)
  gfx.DrawLabel(effector, 375, 77, 320)

  -- Draw the illustrator
  if diff.illustrator then
    local illustrator = this.memo:memoize(string.format("ill_%s_%s", song.id, diff.id), function ()
      gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")
      return gfx.CreateLabel(diff.illustrator, 16, 0)
    end)
    gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_BASELINE)
    gfx.FillColor(255, 255, 255, 255)
    gfx.DrawLabel(illustrator, 375, 100, 320)
  end

  -- Draw the bpm
  -- FIXME: dot and dash was not rendered
  bpmFont:draw(song.bpm, 512, 64, 1, gfx.TEXT_ALIGN_LEFT, gfx.TEXT_ALIGN_MIDDLE)
  -- gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")
  -- gfx.FontSize(32)
  -- gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_BASELINE)
  -- gfx.FillColor(255, 255, 255, 255)
  -- gfx.Text(song.bpm, 510, 73)

  -- Draw the hi-score
  local hiScore = diff.scores[1]
  if hiScore then
    -- FIXME: large / small font
    local scoreText = string.format("%08d", hiScore.score)
    levelFont:draw(scoreText, 362, 220, 1, gfx.TEXT_ALIGN_LEFT, gfx.TEXT_ALIGN_MIDDLE)
    -- local scoreHiText = string.format("%05d", math.floor(hiScore.score / 1000))
    -- levelFont:draw(scoreHiText, 362, 220, 1, gfx.TEXT_ALIGN_LEFT, gfx.TEXT_ALIGN_MIDDLE)
    -- local scoreLoText = string.format("%03d", hiScore.score % 1000)
    -- bpmFont:draw(scoreLoText, 470, 220, 1, gfx.TEXT_ALIGN_LEFT, gfx.TEXT_ALIGN_MIDDLE)
  end

  -- Draw the grade and medal
  local grade = lookup_grade_image(diff)
  grade.image:draw({ x = 554, y = 220, alpha = grade.flicker and glowState and 0.9 or 1 })
  local medal = lookup_medal_image(diff)
  medal.image:draw({ x = 600, y = 220, alpha = medal.flicker and glowState and 0.9 or 1 })

  for i = 1, 4 do
    local d = lookup_difficulty(song.difficulties, i)
    this:draw_difficulty(i - 1, d, jacket)
  end

  this:draw_cursor(diff.difficulty)
end

SongData.draw_title_artist = function(this, label, x, y, maxWidth)
  gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_BASELINE)
  gfx.FillColor(55, 55, 55, 64)
  gfx.DrawLabel(label, x + 2, y + 2, maxWidth)
  gfx.FillColor(55, 55, 55, 255)
  gfx.DrawLabel(label, x, y, maxWidth)
end

SongData.draw_difficulty = function(this, index, diff, jacket)
  local x = 344
  local y = 280

  -- Draw the jacket icon
  local jacket = this.jacketCache.images.loading
  if diff ~= nil then jacket = this.jacketCache:get(diff.jacketPath) end
  jacket:draw({ x = 17 + index * 52, y = 262, w = 46, h = 46, anchor_h = Image.ANCHOR_LEFT, anchor_v = Image.ANCHOR_TOP })

  if diff == nil then
    this.images.none:draw({ x = x + index * 96, y = y })
  else
    -- Draw the background
    this.images.difficulties[diff.difficulty + 1]:draw({ x = x + index * 96, y = y })
    -- Draw the level
    local levelText = string.format("%02d", diff.level)
    largeFont:draw(levelText, x + index * 96 - 4, y - 6, 1, gfx.TEXT_ALIGN_CENTER, gfx.TEXT_ALIGN_MIDDLE)
  end
end

SongData.draw_cursor = function(this, index)
  local x = 344
  local y = 280

  -- Draw the cursor
  this.images.cursor:draw({ x = x + index * 96, y = y - 3 })
end

SongData.set_index = function(this, newIndex)
  this.selectedIndex = newIndex
end

SongData.set_difficulty = function(this, newDiff)
  this.selectedDifficulty = newDiff
end


-- SongTable class
------------------
SongTable = {}
SongTable.new = function(jacketCache)
  local this = {
    cols = 3,
    rows = 3,
    selectedIndex = 1,
    selectedDifficulty = 0,
    rowOffset = 0, -- song index offset of top-left song in page
    cursorPos = 0, -- cursor position in page [0..cols * rows)
    displayCursorPos = 0,
    cursorAnim = 0,
    cursorAnimTotal = 0.1,
    memo = Memo.new(),
    jacketCache = jacketCache,
    images = {
      matchingBg = Image.skin("song_select/matching_bg.png"),
      scoreBg = Image.skin("song_select/score_bg.png"),
      force = Image.skin("song_select/force.png"),
      cursor = Image.skin("song_select/cursor.png"),
      cursorText = Image.skin("song_select/cursor_text.png"),
      cursorDiamond = Image.skin("song_select/cursor_diamond.png"),
      cursorDiamondWire = Image.skin("song_select/cursor_diamond_wire.png"),
      plates = {
        Image.skin("song_select/plate/novice.png"),
        Image.skin("song_select/plate/advanced.png"),
        Image.skin("song_select/plate/exhaust.png"),
        Image.skin("song_select/plate/gravity.png")
      }
    }
  }
  setmetatable(this, {__index = SongTable})
  return this
end

SongTable.calc_cursor_point = function(this, pos)
  local col = pos % this.cols
  local row = math.floor((pos) / this.cols)
  local x = 154 + col * this.images.cursor.w
  local y = 478 + row * this.images.cursor.h
  return x, y
end

SongTable.set_index = function(this, newIndex)
  if newIndex ~= this.selectedIndex then
    game.PlaySample("cursor_song")
  end

  local delta = newIndex - this.selectedIndex
  if delta < -1 or delta > 1 then
    local newOffset = newIndex - 1
    this.rowOffset = math.floor((newIndex - 1) / this.cols) * this.cols
    this.cursorPos = (newIndex - 1) - this.rowOffset
    this.displayCursorPos = this.cursorPos
  else
    local newCursorPos = this.cursorPos + delta

    if newCursorPos < 0 then
      -- scroll up
      this.rowOffset = this.rowOffset - this.cols
      if this.rowOffset < 0 then
        -- this.rowOffset = math.floor(#songwheel.songs / this.cols)
      end
      newCursorPos = newCursorPos + this.cols
    elseif newCursorPos >= this.cols * this.rows then
      -- scroll down
      this.rowOffset = this.rowOffset + this.cols
      newCursorPos = newCursorPos - this.cols
    else
      -- no scroll, move cursor in page
    end
    if this.cursorAnim > 0 then
      this.displayCursorPos = easing.outQuad(0.5 - this.cursorAnim, this.displayCursorPos, this.cursorPos - this.displayCursorPos, 0.5)
    end
    this.cursorPos = newCursorPos
    this.cursorAnim = this.cursorAnimTotal
  end
  this.selectedIndex = newIndex
end

SongTable.set_difficulty = function(this, newDiff)
  if newDiff ~= this.selectedDifficulty then
    game.PlaySample("cursor_difficulty")
  end
  this.selectedDifficulty = newDiff
end

SongTable.render = function(this, deltaTime)
  this:draw_songs()
  this:draw_cursor(deltaTime)
end

SongTable.draw_songs = function(this)
  for i = 1, this.cols * this.rows do
    if this.rowOffset + i <= #songwheel.songs then
      this:draw_song(i - 1, this.rowOffset + i)
    end
  end
end

-- Draw the song plate
SongTable.draw_song = function(this, pos, songIndex)
  local song = songwheel.songs[songIndex]
  if not song then return end

  -- Lookup difficulty
  local diff = song.difficulties[this.selectedDifficulty]
  if diff == nil then diff = song.difficulties[1] end

  local x, y = this:calc_cursor_point(pos)
  x = x + 4
  y = y + 16

  -- Draw the background
  gfx.FillColor(255, 255, 255)
  this.images.scoreBg:draw({ x = x + 72, y = y + 16 })
  if diff.force and diff.force > 0 then
    this.images.matchingBg:draw({ x = x + 72, y = y - 62 })
  end
  this.images.plates[diff.difficulty + 1]:draw({ x = x, y  = y })

  -- Draw the jacket
  local jacket = this.jacketCache:get(diff.jacketPath)
  jacket:draw({ x = x - 24, y = y - 21, w = 122, h = 122 })

  -- Draw the title
  local title = this.memo:memoize(string.format("title_%s", song.id), function ()
    gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")
    return gfx.CreateLabel(song.title, 14, 0)
  end)
  gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_BASELINE)
  gfx.DrawLabel(title, x - 22, y + 53, 125)

  -- Draw the grade and medal
  local grade = lookup_grade_image(diff)
  grade.image:draw({ x = x + 78, y = y - 23, alpha = grade.flicker and glowState and 0.9 or 1 })

  local medal = lookup_medal_image(diff)
  medal.image:draw({ x = x + 78, y = y + 10, alpha = medal.flicker and glowState and 0.9 or 1 })

  -- Draw the level
  local levelText = string.format("%02d", diff.level)
  levelFont:draw(levelText, x + 72, y + 56, 1, gfx.TEXT_ALIGN_CENTER, gfx.TEXT_ALIGN_MIDDLE)

  -- Draw the volforce
  if diff.force and diff.force > 0 then
    local forceText = string.format("%d", math.floor(diff.force * 100))
    bpmFont:draw(forceText, x + 76, y - 60, 1, gfx.TEXT_ALIGN_CENTER, gfx.TEXT_ALIGN_MIDDLE)
  end

  if diff.forceInTotal then
    this.images.force:draw({x = x - 75, y = y - 60, w = 59, h = 59 })
  end
end

-- Draw the song cursor
SongTable.draw_cursor = function(this, deltaTime)
  gfx.Save()

  local pos = this.displayCursorPos
  if this.cursorAnim > 0 then
    this.cursorAnim = this.cursorAnim - deltaTime
    if this.cursorAnim <= 0 then
      this.displayCursorPos = this.cursorPos
      pos = this.cursorPos
    else
      pos = easing.outQuad(this.cursorAnimTotal - this.cursorAnim, this.displayCursorPos, this.cursorPos - this.displayCursorPos, this.cursorAnimTotal)
    end
  end

  local x, y = this:calc_cursor_point(pos)
  gfx.FillColor(255, 255, 255)

  local t = currentTime % 1

  -- scroll text
  gfx.Scissor(
    x - this.images.cursor.w / 2, y - (this.images.cursor.h - 30) / 2,
    this.images.cursor.w, this.images.cursor.h - 30)
  local offset = (currentTime * 50) % 290
  local alpha = glowState and 0.8 or 1
  this.images.cursorText:draw({ x = x + 96, y = y + offset, alpha = alpha })
  this.images.cursorText:draw({ x = x + 96, y = y - 290 + offset, alpha = alpha })
  this.images.cursorText:draw({ x = x - 96, y = y + offset, alpha = alpha })
  this.images.cursorText:draw({ x = x - 96, y = y - 290 + offset, alpha = alpha })
  gfx.ResetScissor()

  -- diamong wireframe
  local h = (this.images.cursorDiamondWire.h * 1.5) * easing.outQuad(t * 2, 0, 1, 1)
  this.images.cursorDiamondWire:draw({ x = x, y = y, w = this.images.cursorDiamondWire.w * 1.5, h = h, alpha = 0.5 })

  -- ghost cursor
  alpha = easing.outSine(t, 1, -1, 1)
  h = this.images.cursor.h * easing.outSine(t, 0, 1, 1)
  this.images.cursor:draw({ x = x, y = y, h = h, alpha = alpha })

  -- concrete cursor
  -- local w = this.images.cursor.w * easing.outSine(t, 1, 0.05, 0.5)
  this.images.cursor:draw({ x = x, y = y, alpha = glowState and 0.8 or 1 })

  -- diamond knot
  gfx.GlobalCompositeOperation(gfx.BLEND_OP_LIGHTER)
  this.images.cursorDiamond:draw({ x = x + 100, y = y, alpha = 1 })
  this.images.cursorDiamond:draw({ x = x - 100, y = y, alpha = 1 })

  local s = this.images.cursorDiamond.w / 1.5
  this.images.cursorDiamond:draw({ x = x + 90 + easing.outQuad(t, 0, -4, 0.5), y = y, w = s, h = s, alpha = 0.5 })
  this.images.cursorDiamond:draw({ x = x - 90 - easing.outQuad(t, 0, -4, 0.5), y = y, w = s, h = s, alpha = 0.5 })

  gfx.Restore()
end


-- main
-------

local jacketCache = JacketCache.new()
local songData = SongData.new(jacketCache)
local songTable = SongTable.new(jacketCache)

glowState = false
currentTime = 0

-- Callback
get_page_size = function()
  return 12
end

searchIndex = 1
soffset = 0
searchText = gfx.CreateLabel("", 5, 0)

draw_search = function(x,y,w,h)
  soffset = soffset + (searchIndex) - (songwheel.searchInputActive and 0 or 1)
  if searchIndex ~= (songwheel.searchInputActive and 0 or 1) then
      game.PlaySample("woosh")
  end
  searchIndex = songwheel.searchInputActive and 0 or 1

  gfx.BeginPath()
  local bgfade = 1 - (searchIndex + soffset)
  --if not songwheel.searchInputActive then bgfade = soffset end
  gfx.FillColor(0,0,0,math.floor(200 * bgfade))
  gfx.Rect(0,0,resx,resy)
  gfx.Fill()
  gfx.ForceRender()
  local xpos = x + (searchIndex + soffset)*w
  gfx.UpdateLabel(searchText ,string.format("Search: %s",songwheel.searchText), 30, 0)
  gfx.BeginPath()
  gfx.RoundedRect(xpos,y,w,h,h/2)
  gfx.FillColor(30,30,30)
  gfx.StrokeColor(0,128,255)
  gfx.StrokeWidth(1)
  gfx.Fill()
  gfx.Stroke()
  gfx.BeginPath();
  gfx.LoadSkinFont("segoeui.ttf");
  gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_MIDDLE);
  gfx.DrawLabel(searchText, xpos+10,y+(h/2), w-20)
end

-- Callback
render = function(deltaTime)
  currentTime = currentTime + deltaTime

  if ((math.floor(currentTime * 1000) % 100) < 50) then
    glowState = false
  else
    glowState = true
  end

  gfx.ResetTransform()

  local desw = 720
  local desh = 1280
  local scale = resy / desh

  local xshift = (resx - desw * scale) / 2
  local yshift = (resy - desh * scale) / 2

  gfx.Translate(xshift, yshift)
  gfx.Scale(scale, scale)

  songData:render(deltaTime)
  songTable:render(deltaTime)

  if totalForce then
    local forceText = string.format("%.2f", totalForce)
    -- gfx.SetImageTint(255, 254, 2)
    bpmFont:draw(forceText, 140, 353, 1, gfx.TEXT_ALIGN_LEFT, gfx.TEXT_ALIGN_MIDDLE)
  end

  -- Draw the search status
	if songwheel.searchStatus then
    gfx.BeginPath()
    gfx.LoadSkinFont("segoeui.ttf")
		gfx.FillColor(255, 255, 255)
		gfx.FontSize(20)
		gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_BOTTOM)
		gfx.Text(songwheel.searchStatus, 3, desh)
  end

  soffset = soffset * 0.8
  draw_search(120, 5, 600, 40)
end

-- Callback
set_index = function(newIndex)
  songData:set_index(newIndex)
  songTable:set_index(newIndex)
end

-- Callback
set_diff = function(newDiff)
  songData:set_difficulty(newDiff)
  songTable:set_difficulty(newDiff)
end

-- force calculation
--------------------
totalForce = nil

local badgeRates = {
	0.5,  -- Played
	1.0,  -- Cleared
	1.02, -- Hard clear
	1.04, -- UC
	1.1   -- PUC
}

local gradeRates = {
	{["min"] = 9900000, ["rate"] = 1.05}, -- S
	{["min"] = 9800000, ["rate"] = 1.02}, -- AAA+
	{["min"] = 9700000, ["rate"] = 1},    -- AAA
	{["min"] = 9500000, ["rate"] = 0.97}, -- AA+
	{["min"] = 9300000, ["rate"] = 0.94}, -- AA
	{["min"] = 9000000, ["rate"] = 0.91}, -- A+
	{["min"] = 8700000, ["rate"] = 0.88}, -- A
	{["min"] = 7500000, ["rate"] = 0.85}, -- B
	{["min"] = 6500000, ["rate"] = 0.82}, -- C
	{["min"] =       0, ["rate"] = 0.8}   -- D
}

calculate_force = function(diff)
	if #diff.scores < 1 then
		return 0
	end
	local score = diff.scores[1]
	local badgeRate = badgeRates[diff.topBadge]
	local gradeRate
    for i, v in ipairs(gradeRates) do
      if score.score >= v.min then
        gradeRate = v.rate
		break
      end
    end
	return math.floor((diff.level * 2) * (score.score / 10000000) * gradeRate * badgeRate) / 100
end

-- callback
songs_changed = function(withAll)
  local diffsById = {}
	local diffs = {}
	for i = 1, #songwheel.allSongs do
		local song = songwheel.allSongs[i]
		for j = 1, #song.difficulties do
			local diff = song.difficulties[j]
			diff.force = calculate_force(diff)
      table.insert(diffs, diff)
      diffsById[diff.id] = diff
		end
	end

  table.sort(diffs, function (l, r)
		return l.force > r.force
	end)

  totalForce = 0
	for i = 1, 50 do
		if diffs[i] then
      totalForce = totalForce + diffs[i].force
      diffs[i].forceInTotal = true
		end
  end

  for i = 1, #songwheel.songs do
    local song = songwheel.songs[i]
    for j = 1, #song.difficulties do
      local diff = song.difficulties[j]
      local newDiff = diffsById[diff.id]
      song.difficulties[j] = newDiff
    end
  end
end
