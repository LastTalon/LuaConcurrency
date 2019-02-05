local asynchronous = require("Asynchronous")

function LazyReturn(data)
	asynchronous.sleep(3)
	return data
end

local name = asynchronous.async(LazyReturn)("World")

local greeting = "Hello, "
local ending = "!"

local sentence = greeting .. asynchronous.await(name) .. ending
print(sentence)
