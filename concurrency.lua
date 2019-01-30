local concurrency = {}

concurrency._version = "0.1.2"

concurrency.TaskStatus = {
	["Pending"] = 0,
	["Completed"] = 1,
	["Canceled"] = 2
}

local function argTypeOrDie(arg, datatype, functionName, argPosition)
	local t = type(arg)
	if t ~= datatype then
		error("bad argument #" .. argPosition .. " to '" .. functionName .. "' (" ..datatype .. " expected, got " .. t .. ")", 3)
	end
end

local Task = {}
Task.__index = Task

function Task:Completed()
	return self.Status == concurrency.TaskStatus.Completed
end

function Task:Canceled()
	return self.Status == concurrency.TaskStatus.Canceled
end

function Task:Start(...)
	if self.Status == concurrency.TaskStatus.Pending then
		local resume = {coroutine.resume(self.Coroutine, ...)}
		if resume[1] then
			if coroutine.status(self.Coroutine) == "dead" then
				table.remove(resume, 1)
				self.Value = resume
				self.Status = concurrency.TaskStatus.Completed
			end
		else
			self.Value = resume[2]
			self.Status = concurrency.TaskStatus.Canceled
		end
	end
end

function Task:Wait()
	while self.Status == concurrency.TaskStatus.Pending do
		self:Start()
		concurrency.sleep()
	end
end

function Task:Continue(fn, ...)
	argTypeOrDie(fn, "function", "Continue", 1)
	
	self:Wait()
	if self.Status == concurrency.TaskStatus.Completed then
		fn(...)
	else
		error(self.Value, 2)
	end
end

function concurrency.task(fn)
	argTypeOrDie(fn, "function", "task", 1)
	
	local self = setmetatable({}, Task)
	self.Coroutine = coroutine.create(fn)
	self.Status = concurrency.TaskStatus.Pending
	
	return self
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
		local deferred = concurrency.task(function(...)
			concurrency.sleep()
			local task = concurrency.task(fn)
			local args = {...}
			local call = type(args[#args]) == "function"
			local callback
			if call then
				callback = table.remove(args)
			end
			task:Start(unpack(args))
			task:Wait()
			if call then
				callback(unpack(task.Value))
			end
		end)
		deferred:Start(...)
	end
	
	return callbackFn
end

concurrency.yield = coroutine.yield
concurrency.sleep = require("sleep.sleep")

return concurrency
