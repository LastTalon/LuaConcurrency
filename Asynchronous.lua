local asynchronous = {}
local Task = require("Task")

asynchronous._version = "0.2.2"
asynchronous.TaskStatus = require("StatusEnum")
asynchronous.sleep = Task.sleep
asynchronous.yield = coroutine.yield

local function argTypeOrDie(arg, datatype, functionName, argPosition)
	local t = type(arg)
	if t ~= datatype then
		error("bad argument #" .. argPosition .. " to '" .. functionName .. "' (" ..datatype .. " expected, got " .. t .. ")", 3)
	end
end

function asynchronous.task(fn)
	argTypeOrDie(fn, "function", "task", 1)
	
	return Task.new(fn)
end

function asynchronous.async(fn)
	argTypeOrDie(fn, "function", "async", 1)
	
	local asyncFn = function(...)
		local task = asynchronous.task(fn)
		task:Start(...)
		return task
	end
	
	return asyncFn
end

function asynchronous.await(task)
	argTypeOrDie(task, "table", "await", 1)
	
	if task.Status == asynchronous.TaskStatus.Pending then
		task:Wait()
	end
	
	if task.Status == asynchronous.TaskStatus.Completed then
		return unpack(task.Value)
	else
		error(task.Value, 2)
	end
end

function asynchronous.callback(fn)
	argTypeOrDie(fn, "function", "callback", 1)
	
	local callbackFn = function(...)
		local task = asynchronous.task(fn)
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

return asynchronous
