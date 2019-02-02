local extractStatus = require("ExtractStatus")
local taskManager = require("TaskManager")

local function sleep(duration)
	local co = coroutine.running()
	local task = taskManager.running()
	local fulfilled = false
	delay(duration, function()
		fulfilled = true
		if coroutine.status(co) == "suspended" then
			if task ~= nil then
				task.Status, task.Value = extractStatus(coroutine.resume(co), coroutine.status(co))
			else
				coroutine.resume(co)
			end
		end
	end)
	while not fulfilled do
		coroutine.yield()
	end
end

return sleep
