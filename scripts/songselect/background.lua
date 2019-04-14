local backgroundImage = gfx.CreateSkinImage("song_select/bg.png", 1)

render = function(deltaTime)
    resx, resy = game.GetResolution()
    gfx.BeginPath()
    gfx.ImageRect(0, 0, resx, resy, backgroundImage, 1, 0)
end
