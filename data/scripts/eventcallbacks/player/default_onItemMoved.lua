local event = Event()
event.onItemMoved = function(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	return true
end
event:register()