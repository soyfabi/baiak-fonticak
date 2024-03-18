local conditionSubId = 45064 -- must be a unique subId not used for other buffs in your server
local config  = {
    statStorageKey = 45064, -- give players points with this storage
    ["statMain"] = {
        -- flat_bonus_stats
        {storageKey = 45065, statType = "life increase", value = 50},
        {storageKey = 45066, statType = "mana increase", value = 50},
        {storageKey = 45067, statType = "magic", value = 1},
        {storageKey = 45068, statType = "fist", value = 1},
        {storageKey = 45069, statType = "melee", value = 1},
        {storageKey = 45070, statType = "distance", value = 1},
        {storageKey = 45071, statType = "shield", value = 1},
        {storageKey = 45072, statType = "fishing", value = 1},
        {storageKey = 45073, statType = "critical hit chance", value = 1},
        {storageKey = 45074, statType = "critical hit damage", value = 1},
        {storageKey = 45075, statType = "life leech chance", value = 1},
        {storageKey = 45076, statType = "life leech amount", value = 1},
        {storageKey = 45077, statType = "mana leech chance", value = 1},
        {storageKey = 45078, statType = "mana leech amount", value = 1}
    },
    ["statSpeed"] = {
        {storageKey = 45079, statType = "speed", value = 2}
    },
    ["statRegen"] = {
        {storageKey = 45080, statType = "life regen", value = 5, ticks = 5000}, -- ticks in milliseconds}
        {storageKey = 45081, statType = "mana regen", value = 5, ticks = 5000}  -- can't go lower then 1000
    },
    ["statSoulRegen"] = { -- you can remove entire categories
        {storageKey = 45082, statType = "soul regen", value = 1, ticks = 5000} -- or individual stats, if you don't want to use them
    },
  
    modalWindow = {
        id = 1002, -- must be unique
        title = "Stat System",
        message = "",
        eventText = "ModalWindow_XikiniStatSystem",
        buttons = {
            {text = "Reset"},
            {text = "Remove"},
            {text = "Add", defaultEnterButton = true},
            {text = "Close", defaultEscapeButton = true},
        }
    }
}

-- Choose Flat or Percentage stats. Cannot use both.

-- Flat Stats
--[[
    ["statMain"] = {
        -- flat_bonus_stats
        {storageKey = 45065, statType = "life increase", value = 50},
        {storageKey = 45066, statType = "mana increase", value = 50},
        {storageKey = 45067, statType = "magic", value = 1},
        {storageKey = 45068, statType = "fist", value = 1},
        {storageKey = 45069, statType = "melee", value = 1},
        {storageKey = 45070, statType = "distance", value = 1},
        {storageKey = 45071, statType = "shield", value = 1},
        {storageKey = 45072, statType = "fishing", value = 1},
        {storageKey = 45073, statType = "critical hit chance", value = 1},
        {storageKey = 45074, statType = "critical hit damage", value = 1},
        {storageKey = 45075, statType = "life leech chance", value = 1},
        {storageKey = 45076, statType = "life leech amount", value = 1},
        {storageKey = 45077, statType = "mana leech chance", value = 1},
        {storageKey = 45078, statType = "mana leech amount", value = 1}
    },
    ["statSpeed"] = {
        {storageKey = 45079, statType = "speed", value = 2}
    },
    ["statRegen"] = {
        {storageKey = 45080, statType = "life regen", value = 5, ticks = 5000}, -- ticks in milliseconds}
        {storageKey = 45081, statType = "mana regen", value = 5, ticks = 5000}  -- can't go lower then 1000
    },
    ["statSoulRegen"] = { -- you can remove entire categories
        {storageKey = 45082, statType = "soul regen", value = 1, ticks = 5000} -- or individual stats, if you don't want to use them
    },
]]--


