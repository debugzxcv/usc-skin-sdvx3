require("easing")

gfx.LoadSkinFont("UDDigiKyokashoNP-B.ttf")
gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")

game.LoadSkinSample("cursor_song")

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

-- SongTable class
SongTable = {}
SongTable.new = function()
  local this = {
    cols = 3,
    rows = 3,
    selectedIndex = 1,
    selectedDifficulty = 0,
    rowOffset = 0, -- index of top-left song in page
    cursorPos = 0, -- cursor position in page [0..cols * rows)
    cache = {},
    images = {
      jacketLoading = Image.skin("song_select/jacket_loading.png", 0),
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
  this.selectedIndex = newIndex
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
    this.cache[song.id]["jacket"] = {}
  end

  -- Lookup difficulty
  local diffIndex = 1
  for i, v in ipairs(song.difficulties) do
    if v.difficulty == this.selectedDifficulty then
      diffIndex = i
    end
  end
  local diff = song.difficulties[diffIndex]

  local col = pos % this.cols
  local row = math.floor(pos / this.cols)
  local x = 154 + col * this.images.cursor.w + 4
  local y = 478 + row * this.images.cursor.h + 16

  -- Draw the background
  gfx.FillColor(255, 255, 255)
  this.images.scoreBg:draw(x + 72, y + 16, 1, 0)
  this.images.plates[diff.difficulty + 1]:draw(x, y, 1, 0)

  -- Draw the jacket
  local jacket = this.cache[song.id]["jacket"][diff.id]
  if not jacket or jacket == this.images.jacketLoading.image then
    jacket = gfx.LoadImageJob(diff.jacketPath, this.images.jacketLoading.image)
    this.cache[song.id]["jacket"][diff.id] = jacket
  end
  gfx.FillColor(255, 255, 255, 1)
  gfx.BeginPath()
  local js = 122
  gfx.ImageRect(x - 24 - js / 2, y - 21 - js / 2, js, js, jacket, 1, 0)

  -- Draw the title
  local title = this.cache[song.id]["title"]
  if not title then
    gfx.FontFace("rounded-mplus-1c-bold.ttf")
    gfx.TextAlign(gfx.TEXT_ALIGN_CENTER or gfx.TEXT_ALIGN_BASELINE)
    title = gfx.CreateLabel(song.title, 14, 0)
    this.cache[song.id]["title"] = title
  end
  gfx.DrawLabel(title, x - 22, y + 63, 125)

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

songTable = SongTable.new()

-- Callback
render = function(deltaTime)
  songTable:render(deltaTime)
end

-- Callback
set_index = function(newIndex)
  songTable:set_index(newIndex)
end

-- Callback
set_diff = function(newDiff)
end
