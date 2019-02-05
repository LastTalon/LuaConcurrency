local TaskStatus = require("StatusEnum")

local function extract(resume, status)
	if resume[1] then
		if status == "dead" then
			table.remove(resume, 1)
			return TaskStatus.Completed, resume
		end
	else
		return TaskStatus.Canceled, resume[2]
	end
	return TaskStatus.Pending, nil
end

return extract
