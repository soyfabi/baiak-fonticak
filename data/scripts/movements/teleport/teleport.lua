local setting = {
	[45000] = {position = Position(2500, 2500, 7)}, -- Quest Exit
}

local Teleports = MoveEvent()

function Teleports.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	local teleport = setting[item.uid]
	if teleport then
		player:teleportTo(teleport.position)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	end
	
	return true
end

Teleports:type("stepin")

for index, value in pairs(setting) do
	Teleports:uid(index)
end

Teleports:register()
