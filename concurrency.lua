local concurrency = {}
local Task = require("Task")

concurrency._version = "0.2.2"
concurrency.TaskStatus = require("StatusEnum")
concurrency.sleep = Task.sleep
concurrency.yield = coroutine.yield

local function argTypeOrDie(arg, datatype, functionName, argPosition)
	local t = type(arg)
	if t ~= datatype then
		error("bad argument #" .. argPosition .. " to '" .. functionName .. "' (" ..datatype .. " expected, got " .. t .. ")", 3)
	end
end

function concurrency.task(fn)
	argTypeOrDie(fn, "function", "task", 1)
	
	return Task.new(fn)
end

function concurrency.async(fn)
	argTypeOrDie(fn, "function", "async", 1)
	
	local asyncFn = function(...)
		local task = concurrency.task(fn)
		task:Start(...)
		return task
	end
	
	return asyncFn
end

function concurrency.await(task)
	argTypeOrDie(task, "table", "await", 1)
	
	if task.Status == concurrency.TaskStatus.Pending then
		concurrency.yield()
		task:Wait()
	end
	
	if task.Status == concurrency.TaskStatus.Completed then
		return unpack(task.Value)
	else
		error(task.Value, 2)
	end
end

function concurrency.callback(fn)
	argTypeOrDie(fn, "function", "callback", 1)
	
	local callbackFn = function(...)
		local task = concurrency.task(fn)
		local args = {...}
		local fulfill
		local reject
		if type(args[#args]) == "function" then
			fulfill = args[#args]
			table.remove(args)
			if type(args[#args]) == "function" then
				reject = fulfill
				fulfill = args[#args]
				table.remove(args)
			end
		end
		
		task:Start(unpack(args))
		task:Then(fulfill, reject)
		
		return task
	end
	
	return callbackFn
end

return concurrency
