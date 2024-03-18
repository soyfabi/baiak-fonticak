function canJoin(player)
	return player:getGuildLevel() == 3 or player:getGroup():getAccess()
end

function onSpeak(player, type, message)
	local staff = player:getGroup():getAccess()
	local guild = player:getGuild()
	local info = "STAFF"
	type = TALKTYPE_CHANNEL_Y
	
	if staff then
		if guild then
			info =  info .. "][" .. guild:getName()
		end
		type = TALKTYPE_CHANNEL_O
	else
		info = guild:getName()
	end
	
	sendChannelMessage(10, type, player:getName() .. " [".. player:getLevel() .."] Guild: [" .. info .. "]: " .. message)
	return false
end