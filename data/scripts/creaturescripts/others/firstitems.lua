local FirstItems = CreatureEvent("FirstItems")
local config = {
	[1] = { -- Sorcerer
--equipment: mage hat, spellbook, magician's robe, snakebite rod, studded legs, scarf, leather boots, life ring
		items = {{2323, 1}, {8901, 1}, {8871, 1}, {2184, 1}, {7730, 1}, {2661, 1}, {2195, 1}, {2168, 1}},
		--container brown mushrooms, mana potion, health potion, rope, shovel
		container = {{2676, 5}, {2120, 1}, {5710, 1}, {7620, 1}, {7618, 1}}
	},
	[2] = { -- Druid
--equipment: mage hat, spellbook, magician's robe, snakebite rod, studded legs, scarf, leather boots, life ring
		items = {{2323, 1}, {8901, 1}, {8871, 1}, {2184, 1}, {7730, 1}, {2661, 1}, {2195, 1}, {2168, 1}},
		--container brown mushrooms, mana potion, health potion, rope, shovel
		container = {{2676, 5}, {2120, 1}, {5710, 1}, {7620, 1}, {7618, 1}}
	},
	[3] = { -- Paladin
--equipment: legion helmet, dwarven shield, ranger's cloak, spear, elven legs, scarf, leather boots, life ring
		items = {{3972, 1}, {2518, 1}, {2660, 1}, {8855, 1}, {2507, 1}, {2661, 1}, {2195, 1}, {2168, 1}},
		--container brown mushrooms, adventurer's stone, mana potion, health potion, rope, shovel, arrow, blue quiver, bow
		container = {{2676, 5}, {2120, 1}, {5710, 1}, {7620, 1}, {7618, 1}}
	},
	[4] = { -- Knight
--equipment: brass helmet, dwarven shield, brass armor, steel axe, brass legs, scarf, leather boots, life ring
		items = {{2497, 1}, {2518, 1}, {2487, 1}, {8931, 1}, {2477, 1}, {2661, 1}, {2195, 1}, {2168, 1}},
		--container brown mushrooms, adventurer's stone, mana potion, health potion, rope, shovel, jagged sword, daramian club 
		container = {{2676, 5}, {2120, 1}, {5710, 1}, {2443, 1}, {2444, 1}, {7620, 1}, {7618, 1}}
	}
}

function FirstItems.onLogin(player)
	player:registerEvent("FirstItems")
	if player:getLastLoginSaved() ~= 0 then
		return true
	end

	local targetVocation = config[player:getVocation():getId()]
	if not targetVocation then
		return true
	end

	for i = 1, #targetVocation.items do
		player:addItem(targetVocation.items[i][1], targetVocation.items[i][2])
	end

	local backpack = player:addItem(1998)
	if not backpack then
		return true
	end

	for i = 1, #targetVocation.container do
	backpack:addItem(targetVocation.container[i][1], targetVocation.container[i][2])
	end
	
	return true
end
FirstItems:register()
