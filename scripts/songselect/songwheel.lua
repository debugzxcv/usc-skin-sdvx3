require("easing")

gfx.LoadSkinFont("UDDigiKyokashoNP-B.ttf")
gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")

game.LoadSkinSample("cursor_song")
game.LoadSkinSample("cursor_difficulty")

local levelFont = ImageFont.new("font-level", "0123456789")
local largeFont = ImageFont.new("font-large", "0123456789")
local bpmFont = ImageFont.new("number", "0123456789.") -- FIXME: font-default

local noGrade = Image.skin("song_select/grade/nograde.png", 0)
local grades = {
  {["min"] = 9900000, ["image"] = Image.skin("song_select/grade/s.png", 0)},
  {["min"] = 9800000, ["image"] = Image.skin("song_select/grade/aaap.png", 0)},
  {["min"] = 9700000, ["image"] = Image.skin("song_select/grade/aaa.png", 0)},
  {["min"] = 9500000, ["image"] = Image.skin("song_select/grade/ap.png", 0)},
  {["min"] = 9300000, ["image"] = Image.skin("song_select/grade/aa.png", 0)},
  {["min"] = 9000000, ["image"] = Image.skin("song_select/grade/ap.png", 0)},
  {["min"] = 8700000, ["image"] = Image.skin("song_select/grade/a.png", 0)},
  {["min"] = 7500000, ["image"] = Image.skin("song_select/grade/b.png", 0)},
  {["min"] = 6500000, ["image"] = Image.skin("song_select/grade/c.png", 0)},
  {["min"] =       0, ["image"] = Image.skin("song_select/grade/d.png", 0)},
}

local noMedal = Image.skin("song_select/medal/nomedal.png", 0)
local medals = {
  Image.skin("song_select/medal/played.png", 0),
  Image.skin("song_select/medal/clear.png", 0),
  Image.skin("song_select/medal/hard.png", 0),
  Image.skin("song_select/medal/uc.png", 0),
  Image.skin("song_select/medal/puc.png", 0)
}

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
      loading = Image.skin("song_select/jacket_loading.png", 0),
    }
  }

  setmetatable(this, {__index = JacketCache})
  return this
end

JacketCache.get = function(this, songId, diffId, path)
  local songCache = this.cache[songId]
  if not songCache then
    songCache = {}
    this.cache[songId] = songCache
  end

  local jacket = songCache[diffId]
  if not jacket or jacket == this.images.loading.image then
    jacket = gfx.LoadImageJob(path, this.images.loading.image)
    songCache[diffId] = jacket
  end
  return jacket
end


-- SongData class
-----------------
SongData = {}
SongData.new = function(jacketCache)
  local this = {
    selectedIndex = 1,
    selectedDifficulty = 0,
    cache = {},
    jacketCache = jacketCache,
    images = {
      dataBg = Image.skin("song_select/data_bg.png", 0),
      cursor = Image.skin("song_select/level_cursor.png", 0),
      none = Image.skin("song_select/level/none.png", 0),
      difficulties = {
        Image.skin("song_select/level/novice.png", 0),
        Image.skin("song_select/level/advanced.png", 0),
        Image.skin("song_select/level/exhaust.png", 0),
        Image.skin("song_select/level/gravity.png", 0)
      },
    }
  }

  setmetatable(this, {__index = SongData})
  return this
end