-- Percent Stats
--[[
    ["statMain"] = {
        -- percent_bonus_stats
        {storageKey = 45065, statType = "life increase percent", value = 1},
        {storageKey = 45066, statType = "mana increase percent", value = 1},
        {storageKey = 45067, statType = "magic percent", value = 1},
        {storageKey = 45068, statType = "fist percent", value = 1},
        {storageKey = 45069, statType = "melee percent", value = 1},
        {storageKey = 45070, statType = "distance percent", value = 1},
        {storageKey = 45071, statType = "shield percent", value = 1},
        {storageKey = 45072, statType = "fishing percent", value = 1},
        {storageKey = 45073, statType = "critical hit chance", value = 1},
        {storageKey = 45074, statType = "critical hit damage", value = 1},
        {storageKey = 45075, statType = "life leech chance", value = 1},
        {storageKey = 45076, statType = "life leech amount", value = 1},
        {storageKey = 45077, statType = "mana leech chance", value = 1},
        {storageKey = 45078, statType = "mana leech amount", value = 1}
    },
    ["statSpeed"] = {
        {storageKey = 45079, statType = "speed", value = 2}
    },
    ["statRegen"] = {
        {storageKey = 45080, statType = "life regen", value = 5, ticks = 5000}, -- ticks in milliseconds}
        {storageKey = 45081, statType = "mana regen", value = 5, ticks = 5000}  -- can't go lower then 1000
    },
    ["statSoulRegen"] = {
        {storageKey = 45082, statType = "soul regen", value = 1, ticks = 5000}
    },
]]--


-- END OF CONFIG

local choiceDictionary = {}

local conditions = {
    ["life increase"] = {CONDITION_PARAM_STAT_MAXHITPOINTS},
    ["mana increase"] = {CONDITION_PARAM_STAT_MAXMANAPOINTS},
    ["speed"] = {CONDITION_PARAM_SPEED},
    ["magic"] = {CONDITION_PARAM_STAT_MAGICPOINTS},
    ["melee"] = {CONDITION_PARAM_SKILL_MELEE},
    ["fist"] = {CONDITION_PARAM_SKILL_FIST},
    ["club"] = {CONDITION_PARAM_SKILL_CLUB},
    ["sword"] = {CONDITION_PARAM_SKILL_SWORD},
    ["axe"] = {CONDITION_PARAM_SKILL_AXE},
    ["distance"] = {CONDITION_PARAM_SKILL_DISTANCE},
    ["shield"] = {CONDITION_PARAM_SKILL_SHIELD},
    ["fishing"] = {CONDITION_PARAM_SKILL_FISHING},
    ["critical hit chance"] = {CONDITION_PARAM_SPECIALSKILL_CRITICALHITCHANCE},
    ["critical hit damage"] = {CONDITION_PARAM_SPECIALSKILL_CRITICALHITAMOUNT},
    ["life leech chance"] = {CONDITION_PARAM_SPECIALSKILL_LIFELEECHCHANCE},
    ["life leech amount"] = {CONDITION_PARAM_SPECIALSKILL_LIFELEECHAMOUNT},
    ["mana leech chance"] = {CONDITION_PARAM_SPECIALSKILL_MANALEECHCHANCE},
    ["mana leech amount"] = {CONDITION_PARAM_SPECIALSKILL_MANALEECHAMOUNT},
    ["life increase percent"] = {CONDITION_PARAM_STAT_MAXHITPOINTSPERCENT},
    ["mana increase percent"] = {CONDITION_PARAM_STAT_MAXMANAPOINTSPERCENT},
    ["magic percent"] = {CONDITION_PARAM_STAT_MAGICPOINTSPERCENT},
    ["melee percent"] = {CONDITION_PARAM_SKILL_MELEEPERCENT},
    ["fist percent"] = {CONDITION_PARAM_SKILL_FISTPERCENT},
    ["club percent"] = {CONDITION_PARAM_SKILL_CLUBPERCENT},
    ["sword percent"] = {CONDITION_PARAM_SKILL_SWORDPERCENT},
    ["axe percent"] = {CONDITION_PARAM_SKILL_AXEPERCENT},
    ["distance percent"] = {CONDITION_PARAM_SKILL_DISTANCEPERCENT},
    ["shield percent"] = {CONDITION_PARAM_SKILL_SHIELDPERCENT},
    ["fishing percent"] = {CONDITION_PARAM_SKILL_FISHINGPERCENT},
    ["life regen"] = {CONDITION_PARAM_HEALTHGAIN, CONDITION_PARAM_HEALTHTICKS},
    ["mana regen"] = {CONDITION_PARAM_MANAGAIN, CONDITION_PARAM_MANATICKS},
    ["soul regen"] = {CONDITION_PARAM_SOULGAIN, CONDITION_PARAM_SOULTICKS}
}

local main_attributes = {CONDITION_ATTRIBUTES, CONDITION_HASTE, CONDITION_REGENERATION, CONDITION_SOUL}
local main_stats = {"statMain", "statSpeed", "statRegen", "statSoulRegen"}

