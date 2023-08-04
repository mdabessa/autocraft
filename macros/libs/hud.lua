local hud = {}

hud.texts = {}
hud.index = 0

hud.addText = function(text, x, y)
    local _text = hud2D.newText(text, x, y)
    hud.texts[hud.index] = _text
    hud.index = hud.index + 1
    return _text, hud.index - 1
end

hud.removeText = function(id)
    hud.texts[id] = nil
end

hud.enable = function()
    for _, text in pairs(hud.texts) do
        if not text.isDrawing() then
            text.enableDraw()
        end
    end
end

hud.disable = function()
    for _, text in pairs(hud.texts) do
        text.disableDraw()
    end
end

hud.clear = function()
    for _, text in pairs(hud.texts) do
        text.disableDraw()
    end
    hud.texts = {}
end

return hud