SongData.render = function(this, deltaTime)
  local song = songwheel.songs[this.selectedIndex]

  -- Initialize song cache
  if not this.cache[song.id] then
    this.cache[song.id] = {}
  end

  -- Lookup difficulty
  local diff = lookup_difficulty(song.difficulties, this.selectedDifficulty)
  if diff == nil then diff = song.difficulties[#song.difficulties] end

  -- Draw the background
  this.images.dataBg:draw(360, 176, 1, 0)

  -- Draw the jacket
  local jacket = this.jacketCache:get(song.id, diff.id, diff.jacketPath)
  gfx.FillColor(255, 255, 255, 1)
  gfx.BeginPath()
  local js = 200
  gfx.ImageRect(18, 58, js, js, jacket, 1, 0)

  -- Draw the title
  local title = this.cache[song.id]["title"]
  if not title then
    -- gfx.FontFace("rounded-mplus-1c-bold.ttf")
    gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")
    title = gfx.CreateLabel(song.title, 24, 0)
    this.cache[song.id]["title"] = title
  end
  gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_BASELINE)
  gfx.FillColor(55, 55, 55, 64)
  gfx.DrawLabel(title, 247, 135, 400)
  gfx.FillColor(55, 55, 55, 255)
  gfx.DrawLabel(title, 245, 133, 400)

  -- Draw the artist
  local artist = this.cache[song.id]["artist"]
  if not artist then
    gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")
    artist = gfx.CreateLabel(song.artist, 18, 0)
    this.cache[song.id]["artist"] = artist
  end
  gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_BASELINE)
  gfx.FillColor(55, 55, 55, 64)
  gfx.DrawLabel(artist, 247, 172, 400)
  gfx.FillColor(55, 55, 55, 255)
  gfx.DrawLabel(artist, 245, 170, 400)

  -- Draw the effector
  local effectorKey = string.format("effector_%d", diff.id)
  local effector = this.cache[song.id][effectorKey]
  if not effector then
    gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")
    effector = gfx.CreateLabel(diff.effector, 16, 0)
    this.cache[song.id][effectorKey] = effector
  end
  gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_BASELINE)
  gfx.FillColor(255, 255, 255, 255)
  gfx.DrawLabel(effector, 375, 77, 400)

  -- Draw the bpm
  -- FIXME: dot and dash was not rendered
  levelFont:draw(song.bpm, 512, 63, 1, gfx.TEXT_ALIGN_LEFT, gfx.TEXT_ALIGN_MIDDLE)
  -- gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")
  -- gfx.FontSize(32)
  -- gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_BASELINE)
  -- gfx.FillColor(255, 255, 255, 255)
  -- gfx.Text(song.bpm, 510, 73)

  for i = 1, 4 do
    local d = lookup_difficulty(song.difficulties, i)
    local jacket = this.jacketCache.images.loading.image
    if d ~= nil then jacket = this.jacketCache:get(song.id, d.id, d.jacketPath) end
    this:render_difficulty(i - 1, d, jacket)
  end

  this:render_cursor(diff.difficulty)
end

SongData.render_difficulty = function(this, index, diff, jacket)
  local x = 344
  local y = 280

  -- Draw the jacket icon
  gfx.FillColor(255, 255, 255, 1)
  gfx.BeginPath()
  local js = 46
  gfx.ImageRect(17 + index * 52, 262, js, js, jacket, 1, 0)

  if diff == nil then
    this.images.none:draw(x + index * 96, y, 1, 0)
  else
    -- Draw the background
    this.images.difficulties[diff.difficulty + 1]:draw(x + index * 96, y, 1, 0)
    -- Draw the level
    local levelText = string.format("%02d", diff.level)
    largeFont:draw(levelText, x + index * 96 - 4, y - 6, 1, gfx.TEXT_ALIGN_CENTER, gfx.TEXT_ALIGN_MIDDLE)
  end
end

SongData.render_cursor = function(this, index)
  local x = 344
  local y = 280

  --  Draw the cursor
  this.images.cursor:draw(x + index * 96, y - 3, 1, 0)
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
    cache = {},
    jacketCache = jacketCache,
    images = {
      scoreBg = Image.skin("song_select/score_bg.png", 0),
      cursor = Image.skin("song_select/cursor.png", 0),
      plates = {
        Image.skin("song_select/plate/novice.png", 0),
        Image.skin("song_select/plate/advanced.png", 0),
        Image.skin("song_select/plate/exhaust.png", 0),
        Image.skin("song_select/plate/gravity.png", 0)
      }
    }
  }
  setmetatable(this, {__index = SongTable})
  return this
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
    this.cursorPos = newCursorPos
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
  this:render_songs()
  this:render_cursor()
