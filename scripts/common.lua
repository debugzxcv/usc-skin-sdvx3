gfx.LoadSkinFont("segoeui.ttf")

-- Image class
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
--  gfx.BeginPath()
--  gfx.ImageRect(x - this.w / 2, y - this.h / 2, this.w, this.h, this.image, alpha, angle)
  this:drawSize(x, y, this.w, this.h, alpha, angle)
end

Image.drawSize = function(this, x, y, w, h, alpha, angle)
  gfx.BeginPath()
  gfx.ImageRect(x - w / 2, y - h / 2, w, h, this.image, alpha, angle)
end
