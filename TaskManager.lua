local taskManager = {}

local tasks = {}

function taskManager.running()
	local co = coroutine.running()
	for i, v in ipairs(tasks) do
		if co == v.Coroutine then
			return v
		end
	end
	return nil
end

function taskManager.register(task)
	table.insert(tasks, task)
end

function taskManager.deregister(task)
	local index = nil
	for i, v in ipairs(tasks) do
		if task == v then
			index = i
			break
		end
	end
	table.remove(tasks, index)
end

return taskManager
