local stamina = Action()

function stamina.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local maxStamina = 42 -- stamina recovery.
	local timer = 2 -- hours for use stamina.
	
	if player:getStorageValue(Storage.STAMINASTORAGE) > os.time() then
		local remainingTime = player:getStorageValue(Storage.STAMINASTORAGE) - os.time()
		local hours = math.floor(remainingTime / 3600)
		local minutes = math.floor((remainingTime % 3600) / 60)
		local seconds = remainingTime % 60
		
		local timeMessage
		if hours > 0 then
			timeMessage = string.format("You have to wait:\n%d hours, %d minutes, and %d seconds to use the stamina salad again.", hours, minutes, seconds)
		elseif minutes > 0 then
			timeMessage = string.format("You have to wait:\n%d minutes and %d seconds to use the stamina salad again.", minutes, seconds)
		else
			timeMessage = string.format("You have to wait:\n%d seconds to use the stamina salad again.", seconds)
		end
		
		return player:sendTextMessage(MESSAGE_INFO_DESCR, timeMessage)
	end
	
	if player:getStamina() == maxStamina * 60 then
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "I can't use it with full stamina.")
	else
		player:setStamina(maxStamina * 60)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		player:say("[Stamina Recovered]")
		player:setStorageValue(Storage.STAMINASTORAGE, os.time() + timer * 60 * 60)
		item:remove()
		return player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have recovered full stamina, you can use it again after 2 hours.")
	end
	
	return true
end

stamina:id(9993)
stamina:register()
