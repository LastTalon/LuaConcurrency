local function sleep(duration)
	local co = coroutine.running()
	local fulfilled = false
	delay(duration, function (...)
		fulfilled = true
		if coroutine.status(co) == "suspended" then
			coroutine.resume(co, ...)
		end
	end)
	while not fulfilled do
		coroutine.yield()
	end
end

return sleep
