local discordia = require("discordia")

local Date, Time = discordia.Date, discordia.Time

local function isOwnerAuthored(msg) return msg.author == msg.client.owner end

local function isBotAuthored(msg) return msg.author == msg.client.user end

local function canBulkDelete(msg) return msg.id > (Date() - Time.fromWeeks(2)):toSnowflake() end

local function isOnline(member) return member.status ~= "offline" end

return {
	isBotAuthored = isBotAuthored,
	isOwnerAuthored = isOwnerAuthored,
	canBulkDelete = canBulkDelete,
	isOnline = isOnline
}
