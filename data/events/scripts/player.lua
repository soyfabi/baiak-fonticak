function Player:onLook(thing, position, distance)
	local description = ""
	if hasEvent.onLook then
		description = Event.onLook(self, thing, position, distance, description)
	end
	
	if description ~= "" then
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
	end
end

function Player:onLookInBattleList(creature, distance)
	local description = ""
	if hasEvent.onLookInBattleList then
		description = Event.onLookInBattleList(self, creature, distance, description)
	end
	
	if description ~= "" then
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
	end
end

function Player:onLookInTrade(partner, item, distance)
	local description = "You see " .. item:getDescription(distance)
	if hasEvent.onLookInTrade then
		description = Event.onLookInTrade(self, partner, item, distance, description)
	end
	
	if description ~= "" then
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
	end
end

function Player:onLookInShop(itemType, count, description)
	local description = "You see " .. description
	if hasEvent.onLookInShop then
		description = Event.onLookInShop(self, itemType, count, description)
	end
	
	if description ~= "" then
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
	end
end

function Player:onMoveItem(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if hasEvent.onMoveItem then
		return Event.onMoveItem(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	end
	return true
end

function Player:onItemMoved(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if hasEvent.onItemMoved then
		Event.onItemMoved(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	end
end

function Player:onMoveCreature(creature, fromPosition, toPosition)
	if hasEvent.onMoveCreature then
		return Event.onMoveCreature(self, creature, fromPosition, toPosition)
	end
	return true
end

function Player:onReportRuleViolation(targetName, reportType, reportReason, comment, translation)
	if hasEvent.onReportRuleViolation then
		Event.onReportRuleViolation(self, targetName, reportType, reportReason, comment, translation)
	end
end

function Player:onReportBug(message, position, category)
	if hasEvent.onReportBug then
		return Event.onReportBug(self, message, position, category)
	end
	return true
end

function Player:onTurn(direction)
	if hasEvent.onTurn then
		return Event.onTurn(self, direction)
	end
	return true
end

function Player:onTradeRequest(target, item)
	if hasEvent.onTradeRequest then
		return Event.onTradeRequest(self, target, item)
	end
	return true
end

function Player:onTradeAccept(target, item, targetItem)
	if hasEvent.onTradeAccept then
		return Event.onTradeAccept(self, target, item, targetItem)
	end
	return true
end

function Player:onTradeCompleted(target, item, targetItem, isSuccess)
	if hasEvent.onTradeCompleted then
		Event.onTradeCompleted(self, target, item, targetItem, isSuccess)
	end
end

function Player:onGainExperience(source, exp, rawExp, sendText)
	if hasEvent.onGainExperience then
		Event.onGainExperience(self, source, exp, rawExp, sendText)
	end
	return hasEvent.onGainExperience and Event.onGainExperience(self, source, exp, rawExp) or exp
end

function Player:onLoseExperience(exp)
	return hasEvent.onLoseExperience and Event.onLoseExperience(self, exp) or exp
end

function Player:onGainSkillTries(skill, tries)
	if not APPLY_SKILL_MULTIPLIER then
		return hasEvent.onGainSkillTries and Event.onGainSkillTries(self, skill, tries) or tries
	end

	if skill == SKILL_MAGLEVEL then
		tries = tries * configManager.getNumber(configKeys.RATE_MAGIC)
		return hasEvent.onGainSkillTries and Event.onGainSkillTries(self, skill, tries) or tries
	end
	tries = tries * configManager.getNumber(configKeys.RATE_SKILL)
	return hasEvent.onGainSkillTries and Event.onGainSkillTries(self, skill, tries) or tries
end

function Player:onInventoryUpdate(item, slot, equip)
	if hasEvent.onInventoryUpdate then
		Event.onInventoryUpdate(self, item, slot, equip)
	end
end

function Player:onStepTile(fromPosition, toPosition)
    if hasEvent.onStepTile then
        return Event.onStepTile(self, fromPosition, toPosition)
    end
    return true
end

function Player:onNetworkMessage(recvByte, msg)
	local handler = PacketHandlers[recvByte]
	if not handler then
		--io.write(string.format("Player: %s sent an unknown packet header: 0x%02X with %d bytes!\n", self:getName(), recvByte, msg:len()))
		return
	end

	handler(self, msg)
end

function Player:onUpdateStorage(key, value, oldValue, isLogin)
	if hasEvent.onUpdateStorage then
		Event.onUpdateStorage(self, key, value, oldValue, isLogin)
	end
end

function Player:onSay(message)
	if hasEvent.onSay then
		Event.onSay(self, message)
		return true
	end
end

function Player:onChangeGhostMode()
	if hasEvent.onChangeGhostMode then
		Event.onChangeGhostMode(self)
	end
end
