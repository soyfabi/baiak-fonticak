function onCreateMagicWall(creature, tile)
	local magicWall
	if Game.getWorldType() == WORLD_TYPE_NO_PVP then
		magicWall = ITEM_MAGICWALL_SAFE
	else
		magicWall = ITEM_MAGICWALL
	end
	local item = Game.createItem(magicWall, 1, tile)
	item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, "Pulled by: ".. creature:getName() ..".")
end

local combat = Combat()
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_ENERGY)
combat:setCallback(CALLBACK_PARAM_TARGETTILE, "onCreateMagicWall")

local rune = Spell("rune")
function rune.onCastSpell(creature, variant, isHotkey)
	return combat:execute(creature, variant)
end

rune:name("Magic Wall Rune")
rune:group("attack")
rune:cooldown(2 * 1000)
rune:groupCooldown(2 * 1000)
rune:level(32)
rune:magicLevel(9)
rune:runeId(2293)
rune:charges(3)
rune:isBlocking(true, true)
rune:allowFarUse(true)
rune:register()
