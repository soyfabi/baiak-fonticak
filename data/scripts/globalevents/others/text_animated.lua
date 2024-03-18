local effects = {
    {position = Position(2503, 2495, 7), text = 'VIP FREE', color = TEXTCOLOR_YELLOW},
	{position = Position(2497, 2495, 7), text = 'Quests', color = TEXTCOLOR_LIGHTBLUE},
	{position = Position(2502, 2495, 7), text = 'Trainers', color = TEXTCOLOR_LIGHTBLUE},
	{position = Position(2498, 2495, 7), text = 'Hunts', color = TEXTCOLOR_LIGHTBLUE},
	{position = Position(1010, 995, 7), text = 'Events', color = TEXTCOLOR_LIGHTBLUE},
	{position = Position(999, 989, 7), text = 'Castle24H', color = TEXTCOLOR_LIGHTBLUE},
	{position = Position(1007, 989, 7), text = 'Castle48H', color = TEXTCOLOR_LIGHTBLUE},
	{position = Position(1003, 988, 7), text = 'PREMIUM', color = TEXTCOLOR_LIGHTBLUE},
	{position = Position(1003, 993, 7), text = 'Reward Chest', color = TEXTCOLOR_LIGHTBLUE},
    
}

local globalevent = GlobalEvent("Text_Effect")
local effectsColors = {39, 20, 30, 40, 42, 44, 45, 46, 47, 48}

function globalevent.onThink(interval)
    for i = 1, #effects do
        local settings = effects[i]
        local spectators = Game.getSpectators(settings.position, false, true, 7, 7, 5, 5)
        if #spectators > 0 then
            if settings.text then
                Game.sendAnimatedText(settings.text, settings.position, settings.color)
            end
        end
    end
    return true
end

globalevent:interval(2000) -- Interval in milliseconds
globalevent:register()