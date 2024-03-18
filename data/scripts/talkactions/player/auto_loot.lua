local autoloot = {
    talkaction = "!autoloot",
    storageBase = 50000,
    freeAccountLimit = 2,
    premiumAccountLimit = 4,
    currencyToBank = true
}



local currencyItems = {}
if autoloot.currencyToBank then
    for index, item in pairs(Game.getCurrencyItems()) do
        currencyItems[item:getId()] = true
    end
end

local autolootCache = {}
local textEditRequests = {}

local function getPlayerLimit(player)
    return player:isPremium() and autoloot.premiumAccountLimit or autoloot.freeAccountLimit
end

local function getPlayerAutolootItems(player)
    local limits = getPlayerLimit(player)
    local guid = player:getGuid()
    local itemsCache = autolootCache[guid]
    if itemsCache then
        if #itemsCache > limits then
            local newChache = {unpack(itemsCache, 1, limits)}
            autolootCache[guid] = newChache
            return newChache
        end
        return itemsCache
    end

    local items = {}
    for i = 1, limits do
        local itemType = ItemType(math.max(player.storage[autoloot.storageBase + i], 0))
        if itemType and itemType:getId() ~= 0 then
            items[#items +1] = itemType:getId()
        end
    end

    autolootCache[guid] = items
    return items
end

local function setPlayerAutolootItems(player, newItems)
    local items = getPlayerAutolootItems(player)
    for i = getPlayerLimit(player), 1, -1 do
        local itemId = newItems[i]
        if itemId then
            player.storage[autoloot.storageBase + i] = itemId
            items[i] = itemId
        else
            player.storage[autoloot.storageBase + i] = -1
            table.remove(items, i)
        end
    end
    return true
end

local function addPlayerAutolootItem(player, itemId)
    local items = getPlayerAutolootItems(player)
    for _, id in pairs(items) do
        if itemId == id then
            return false
        end
    end
    items[#items +1] = itemId
    return setPlayerAutolootItems(player, items)
end

local function removePlayerAutolootItem(player, itemId)
    local items = getPlayerAutolootItems(player)
    for i, id in pairs(items) do
        if itemId == id then
            table.remove(items, i)
            return setPlayerAutolootItems(player, items)
        end
    end
    return false
end

local function hasPlayerAutolootItem(player, itemId)
    for _, id in pairs(getPlayerAutolootItems(player)) do
        if itemId == id then
            return true
        end
    end
    return false
end

local ec = EventCallback

function ec.onDropLoot(monster, corpse)
    if not corpse:getType():isContainer() then
        return
    end

    local corpseOwner = Player(corpse:getCorpseOwner())
    local items = corpse:getItems()
    local warningCapacity = false
    for _, item in pairs(items) do
        local itemId = item:getId()
        if hasPlayerAutolootItem(corpseOwner, itemId) then
            if currencyItems[itemId] then
                local worth = item:getWorth()
                corpseOwner:setBankBalance(corpseOwner:getBankBalance() + worth)
                corpseOwner:sendTextMessage(MESSAGE_STATUS_SMALL, string.format("Your balance increases by %d gold coins.", worth))
				item:remove()
            elseif not item:moveTo(corpseOwner, 0) then
                warningCapacity = true
            end
        end
    end

    if warningCapacity then
        corpseOwner:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You no have capacity.")
    end
end

ec:register(3)

local talkAction = TalkAction(autoloot.talkaction)

local exhaust = {}

function talkAction.onSay(player, words, param, type)
    
	local playerId = player:getId()
    local currentTime = os.time()
    if exhaust[playerId] and exhaust[playerId] > currentTime then
		player:sendCancelMessage("You are on cooldown, now wait (0." .. exhaust[playerId] - currentTime .. "s).")
		return false
	end
	
	local split = param:splitTrimmed(",")
    local action = split[1]
    if not action then
        player:popupFYI(string.format("Examples of use:\n%s add, gold coin\n%s remove, gold coin\n%s clear\n%s show\n%s edit\n\n~Available slots~\nFree Account: %d\nPremium Account: %d\nCurrency to Bank: %s", words, words, words, words, words, autoloot.freeAccountLimit, autoloot.premiumAccountLimit, autoloot.currencyToBank and "Yes" or "No"), false)
        exhaust[playerId] = currentTime + 2
		return false
    end

    if action == "clear" then
        setPlayerAutolootItems(player, {})
        player:sendTextMessagee(MESSAGE_STATUS_CONSOLE_BLUE, "Autoloot list cleaned.")
        return false
    elseif action == "show" then
        local items = getPlayerAutolootItems(player)
        local description = {string.format('~ Your autoloot list, capacity: %d/%d ~\n', #items, getPlayerLimit(player))}
        for i, itemId in pairs(items) do
            description[#description +1] = string.format("%d) %s", i, ItemType(itemId):getName())
        end
        player:popupFYI(table.concat(description, '\n'), false)
		exhaust[playerId] = currentTime + 2
        return false
    elseif action == "edit" then
        local items = getPlayerAutolootItems(player)
        if #items == 0 then
            -- Example
            items = {3386,3381,3079}
        end
        local description = {}
        for i, itemId in pairs(items) do
            description[#description +1] = ItemType(itemId):getName()
        end
        player:registerEvent("autolootTextEdit")
        player:showTextDialog(2814, string.format("To add articles you just have to write their IDs or names on each line\nfor example:\n\n%s", table.concat(description, '\n')), true, 666)
        textEditRequests[player:getGuid()] = true
		exhaust[playerId] = currentTime + 2
        return false
    end

    local function getItemType()
        local itemType = ItemType(split[2])
        if not itemType or itemType:getId() == 0 then
            itemType = ItemType(math.max(tonumber(split[2]) or 0), 0)
            if not itemType or itemType:getId() == 0 then
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, string.format("The item %s does not exists!", split[2]))
                exhaust[playerId] = currentTime + 2
				return false
            end
        end
        return itemType
    end

    if action == "add" then
        local itemType = getItemType()
        if itemType then
            local limits = getPlayerLimit(player)
            if #getPlayerAutolootItems(player) >= limits then
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, string.format("Your auto loot only allows you to add %d items.", limits))
                exhaust[playerId] = currentTime + 2
				return false
            end

            if addPlayerAutolootItem(player, itemType:getId()) then
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Perfect you have added to the list: %s", itemType:getName()))
            else
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, string.format("The item %s already exists!", itemType:getName()))
            end
			exhaust[playerId] = currentTime + 2
        end
        return false
    elseif action == "remove" then
        local itemType = getItemType()
        if itemType then
            if removePlayerAutolootItem(player, itemType:getId()) then
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Perfect you have removed to the list the article: %s", itemType:getName()))
            else
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, string.format("The item %s does not exists in the list.", itemType:getName()))
            end
			exhaust[playerId] = currentTime + 2
        end
        return false
    end

    return false
end

talkAction:separator(" ")
talkAction:register()

local creatureEvent = CreatureEvent("autolootCleanCache")

function creatureEvent.onLogout(player)
    setPlayerAutolootItems(player, getPlayerAutolootItems(player))
    autolootCache[player:getGuid()] = nil
    return true
end

creatureEvent:register()

creatureEvent = CreatureEvent("autolootTextEdit")

function creatureEvent.onTextEdit(player, item, text)
    player:unregisterEvent("autolootTextEdit")

    local split = text:splitTrimmed("\n")
    local items = {}
    for index, name in pairs(split) do repeat
        local itemType = ItemType(name)
        if not itemType or itemType:getId() == 0 then
            itemType = ItemType(tonumber(name))
            if not itemType or itemType:getId() == 0 then
                break
            end

            break
        end

        items[#items +1] = itemType:getId()
    until true end
    setPlayerAutolootItems(player, items)
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Perfect, you have modified the list of articles manually."))
    return true
end

creatureEvent:register()