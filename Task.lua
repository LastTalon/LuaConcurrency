local extractStatus = require("ExtractStatus")
local taskManager = require("TaskManager")

local Task = {}
Task.__index = Task

Task.TaskStatus = require("StatusEnum")
Task.sleep = require("Sleep")

function Task.new(fn)
	local self = setmetatable({}, Task)
	if type(fn) == "function" then
		self.Coroutine = coroutine.create(fn)
	end
	self.Status = Task.TaskStatus.Pending
	self.Persist = false
	
	taskManager.register(self)
	return self
end

function Task:Completed()
	return self.Status == Task.TaskStatus.Completed
end

function Task:Canceled()
	return self.Status == Task.TaskStatus.Canceled
end

function Task:Start(...)
	if self.Status == Task.TaskStatus.Pending and coroutine.status(self.Coroutine) == "suspended" then
		self.Status, self.Value = extractStatus(coroutine.resume(self.Coroutine, ...), coroutine.status(self.Coroutine))
	end
	if not self.Persist and self.Status ~= Task.TaskStatus.Pending then
		local co = coroutine.create(function()
			Task.sleep()
			self:Destroy()
		end)
		coroutine.resume(co)
	end
end

function Task:Wait()
	while self.Status == Task.TaskStatus.Pending do
		Task.sleep()
		self:Start()
	end
end

function Task:Then(fulfill, reject)
	local fulfillTask
	local rejectTask
	
	if fulfill ~= nil and type(fulfill) == "function" then
		fulfillTask = Task.new(fulfill)
	end
	
	if reject ~= nil and type(reject) == "function" then
		rejectTask = Task.new(reject)
	end
	
	local deferred = Task.new(function()
		self:Wait()
		if self.Status == Task.TaskStatus.Completed then
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

function Task:Persist(persist)
	persist = persist or true
	if type(persist) == "boolean" then
		self.Persist = persist
	end
end

function Task:Destroy()
	self.Coroutine = nil
	self.Status = nil
	self.Value = nil
	taskManager.deregiser(self)
end

return Task
