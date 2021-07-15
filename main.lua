#!/usr/bin/env luvit

local discordia = require("discordia")
local slash = require("discordia-slash")
slash.constructor()
local fs = require("fs")
local json = require("json")
local http = require("coro-http")
local client = discordia.Client():useSlashCommands()

local cfg = json.decode(fs.readFileSync("config.json"))

discordia.extensions()
local loader = require("./loader")
local modules = loader.modules

client:on("slashCommandsReady", function()
	local test_guild = nil
	if cfg.test_guild_id ~= "" then test_guild = client:getGuild(cfg.test_guild_id) end
	print("Logged in as " .. client.user.username)
	local _stats_cmd = slash.new("stats", "Print statistics of a Player")
	_stats_cmd:option("player", "Player name", slash.enums.optionType.string, true)
	_stats_cmd:callback(function(ia, params, cmd)
		if params.player then ia:reply({embeds = {modules.embeds.stats(params.player)}}) end
	end)
	client:slashCommand(_stats_cmd:finish())
	local _lowrank_cmd = slash.new("lowrankbuffs", "Print Low Rank Buffs")
	_lowrank_cmd:callback(function(ia, params, cmd)
		if modules.sc then
			ia:reply({
				embeds = {
					{
						title = "Low rank buffs",
						fields = modules.sc.getLowRankBuffs(),
						color = discordia.Color.fromRGB(144, 136, 219).value,
						timestamp = discordia.Date():toISO("T", "Z")
					}
				}
			})
		else
			ia:reply("❌")
		end
	end)
	client:slashCommand(_lowrank_cmd:finish())
	local _size_mod_cmd = slash.new("sizemodifiers", "Print Ship Size modifers")
	_size_mod_cmd:callback(function(ia, params, cmd)
		if modules.sc then
			ia:reply(modules.sc.getSizeModifiers())
		else
			ia:reply("❌")
		end
	end)
	client:slashCommand(_size_mod_cmd:finish())
	local _help_mod_cmd = slash.new("help", "Helps Jona")
	_help_mod_cmd:callback(function(ia, params, cmd) ia:reply("Git Gud Jona") end)
	client:slashCommand(_help_mod_cmd:finish())
	local _history_cmd = slash.new("history", "Print statistics for the last x days")
	_history_cmd:option("player", "Player name", slash.enums.optionType.string, true)
	_history_cmd:option("days", "Days", slash.enums.optionType.integer, false)
	_history_cmd:callback(function(ia, params, cmd)
		if params.player then ia:reply({embeds = {modules.embeds.history(params.player, params.days)}}) end
	end)
	client:slashCommand(_history_cmd:finish())
	
	local _request_cmd = slash.new("request", "Request a link for a request.")
	_request_cmd:callback(function(ia, params, cmd) ia:reply("https://github.com/Johnnynator/Jeff") 
	end)
	client:slashCommand(_request_cmd:finish())
		
	local _chad_cmd = slash.new("chad", "Determines if you're a chad.")
	_chad_cmd:callback(function(ia, params, cmd)
	_chad_cmd:option("player", "Player name", slash.enums.optionType.string, true)
		if args.name == "Jona" OR args.name == "John" then
			ia:reply("Yes, he's a chad!")
		else 
			ia:reply("No, you're not a chad. Better luck next time!")
		end
	end)
	client:slashCommand(_chad_cmd:finish())
end)

client:on("messageCreate", function(message) if modules.commands then modules.commands.onMessageCreate(message) end end)

client:run(cfg.token)