end

SongTable.render_songs = function(this)
  for i = 1, this.cols * this.rows do
    if this.rowOffset + i <= #songwheel.songs then
      this:render_song(i - 1, this.rowOffset + i)
    end
  end
end

-- Draw the song plate
SongTable.render_song = function(this, pos, songIndex)
  local song = songwheel.songs[songIndex]

  -- Initialize song cache
  if not this.cache[song.id] then
    this.cache[song.id] = {}
  end

  -- Lookup difficulty
  local diff = lookup_difficulty(song.difficulties, this.selectedDifficulty)
  if diff == nil then diff = song.difficulties[#song.difficulties] end

  local col = pos % this.cols
  local row = math.floor(pos / this.cols)
  local x = 154 + col * this.images.cursor.w + 4
  local y = 478 + row * this.images.cursor.h + 16

  -- Draw the background
  gfx.FillColor(255, 255, 255)
  this.images.scoreBg:draw(x + 72, y + 16, 1, 0)
  this.images.plates[diff.difficulty + 1]:draw(x, y, 1, 0)

  -- Draw the jacket
  local jacket = this.jacketCache:get(song.id, diff.id, diff.jacketPath)
  gfx.FillColor(255, 255, 255, 1)
  gfx.BeginPath()
  local js = 122
  gfx.ImageRect(x - 24 - js / 2, y - 21 - js / 2, js, js, jacket, 1, 0)

  -- Draw the title
  local title = this.cache[song.id]["title"]
  if not title then
    -- gfx.FontFace("rounded-mplus-1c-bold.ttf")
    gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")
    title = gfx.CreateLabel(song.title, 14, 0)
    this.cache[song.id]["title"] = title
  end
  gfx.BeginPath()
  gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_BASELINE)
  gfx.DrawLabel(title, x - 22, y + 53, 125)

  -- Draw the grade
  local gradeImage = noGrade
  local medalImage = noMedal
  if diff.scores[1] ~= nil then
		local highScore = diff.scores[1]
    for i, v in ipairs(grades) do
      if highScore.score >= v.min then
        gradeImage = v.image
        break
      end
    end
    if diff.topBadge ~= 0 then
      medalImage = medals[diff.topBadge]
    end
  end
  gradeImage:draw(x + 78, y - 23, 1, 0)
  medalImage:draw(x + 78, y + 10, 1, 0)

  -- Draw the level
  local levelText = string.format("%02d", diff.level)
  levelFont:draw(levelText, x + 72, y + 56, 1, gfx.TEXT_ALIGN_CENTER, gfx.TEXT_ALIGN_MIDDLE)
end

-- Draw the song cursor
SongTable.render_cursor = function(this)
  local col = this.cursorPos % this.cols
  local row = math.floor(this.cursorPos / this.cols)
  local x = 154 + col * this.images.cursor.w
  local y = 478 + row * this.images.cursor.h
  gfx.FillColor(255, 255, 255)
  this.images.cursor:draw(x, y, 1, 0)
end

local wheelSize = 12
get_page_size = function()
    return wheelSize
end

-- main
-------

local jacketCache = JacketCache.new()
local songData = SongData.new(jacketCache)
local songTable = SongTable.new(jacketCache)

-- Callback
render = function(deltaTime)
  gfx.ResetTransform()

  local resx, resy = game.GetResolution()
  local desw = 720
  local desh = 1280
  local scale = resy / desh

  local xshift = (resx - desw * scale) / 2
  local yshift = (resy - desh * scale) / 2

  gfx.Translate(xshift, yshift)
  gfx.Scale(scale, scale)

  songData:render(deltaTime)
  songTable:render(deltaTime)
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
