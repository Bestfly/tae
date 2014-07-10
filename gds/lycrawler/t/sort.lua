local JSON = require 'cjson'
-- load library
local socket = require 'socket'
local http = require 'socket.http'

lines = {
luaH_set = 10,
luaH_get = 24,
luaH_present = 48,
}

a = {}
for n in pairs(lines) do table.insert(a, n) end
table.sort(a)
for i,n in ipairs(a) do print(n) end



-- Main
local ad = "54807975-9730-4850-b6b4-862128352ab4"
local ak = "856474380e125a41" 
local xv = "20111128102912"
local sn = "GetSceneryList"
local ts = os.date("%Y-%m-%d %X", os.time()) .. ".000";
local signtab = { "Version=" .. xv, "AccountID=" .. ad, "ServiceName=" .. sn, "ReqTime=" .. ts }

a = {}
for k,v in pairs(signtab) do table.insert(a, v) end
table.sort(a)
for i,n in ipairs(a) do print(n) end

local a = "<![CDATA[路南区]]>"


-- a = string.match(a, '[\x80-\xff]', 2)

print(a)
print(os.time())
-- 1403080684
-- 1403080560459
function parseargs(s)
	local arg = {}
	string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
		arg[w] = a
	end)
	return arg
end
function unescape (s)
  s = string.gsub(s, "+", " ")
  s = string.gsub(s, "%%(%x%x)", function (h)
        return string.char(tonumber(h, 16))
      end)
  return s
end
s = "queryParamVO.cabinLevel=&queryParamVO.useAdvanced=&queryParamVO.position=4&queryParamVO.positionRet=4&queryParamVO.tripSegment=&queryParamVO.tripType=ow&queryParamVO.depAirport=&queryParamVO.arrAirport=&queryParamVO.depCityCn=%E6%B7%B1%E5%9C%B3&queryParamVO.depCity=SZX&queryParamVO.arrCityCn=%E4%B8%8A%E6%B5%B7&queryParamVO.arrCity=SHA&queryParamVO.depDate=2014-08-09&suppliers=CZS%2FHUS"

cgi = {}
function decode (s)
  for name, value in string.gfind(s, "([^&=]+)=([^&=]+)") do
    name = unescape(name)
    value = unescape(value)
    cgi[name] = value
  end
end
decode (s)

print(JSON.encode(cgi))

local a = "38.80"
local b = "38.00"
print(tonumber(a),tonumber(b))

package.path = "/usr/local/webserver/lua/lib/?.lua;";

local redis = require 'redis'
--[[
local params = {
    host = '127.0.0.1',
    port = 6399,
}
local client = redis.connect(params)
client:select(0) -- for testing purposes
--]]
-- commands defined in the redis.commands table are available at module
-- level and are used to populate each new client instance.
redis.commands.hset = redis.command('hset')
redis.commands.hset = redis.command('hget')
redis.commands.incr = redis.command('incr')
redis.commands.setnx = redis.command('setnx')
redis.commands.hset = redis.command('hsetnx')
redis.commands.sadd = redis.command('sadd')
redis.commands.zadd = redis.command('zadd')
redis.commands.smembers = redis.command('smembers')
redis.commands.keys = redis.command('keys')
redis.commands.sdiff = redis.command('sdiff')

local preview = {
    host = '10.10.42.31',
    port = 6399,
}
local precli = redis.connect(preview)
precli:select(0)
--[[
local res, err = client:keys('sce:lycom:city:*')
if not res then
	print("+++++++++error++++++++")
else
	-- print(type(res))
	local j = 0
	for i = 1, table.getn(res) do
		-- print(res[i])
		r,e = client:hlen(res[i])
		-- print(r)
		j = j + r
	end
	print(j)
end

local luasql = require "luasql.mysql"
local env = assert(luasql.mysql())
-- base_flights_city
local con = assert (env:connect("ticketbase", "rhomobi_dev", "b6x7p6b6x7p6", "localhost", 3306))
-- local con = assert (env:connect("biyifei_base", "rhomobi_dev", "b6x7p6b6x7p6", "localhost", 3306))
con:execute("SET NAMES utf8")
local sqlcmd = "SELECT `CityId`, `sLyId` FROM `scenery`";
local cur = assert (con:execute(sqlcmd))
local row = cur:fetch ({}, "a")
while row do
	print(row.CityId,row.sLyId)
	local res, err = client:hset('sce:lycom:city:' .. row.CityId, row.sLyId, 0)
	if not res then
		print("-------Failed to hset " .. row.CityId .. ":" .. row.sLyId .. "--------")
	else
		print("-------well done " .. row.CityId .. ":" .. row.sLyId .. "--------")
	end
	row = cur:fetch (row, "a")
end
cur:close()
--]]

local res, err = precli:keys('sce:lycom:city:*')
if not res then
	print("+++++++++error++++++++")
else
	-- print(type(res))
	-- local j = 0
	for i = 1, table.getn(res) do
		-- print(res[i])
		-- r,e = precli:hlen(res[i])
		r,e = precli:hkeys(res[i])
		-- print(r)
		for k,v in pairs(r) do
			-- print(v)
			-- 初始化待处理为1
			r,e = precli:hget(res[i], v)
			-- print("+++++++++++++++++")
			-- print(type(res))
			if tonumber(r) ~= 0 then
				print(res[i],v)
			end
		end
	end
	-- print(j)
end