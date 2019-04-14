gfx.LoadSkinFont("segoeui.ttf")

-- Image class
--------------
Image = {}
Image.skin = function(filename, imageFlags)
  local this = {
    image = gfx.CreateSkinImage(filename, imageFlags)
  }
  local w, h = gfx.ImageSize(this.image)
  this.w = w
  this.h = h
  setmetatable(this, {__index = Image})
  return this
end

-- anchor point is center
Image.draw = function(this, x, y, alpha, angle)
  this:drawSize(x, y, this.w, this.h, alpha, angle)
end

Image.drawSize = function(this, x, y, w, h, alpha, angle)
  gfx.BeginPath()
  gfx.ImageRect(x - w / 2, y - h / 2, w, h, this.image, alpha, angle)
end

-- ImageFont class
------------------
ImageFont = {}
ImageFont.new = function(path, chars)
  local this = {
    images = {}
  }
  -- load character images
  for i = 1, chars:len() do
    local c = chars:sub(i, i)
    local image = Image.skin(string.format("%s/%s.png", path, c), 0)
    this.images[c] = image
  end
  -- use size of first char as font size
  local w, h = gfx.ImageSize(this.images[chars:sub(1, 1)].image)
  this.w = w
  this.h = h

  setmetatable(this, {__index = ImageFont})
  return this
end
ImageFont.draw = function(this, text, x, y, alpha, textFlags)
  local totalW = text:len() * this.w

  -- adjust horizontal alignment
  if textFlags and gfx.TEXT_ALIGN_CENTER then
    x = x - totalW / 2
  elseif textFlags and gfx.TEXT_ALIGN_RIGHT then
    x = x - totalW
  end

  -- adjust vertical alignment
  if textFlags and gfx.TEXT_ALIGN_MIDDLE then
    y = y - this.h / 2
  elseif textFlags and gfx.TEXT_ALIGN_BOTTOM then
    y = y - this.h
  end

  for i = 1, text:len() do
    local c = text:sub(i, i)
    local image = this.images[c]
    if image ~= nil then
      gfx.BeginPath()
      gfx.ImageRect(x, y, this.w, this.h, image.image, alpha, 0)
      x = x + this.w
    end
  end
end
