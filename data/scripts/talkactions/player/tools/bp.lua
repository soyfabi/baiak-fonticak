local backpacks = {
    ["brown"] = {itemId = 1988, price = 20},
    ["crown"] = {itemId = 10522, price = 10000}
}

-- END OF CONFIG

local playerConfirmation = {}

local function getItemNameString(item)
    return item:getNameDescription(item:getSubType(), true)
end

local talkaction = TalkAction("!backpack")

function talkaction.onSay(player, words, param, type)
   
    if param == "" then
        param = "brown" -- aka: default backpack
    end
   
    param = param:lower()
    local playerId = player:getId()
    local index = playerConfirmation[playerId]
    playerConfirmation[playerId] = nil   
   
    if param == "confirm" and index then
        if player:getTotalMoney() < backpacks[index].price then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "You do not have sufficient funds to purchase this item.")
            return false
        end
        local backpack = Game.createItem(backpacks[index].itemId, 1)
        if player:addItemEx(backpack, false) ~= RETURNVALUE_NOERROR then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "You do not have sufficient room or capacity to receive this item.")
            return false
        end
        player:removeTotalMoney(backpacks[index].price)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You have purchased " .. getItemNameString(backpack) .. " for " .. backpacks[index].price .. " gold.")
        return false
    elseif param == "list" then
        local text = ""
        for k, v in pairs(backpacks) do
            if text ~= "" then
                text = text .. "\n"
            end
            text = text .. k .. " backpack - " .. v.price .. " gold"
        end
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Here is the list of backpacks.")
        player:showTextDialog(1988, "List of backpacks:\n\n" .. text)
        return false
    end
   
    index = backpacks[param]
   
    if not index then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "There is no backpack named " .. param .. ".")
        return false
    end
   
    playerConfirmation[playerId] = param
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Would you like to purchase a " .. param .. " backpack for " .. index.price .. " gold?")
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "To finalise the purchase use !backpack confirm")
    return false
end

talkaction:separator(" ")
talkaction:register()