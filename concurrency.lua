local concurrency = {}

concurrency._version = "0.2.0"

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

function Task:Then(fulfill, reject)
	local fulfillTask
	local rejectTask
	
	if fulfill ~= nil and type(fulfill) == "function" then
		fulfillTask = concurrency.task(fulfill)
	end
	
	if reject ~= nil and type(reject) == "function" then
		rejectTask = concurrency.task(reject)
	end
	
	local deferred = concurrency.task(function()
		concurrency.sleep()
		self:Wait()
		if self.Status == concurrency.TaskStatus.Completed then
			if fulfillTask ~= nil then
				fulfillTask:Start(unpack(self.Value))
			end
		else
			if rejectTask ~= nil then
				rejectTask:Start(self.Value)
			end
		end
	end)
	deferred:Start()
	
	return fulfillTask, rejectTask
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

concurrency.yield = coroutine.yield
concurrency.sleep = require("sleep.sleep")

return concurrency
