local discordia = require("discordia")
local http = require("coro-http")
local json = require("json")

local function printfloat(num) return string.format("%.2f", num) end

local errorColor = discordia.Color.fromRGB(254, 25, 25).value
local scBase = "https://gmt.star-conflict.com/pubapi/v1/userinfo.php"
local badboyBase = "http://www.badboytool.com/tool/sc/api.php"

local function stats(name)
	local link = scBase .. "?nickname=" .. name
	local result, body = http.request("GET", link)
	body = json.parse(body)
	local data = body["data"]
	if body["code"] ~= 0 then
		return {
			title = "Error: " .. body["result"],
			fields = {{name = "Player name", value = name, inline = true}, {name = "Description", value = body["text"]}},
			color = errorColor,
			timestamp = discordia.Date():toISO("T", "Z")
		}
	else
		return {
			title = "Player stats of " .. data["nickName"],
			fields = {
				{name = "Nickname", value = data["nickName"], inline = true}, {
					name = "Corporation",
					value = data["clan"] and (data["clan"]["name"] .. " [" .. data["clan"]["tag"] .. "]") or "None",
					inline = true
				}, {
					name = "PvP Stats",
					value = data["pvp"] and "Games: " .. data["pvp"]["gamePlayed"] .. "\nGames Won: " .. data["pvp"]["gameWin"] ..
									"\nGames Lost: " .. data["pvp"]["gamePlayed"] - data["pvp"]["gameWin"] .. "\nKills: " ..
									data["pvp"]["totalKill"] .. "\nAssists: " .. data["pvp"]["totalAssists"] .. "\nDeaths: " ..
									data["pvp"]["totalDeath"] .. "\nK/D: " .. printfloat(data["pvp"]["totalKill"] / data["pvp"]["totalDeath"]) ..
									"\nDPS: " .. printfloat(data["pvp"]["totalDmgDone"] / data["pvp"]["totalBattleTime"] * 1000) or
									"No PvP battles recorded",
					inline = false
				}, {
					name = "Avg per Battle",
					value = data["pvp"] and "Kills: " .. printfloat(data["pvp"]["totalKill"] / data["pvp"]["gamePlayed"]) ..
									"\nAssists: " .. printfloat(data["pvp"]["totalAssists"] / data["pvp"]["gamePlayed"]) .. "\nDeaths: " ..
									printfloat(data["pvp"]["totalDeath"] / data["pvp"]["gamePlayed"]) or "No PvP battles recorded",
					inline = false
				}
			},
			color = discordia.Color.fromRGB(144, 136, 219).value,
			timestamp = discordia.Date():toISO("T", "Z")
		}
	end
end

local function history(name, days)
	if days == nil or tonumber(days) == nil or tonumber(days) < 1 then
		days = 7
	elseif tonumber(days) > 30 then
		days = 30
	else
		days = tonumber(math.floor(tonumber(days) + 0.5))
	end

	if name == nil then
		return {
			title = "Error: No Name",
			fields = {{name = "Description", value = "!history requires at least a name.", inline = true}},
			color = errorColor,
			timestamp = discordia.Date():toISO("T", "Z")
		}
	end
	local curlink = scBase .. "?nickname=" .. name
	local histlink = badboyBase .. "?get=all&limit=" .. ((days > 1) and days - 1 or days) .. "&nickname=" .. name
	local hist
	local curr
	histres, histreq = http.request("GET", histlink)
	currres, currreq = http.request("GET", curlink)
	if histres.code ~= 200 or currres.code ~= 200 then
		return {
			title = "Error: Invalid HTTP Status code",
			fields = {
				{name = "gmt.star-conflict.con", value = curres.code, inline = true},
    {name = "badboytool.com", value = histres.code, inline = true}
			},
			color = errorColor,
			timestamp = discordia.Date():toISO("T", "Z")
		}
	end
	hist = json.parse(histreq)
	curr = json.parse(currreq)
	if curr["code"] ~= 0 then
		return {
			title = "Error: " .. curr["result"],
			fields = {{name = "Player name", value = name, inline = true}, {name = "Description", value = curr["text"]}},
			color = errorColor,
			timestamp = discordia.Date():toISO("T", "Z")
		}
	elseif hist["code"] ~= 0 then
		return {
			title = "Error: " .. hist["text"],
			fields = {{name = "Player name", value = name, inline = true}, {name = "Days", value = days, inline = true}},
			color = errorColor,
			timestamp = discordia.Date():toISO("T", "Z")
		}
	else
		local gamePlayed, gameWin, totalKills, totalAssists, totalDeath = 0, 0, 0, 0, 0
		local totalDmgDone, totalBattleTime = 0, 0
		-- Discordia's date library can only parese dates in their complete extended representation
		local lastDate = 0
		for year, month, day in hist["data"]["lastCheck"]:gmatch "(%w+)-(%w+)-(%w+)" do
			lastDate = year .. "-" .. month .. "-" .. day - 1
		end
		local savedStats = hist["data"]["history"]["absolute"][lastDate]
		-- Diff to today stats
		gamePlayed = curr["data"]["pvp"]["gamePlayed"] - savedStats["pvp"]["gamePlayed"]
		gameWin = curr["data"]["pvp"]["gameWin"] - savedStats["pvp"]["gameWin"]
		totalKills = curr["data"]["pvp"]["totalKill"] - savedStats["pvp"]["totalKill"]
		totalAssists = curr["data"]["pvp"]["totalAssists"] - savedStats["pvp"]["totalAssists"]
		totalDeath = curr["data"]["pvp"]["totalDeath"] - savedStats["pvp"]["totalDeath"]
		totalBattleTime = curr["data"]["pvp"]["totalBattleTime"] - savedStats["pvp"]["totalBattleTime"]
		totalDmgDone = curr["data"]["pvp"]["totalDmgDone"] - savedStats["pvp"]["totalDmgDone"]
		if days > 1 then
			for date, val in pairs(hist["data"]["history"]["daily"]) do
				gamePlayed = gamePlayed + val["pvp"]["gamePlayed"]
				gameWin = gameWin + val["pvp"]["gameWin"]
				totalKills = totalKills + val["pvp"]["totalKill"]
				totalAssists = totalAssists + val["pvp"]["totalAssists"]
				totalDeath = totalDeath + val["pvp"]["totalDeath"]
				totalBattleTime = totalBattleTime + val["pvp"]["totalBattleTime"]
				totalDmgDone = totalDmgDone + val["pvp"]["totalDmgDone"]
			end
		end
		return {
			title = "Player stats of " .. hist["data"]["nickName"] .. " (" .. days .. "d)",
			fields = {
				{
					name = "PvP stats",
					value = "Battles: " .. gamePlayed .. "\nGame Won: " .. gameWin .. "\nGame Lost: " .. gamePlayed - gameWin ..
									"\nKills: " .. totalKills .. "\nAssists: " .. totalAssists .. "\nDeaths: " .. totalDeath .. "\nK/D: " ..
									printfloat(totalKills / totalDeath) .. "\nDPS: " .. printfloat(totalDmgDone / totalBattleTime * 1000) ..
									"\nTime in Battle: " .. discordia.Time.fromMilliseconds(totalBattleTime):toString(),
					inline = false
				}
			},
			footer = {text = "Date: " .. lastDate},
			color = discordia.Color.fromRGB(144, 136, 219).value,
			timestamp = discordia.Date():toISO("T", "Z")
		}
	end
end

return {history = history, stats = stats}