-- choiceDictionary Setup
for i = 1, 4 do
    local statCategory = main_stats[i]
    if config[statCategory] then
        for index, stat in ipairs(config[statCategory]) do
            choiceDictionary[#choiceDictionary + 1] = config[statCategory][index]
        end
    end
end

local function updateStatBonus(player)
    -- remove all previous buffs
    for i = 1, 4 do
        if player:getCondition(main_attributes[i], conditionSubId) then
            player:removeCondition(main_attributes[i], conditionSubId)
        end
    end
 
    -- add all buffs
    for i = 1, 4 do
        local statCategory = main_stats[i]
        if config[statCategory] then
            local condition = Condition(main_attributes[i], conditionSubId)
            condition:setParameter(CONDITION_PARAM_TICKS, -1)
            for _, stat in ipairs(config[statCategory]) do
                local storageValue = player:getStorageValue(stat.storageKey)
                if storageValue > 0 then
                    for conditionParam = 1, #conditions[stat.statType] do
                        condition:setParameter(conditions[stat.statType][conditionParam], (stat.value * storageValue))
                    end
                    player:addCondition(condition)
                end
            end
        end
    end
    return true
end

local creatureevent = CreatureEvent("onLogin_updateStatBonus")

function creatureevent.onLogin(player)
    updateStatBonus(player)
    return true
end

creatureevent:register()



local function createStatWindow(playerId)
    local player = Player(playerId)
    if not player then
        return
    end

    if player:hasEvent(CREATURE_EVENT_MODALWINDOW, config.modalWindow.eventText) then
        player:unregisterEvent(config.modalWindow.eventText)
    end
    player:registerEvent(config.modalWindow.eventText)
  
    local storageValue = player:getStorageValue(config.statStorageKey)
    local modalWindow = ModalWindow(config.modalWindow.id, config.modalWindow.title, "You have " .. (storageValue > 0 and storageValue or 0) .. " stat points to spend.")
  
    for id, button in ipairs(config.modalWindow.buttons) do
        modalWindow:addButton(id, button.text)
        if button.defaultEscapeButton then
            modalWindow:setDefaultEscapeButton(id)
        elseif button.defaultEnterButton then
            modalWindow:setDefaultEnterButton(id)
        end
    end
  
    for id, stat in ipairs(choiceDictionary) do
        local storageValue = player:getStorageValue(stat.storageKey)
        storageValue = storageValue > 0 and storageValue or 0
        modalWindow:addChoice(id, "[" .. storageValue .. "] " .. stat.statType)
    end
  
    modalWindow:hasPriority()
    modalWindow:sendToPlayer(player)
end


local creatureevent = CreatureEvent(config.modalWindow.eventText)

function creatureevent.onModalWindow(player, modalWindowId, buttonId, choiceId)
    player:unregisterEvent(config.modalWindow.eventText)
  
    if modalWindowId == config.modalWindow.id then
        local buttonChoice = config.modalWindow.buttons[buttonId].text
      
        local statStorageValue = player:getStorageValue(config.statStorageKey)
        if buttonChoice == "Add" then
            if statStorageValue > 0 then
                local stat = choiceDictionary[choiceId]
                local storageValue = player:getStorageValue(stat.storageKey)
                storageValue = storageValue > 0 and storageValue or 0
                player:setStorageValue(stat.storageKey, storageValue + 1)
                player:setStorageValue(config.statStorageKey, statStorageValue - 1)
            end
        elseif buttonChoice == "Remove" then
            if statStorageValue > 0 then
                local stat = choiceDictionary[choiceId]
                local storageValue = player:getStorageValue(stat.storageKey)
                storageValue = storageValue > 0 and storageValue or 0
                if storageValue > 0 then
                    player:setStorageValue(stat.storageKey, storageValue - 1)
                    player:setStorageValue(config.statStorageKey, statStorageValue + 1)
                end
            end
        elseif buttonChoice == "Reset" then
            local totalResetPoints = 0
            for id, stat in ipairs(choiceDictionary) do
                local storageValue = player:getStorageValue(stat.storageKey)
                storageValue = storageValue > 0 and storageValue or 0
                player:setStorageValue(stat.storageKey, 0)
                totalResetPoints = totalResetPoints + storageValue
            end
            player:setStorageValue(config.statStorageKey, statStorageValue + totalResetPoints)
        else
            -- "Close" button
            return true
        end
      
        updateStatBonus(player)
        addEvent(createStatWindow, 0, player:getId())
    end
    return true
end

creatureevent:register()


local talkaction = TalkAction("!stats")

function talkaction.onSay(player, words, param, type)
    createStatWindow(player:getId())
    return false
end

talkaction:separator(" ")
talkaction:register()