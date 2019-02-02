local TaskStatus = require("StatusEnum")

local function extract(...)
	local args = {...}
	local status = args[#args]
	table.remove(args)
	if args[1] then
		if status == "dead" then
			table.remove(args, 1)
			return TaskStatus.Completed, args
		end
	else
		return TaskStatus.Canceled, args[2]
	end
	return TaskStatus.Pending, nil
end

return extract
