function onCreateWildGrowth(creature, tile)
	local wildGrowth
	if Game.getWorldType() == WORLD_TYPE_NO_PVP then
		wildGrowth = ITEM_WILDGROWTH_SAFE
	else
		wildGrowth = ITEM_WILDGROWTH
	end
	local item = Game.createItem(wildGrowth, 1, tile)
	item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, "Pulled by: ".. creature:getName() ..".")
end

local combat = Combat()
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_ENERGY)
combat:setCallback(CALLBACK_PARAM_TARGETTILE, "onCreateWildGrowth")

local rune = Spell("rune")
function rune.onCastSpell(creature, variant, isHotkey)
	return combat:execute(creature, variant)
end

rune:name("Wild Growth Rune")
rune:group("attack")
rune:cooldown(2 * 1000)
rune:groupCooldown(2 * 1000)
rune:level(27)
rune:magicLevel(8)
rune:runeId(2269)
rune:charges(2)
rune:isBlocking(true, true)
rune:allowFarUse(true)
rune:vocation("druid;true", "elder druid;true")
rune:register()
