local item_changer = {
    {position = Position(1856, 2449, 4), item = {8932, 7388, 8929}, currentIndex = 1},
}

local globalevent = GlobalEvent("Item_Changer")

function globalevent.onThink(interval)
    for i = 1, #item_changer do
        local settings = item_changer[i]
        local tile = Tile(settings.position)
        if tile then
            local item = tile:getItemById(settings.item[settings.currentIndex])
            if not item then -- Si no existe el item, lo crea.
                Game.createItem(settings.item[settings.currentIndex], 1, settings.position)
            else -- Si el item ya existe, lo elimina y crea el siguiente en la secuencia.
                item:remove()
                settings.currentIndex = settings.currentIndex + 1
                if settings.currentIndex > #settings.item then
                    settings.currentIndex = 1
                end
                Game.createItem(settings.item[settings.currentIndex], 1, settings.position)
            end
			settings.position:sendMagicEffect(CONST_ME_MAGIC_GREEN)
        end
    end
    return true
end

globalevent:interval(5000)
globalevent:register()
