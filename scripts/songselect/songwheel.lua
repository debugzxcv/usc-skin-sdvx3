require("easing")

gfx.LoadSkinFont("UDDigiKyokashoNP-B.ttf")
gfx.LoadSkinFont("rounded-mplus-1c-bold.ttf")

game.LoadSkinSample("cursor_song")



-- SongTable class
SongTable = {}
SongTable.new = function()
  local this = {
    cols = 3,
    rows = 3,
    selectedIndex = 1,
    selectedDifficulty = 0,
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
  this.selectedIndex = newIndex
end

SongTable.render = function(this, deltaTime)
  for i = 1, #songwheel.songs do
    this:render_song(i)
  end
  this:render_cursor()
end

-- Draw the song plate
SongTable.render_song = function(this, index)
  local song = songwheel.songs[index]

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

  local col = (index - 1) % this.cols
  local row = math.floor((index - 1) / this.cols)
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
end

-- Draw the song cursor
SongTable.render_cursor = function(this)
  local col = (this.selectedIndex - 1) % this.cols
  local row = math.floor((this.selectedIndex - 1) / this.cols)
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
