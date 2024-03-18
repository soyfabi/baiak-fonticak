local destroy = Action()

function destroy.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return onDestroyItem(player, item, fromPosition, target, toPosition, isHotkey)
end

for id = 2376, 2404 do
    destroy:id(id)
end
for id = 2406, 2415 do
    destroy:id(id)
end
for id = 2417, 2419 do
    destroy:id(id)
end
for id = 2421, 2441 do
    destroy:id(id)
end
for id = 2443, 2453 do
    destroy:id(id)
end

destroy:register()