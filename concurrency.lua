local concurrency = {}

concurrency._version = "0.1.1"

concurrency.TaskStatus = {
	["Pending"] = 0,
	["Completed"] = 1,
	["Canceled"] = 2
}

local function taskCompleted(self)
	return self.Status == concurrency.TaskStatus.Completed
end

local function taskCanceled(self)
	return self.Status == concurrency.TaskStatus.Canceled
end

local function taskStart(self, ...)
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

local function taskWait(self)
	while self.Status == concurrency.TaskStatus.Pending do
		self:Start()
		concurrency.sleep()
	end
end

local function taskContinue(self, fn, ...)
	local t = type(fn)
	if t ~= "function" then
		error("bad argument #1 to 'Continue' (function expected, got " .. t .. ")", 2)
	end
	
	self:Wait()
	if self.Status == concurrency.TaskStatus.Completed then
		fn(...)
	else
		error(task.Value, 2)
	end
end

function concurrency.task(fn)
	local t = type(fn)
	if t ~= "function" then
		error("bad argument #1 to 'task' (function expected, got " .. t .. ")", 2)
	end
	
	local o = {}
	o.Coroutine = coroutine.create(fn)
	o.Status = concurrency.TaskStatus.Pending
	o.Value = nil
	o.Completed = taskCompleted
	o.Canceled = taskCanceled
	o.Start = taskStart
	o.Wait = taskWait
	o.Continue = taskContinue
	
	return o
end

function concurrency.async(fn)
	local t = type(fn)
	if t ~= "function" then
		error("bad argument #1 to 'async' (function expected, got " .. t .. ")", 2)
	end
	
	local asyncFn = function(...)
		local task = concurrency.task(fn)
		task:Start(...)
		return task
	end
	
	return asyncFn
end

function concurrency.await(task)
	local t = type(task)
	if t ~= "table" then
		error("bad argument #1 to 'await' (table expected, got " .. t .. ")", 2)
	end
	
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

concurrency.yield = coroutine.yield

function concurrency.sleep(time)
	-- Sleep here if able.
	
	-- Lua provides no sleep functionality by default. Many APIs provide this and
	-- it should be added for each API this library is included in.
end

return concurrency
