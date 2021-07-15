local discordia = require("discordia")

local f = string.format
local insert, concat, sort = table.insert, table.concat, table.sort

local loader = loader

local helpers = loader.load("_helpers")
local embeds = loader.load("embeds")

local prefix = "!"

local function parseContent(content)
	if content:find(prefix, 1, true) ~= 1 then return end
	content = content:sub(prefix:len() + 1)
	local cmd, arg = content:match("(%S+)%s+(.*)")
	return cmd or content, arg
end

local cmds = {}

local function printfloat(num) return string.format("%.2f", num) end

local function onMessageCreate(msg)
	local cmd, arg = parseContent(msg.content)
	if not cmds[cmd] then return end

	if msg.author ~= msg.client.owner then
		print(msg.author.username, cmd, arg) -- TODO: better command use logging
	end
	local success, content = pcall(cmds[cmd][1], arg, msg)
	local reply, err

	if success then -- command ran successfully
		if type(content) == "string" then
			if #content > 1900 then
				reply, err = msg:reply({
					content = "Content is too large. See attached file.",
					file = {os.time() .. ".txt", content},
					code = true
				})
			elseif #content > 0 then
				reply, err = msg:reply(content)
			end
		elseif type(content) == "table" then
			if content.content and #content.content > 1900 then
				local file = {os.time() .. ".txt", content.content}
				content.content = "Content is too large. See attached file."
				content.code = true
				if content.files then
					insert(content.files, file)
				else
					content.files = {file}
				end
			end
			reply, err = msg:reply(content)
		end
	else -- command produced an error, try to send it as a message
		reply = msg:reply({content = content, code = "lua"})
	end

end

cmds["help"] = {
	function(arg, msg)
		local buf = {}
		for k, v in pairs(cmds) do if not v[3] or msg.author == msg.client.owner then insert(buf, f("%s - %s", k, v[2])) end end
		sort(buf)
		return concat(buf, "\n")
	end, "This help command.", false
}

cmds["history"] = {
	function(arg, msg)
		local args = arg:split(" ")
		local name = args[1]
		local days = args[2]
		return {embed = embeds.history(name, days)}
	end, "<name> [days] Prints the stats of a given name for the last x days", false
}

cmds["stats"] = {
	function(arg, msg)
		local name = arg
		if name == nil then return {content = "!stats requires a name"} end
		return {embed = embeds.stats(name)}
	end, "<name> Prints the player stats of a given name", false
}

cmds["lowrankbuffs"] = {
	function(arg, msg)
		if loader.modules.sc and helpers.isOwnerAuthored(msg) then
			return {
				embed = {
					title = "Low rank buffs",
					fields = loader.modules.sc.getLowRankBuffs(),
					color = discordia.Color.fromRGB(144, 136, 219).value,
					imestamp = discordia.Date():toISO("T", "Z")
				}
			}
		else
			msg:addReaction("❌")
		end
	end, "Print low rank buffs information", false
}

cmds["translate"] = {
	function(arg, msg)
		if loader.modules.sc then
			local str = loader.modules.sc.fuzzyFind(arg)
			if #str[1].value < 1 or #str[2].value < 1 then
				return "Can't find translation for " .. arg
			else
				return {
					embed = {
						fields = str,
						color = discordia.Color.fromRGB(144, 136, 219).value,
						imestamp = discordia.Date():toISO("T", "Z")
					}
				}
			end
		else
			msg:addReaction("❌")
		end
	end, "Try to translate a given string between RU and EN ", false
}

cmds["Перевести"] = cmds["translate"]

cmds["load"] = {
	function(arg, msg)
		if msg.author == msg.client.owner then
			if loader.load(arg) then
				return msg:addReaction("✅")
			else
				return msg:addReaction("❌")
			end
		end
	end, "Loads or reloads a module. Owner only.", true
}

cmds["unload"] = {
	function(arg, msg)
		if msg.author == msg.client.owner then
			if loader.unload(arg) then
				return msg:addReaction("✅")
			else
				return msg:addReaction("❌")
			end
		end
	end, "Unloads a module. Owner only.", true
}

cmds["reload"] = cmds["load"]

return {onMessageCreate = onMessageCreate}
