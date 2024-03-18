local test_scripts = Action()

function test_scripts.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	player:setStorageValue(45064, 50)
	player:say("hola")
	
	return true
end

test_scripts:id(11236)
test_scripts:register()
