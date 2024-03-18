local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local rewards = {
--  Level, items, count. --
    [100] = {items = 2160, count = 5},
    [200] = {items = 2160, count = 10},
    [300] = {items = 2160, count = 15},
}

function getNextRewardLevel(currentLevel)
    local nextLevel = nil
    for level, _ in pairs(rewards) do
        if level > currentLevel then
            if nextLevel == nil or level < nextLevel then
                nextLevel = level
            end
        end
    end
    return nextLevel
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then
        return false
    end

    local player = Player(cid)
	local storage = 100000 -- storage que se le dara al obtener el premio.
	
    if msgcontains(msg, "premio") then
        local level = getPlayerLevel(cid)
        local reward = rewards[level]

        if reward then
            if getPlayerStorageValue(cid, storage + level) < 1 then
				doPlayerAddItem(cid, reward.items, reward.count)
                setPlayerStorageValue(cid, storage + level, 1)
                npcHandler:say("Aquí está tu premio por alcanzar el nivel " .. level .. ".", cid)
            else
                npcHandler:say("Lo siento, ya has recogido tu premio para este nivel.", cid)
            end
        else
            local nextLevel = getNextRewardLevel(level)
            if nextLevel then
                npcHandler:say("Lo siento, no tienes el nivel requerido, necesitas ser nivel " .. nextLevel .. ".", cid)
            else
                npcHandler:say("No hay más premios disponibles.", cid)
            end
        end
    end

    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
