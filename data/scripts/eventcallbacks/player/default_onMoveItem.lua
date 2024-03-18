local event = Event()

local stoneSkinAmuletExhausted = {}

local tileLimit = 0
local protectionTileLimit = 20
local houseTileLimit = 7

CONTAINER_WEIGHT_CHECK = true -- true = enable / false = disable
CONTAINER_WEIGHT_MAX = 1000000 -- 1000000 = 10k = 10000.00 oz

event.onMoveItem = function(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	-- No move items with actionID = 200 --
	if item:getActionId() == 200 then
		return false
	end
	
	-- No move parcel very heavy
	if CONTAINER_WEIGHT_CHECK and ItemType(item:getId()):isContainer()
	and item:getWeight() > CONTAINER_WEIGHT_MAX then
		self:sendCancelMessage("Your cannot move this item too heavy.")
		return false
	end
	
	-- Players cannot throw items on teleports
	if toPosition.x ~= CONTAINER_POSITION then
		local thing = Tile(toPosition):getItemByType(ITEM_TYPE_TELEPORT)
		if thing then
			self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
			self:getPosition():sendMagicEffect(CONST_ME_POFF)
			return false
		end
	end
	
	-- Bath tube
	local toTile = Tile(toCylinder:getPosition())
	local topDownItem = toTile:getTopDownItem()
	if topDownItem and table.contains({ BATHTUB_EMPTY, BATHTUB_FILLED }, topDownItem:getId()) then
		return false
	end
	
	-- SSA exhaust
	if toPosition.x == CONTAINER_POSITION and toPosition.y == CONST_SLOT_NECKLACE
	and item:getId() == 2197 then
		local pid = self:getId()
		if stoneSkinAmuletExhausted[pid] then
			addEvent(function()self:sendCancelMessage("Wait 2 seconds for equip SSA again.") end, 100)
			return false
		else
			stoneSkinAmuletExhausted[pid] = true
			addEvent(function() stoneSkinAmuletExhausted[pid] = false end, 2000, pid)
			return true
		end
	end
	
	-- Max Tile --
	local tile = Tile(toPosition)
    if tile then
        local itemLimit = tile:getHouse() and houseTileLimit or tile:hasFlag(TILESTATE_PROTECTIONZONE) and protectionTileLimit or tileLimit
        if itemLimit > 0 and tile:getThingCount() > itemLimit and item:getType():getType() ~= ITEM_TYPE_MAGICFIELD then
			addEvent(function()self:sendCancelMessage("You can not add more items on this tile.") end, 100)
            return false
        end
    end
	
	-- Block Throw in Depot
	local tile = Tile(toPosition)
    if tile and tile:hasFlag(TILESTATE_DEPOT) and self:getPosition():getDistance(toPosition) > 1 then
		addEvent(function()self:sendCancelMessage("You can't throw items on top of this depot.") end, 100)
        return false
    end

	if item:getTopParent() == self and bit.band(toPosition.y, 0x40) == 0 then
		local itemType, moveItem = ItemType(item:getId())
		if bit.band(itemType:getSlotPosition(), SLOTP_TWO_HAND) ~= 0 and toPosition.y == CONST_SLOT_LEFT then
			moveItem = self:getSlotItem(CONST_SLOT_RIGHT)
		elseif itemType:getWeaponType() == WEAPON_SHIELD and toPosition.y == CONST_SLOT_RIGHT then
			moveItem = self:getSlotItem(CONST_SLOT_LEFT)
			if moveItem and bit.band(ItemType(moveItem:getId()):getSlotPosition(), SLOTP_TWO_HAND) == 0 then
				return true
			end
		end

		if moveItem then
			local parent = item:getParent()
			if parent:isContainer() and parent:getSize() == parent:getCapacity() then
				self:sendTextMessage(MESSAGE_STATUS_SMALL, Game.getReturnMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM))
				return false
			else
				return moveItem:moveTo(parent)
			end
		end
	end
	
	if toPosition.x == CONTAINER_POSITION then
		local containerId = toPosition.y - 64
		local container = self:getContainerById(containerId)		
		if not container then
			return true 
		end

		-- Do not let the player insert items into either the Reward Container or the Reward Chest
		local itemId = container:getId()		
		if itemId == ITEM_REWARD_CONTAINER or itemId == ITEM_REWARD_CHEST then
			self:sendCancelMessage('Sorry, not possible.')
			return false
		end

		-- The player also shouldn't be able to insert items into the boss corpse		
		local tile = Tile(container:getPosition())
		for _, item in ipairs(tile:getItems()) do
			if item:getAttribute(ITEM_ATTRIBUTE_CORPSEOWNER) == 2^31 - 1 and item:getName() == container:getName() then
				self:sendCancelMessage('Sorry, not possible.')
				return false
			end
		end
	end

	-- Do not let the player move the boss corpse.
	if item:getAttribute(ITEM_ATTRIBUTE_CORPSEOWNER) == 2^31 - 1 then
		self:sendCancelMessage('Sorry, not possible.')
		return false
	end

	return true
end

event:register()
