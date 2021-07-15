#!/usr/bin/env luajit

local ffi = require("ffi")

ffi.cdef [[
char * extract_file(const char * file, int32_t * size);
int tpak_free();
int read_input(const char *input);
void free(void *ptr);
]]

local tpak = ffi.load('tpak')
local fs = require('fs')
local json = require('json')
local helpers = loader.load('_helpers')
local cfg = json.decode(fs.readFileSync('config.json'))

local strings = {}

local sandbox = setmetatable({
	require = require,
	SystemGetGlobalObject = function() return end,
	Vec3 = function() return end,
	Quat = function() return end,
	u64 = function(a) return a end,
	Vec2 = function(x, y) return {x = x, y = y} end,
	IsAppInPrepareSharedDataMode = function() return false end,
	GetCvarValue = function() return end,
	GetU64Time = function() return {l = 1, h = 1} end,
	IsPC = function() return true end,
	IsMac = function() return false end,
	IsLinux = function() return false end,
	IsX360 = function() return false end,
	IsPS3 = function() return false end,
	math = math,
	sandbox = sandbox
}, {__index = _G})

local function SystemExecFile(file)
	sandbox.SystemExecFile = SystemExecFile
	sandbox.math.mod = function(a, b) return math.fmod(a, b) end
	_G.IsAppInPrepareSharedDataMode = function() return false end
	_G = sandbox
	local size = ffi.new('int32_t[1]', 0)
	local buf = tpak.extract_file(file:lower(), size)
	local str = ffi.string(buf, size[0])
	local fn, err = load(str, 'tpak', 'tb', sandbox)
	if fn == null then print(err) end
	ffi.C.free(buf)
	fn()
end

local function getSandbox() return sandbox end

local function getStrings() return strings end

local function readStrings()
	for _, lang in ipairs({{"en", "english"}, {"ru", "russian"}}) do
		local size = ffi.new('int32_t[1]', 0)
		local buf = tpak.extract_file("strings/" .. lang[2] .. "/string.txt", size)
		local str = ffi.string(buf, size[0])
		for key, value in str:gmatch "\"(.-)\"%s\"(.-)\"[\r\n]" do
			if strings[key] == nil then strings[key] = {} end
			strings[key][lang[1]] = value
		end
	end
end

local function getLowRankBuffs()
	local ret = {
		{name = "Rank", value = "", inline = true}, {name = "Resists", value = "", inline = true},
  {name = "Main Damage", value = "", inline = true}
	}
	for j, var in ipairs(sandbox.BuffByRank[17]) do
		if sandbox.Spell[var]["inherit"] == "RankBuffBase" then
			spell = sandbox.Spell[var]
			ret[1].value = ret[1].value .. j .. "\n"
			ret[2].value = ret[2].value .. spell.aura_param .. "\n"
			ret[3].value = ret[3].value .. spell.additional_auras[1].aura_param .. "\n"
		else
			spell = sandbox.Spell[var]
			ret[1].value = ret[1].value .. j .. "\n"
			ret[2].value = ret[2].value .. spell.aura_param .. "\n"
			ret[3].value = ret[3].value .. "0" .. "\n"
		end
	end
	return ret
end

local function getLowRankBuffsAll()
	local ret = {
		{name = "Rank", value = "", inline = true}, {name = "Resists", value = "", inline = true},
  {name = "Main Damage", value = "", inline = true}, {name = "Sec Damage", value = "", inline = true},
  {name = "Mod Damage", value = "", inline = true}
	}
	for j, var in ipairs(sandbox.BuffByRank[17]) do
		if sandbox.Spell[var]["inherit"] == "RankBuffBase" then
			spell = sandbox.Spell[var]
			ret[1].value = ret[1].value .. j .. "\n"
			ret[2].value = ret[2].value .. spell.aura_param .. "\n"
			ret[3].value = ret[3].value .. spell.additional_auras[1].aura_param .. "\n"
			ret[4].value = ret[4].value .. spell.additional_auras[2].aura_param .. "\n"
			ret[5].value = ret[5].value .. spell.additional_auras[3].aura_param .. "\n"
		else
			spell = sandbox.Spell[var]
			ret[1].value = ret[1].value .. j .. "\n"
			ret[2].value = ret[2].value .. spell.aura_param .. "\n"
			ret[3].value = ret[3].value .. "0" .. "\n"
		end
	end
	return ret
end

local function getSizeModifiers()
	local function formatedLine(tablename, prettyname, format)
		if tablename and format then
			coeflist = sandbox[tablename]
			return string.format(fmt, prettyname, coeflist[sandbox.ai.Signature.TINY], coeflist[sandbox.ai.Signature.SMALL],
			                     coeflist[sandbox.ai.Signature.MEDIUM], coeflist[sandbox.ai.Signature.LARGE],
			                     coeflist[sandbox.ai.Signature.HUGE])
		end
	end
	local str = {}
	fmt = "%20s %7s %7s %7s %7s %7s"
	str[1] = "```"
	str[2] = string.format(fmt, "Type", "tiny", "small", "medium", "large", "huge")
	str[3] = formatedLine("BlastWaveSignatureCoef", "Blast Wave Coef", fmt)
	str[4] = formatedLine("ExplosionShootSignatureCoef", "Explosive Shoot Coef", fmt)
	str[5] = formatedLine("RemoteHealSignatureCoef", "Remote Heal Coef", fmt)
	str[6] = formatedLine("RewardSignatureCoef", "Reward Coef", fmt)
	str[7] = "```"
	return {content = table.concat(str, "\n"), code = true}
end

tpak.read_input(cfg.data_path)
setfenv(SystemExecFile, sandbox)
SystemExecFile("scripts/m3dsys.lua")
SystemExecFile("gamedata/physics/main.lua")
SystemExecFile("gamedata/materials/main.lua")
SystemExecFile("scripts/ai/main.lua")
SystemExecFile("gamedata/def/main.lua")
readStrings()
tpak.tpak_free()

return {
	getSandbox = getSandbox,
	getStrings = getStrings,
	getLowRankBuffs = getLowRankBuffsAll,
	getSizeModifiers = getSizeModifiers
}
