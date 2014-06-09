local base64 = require 'base64'
function urlencode(s) return s and (s:gsub("[^a-zA-Z0-9.~_-]", function (c) return string.format("%%%02x", c:byte()); end)); end
function urldecode(s) return s and (s:gsub("%%(%x%x)", function (c) return char(tonumber(c,16)); end)); end
-- init task of localcity.
local luasql = require "luasql.mysql"
local env = assert(luasql.mysql())
local con = assert (env:connect("biyifei_base", "rhomobi_dev", "b6x7p6b6x7p6", "localhost", 3306))
con:execute("SET NAMES utf8")
local sqlcmd = "SELECT `city_code`, `city_name` FROM `localcitys`";
local cur = assert (con:execute(sqlcmd))
local row = cur:fetch ({}, "a")
local citycn = {};
local cityex = {};
while row do
	-- print(row.city_code)
	table.insert(citycn, row.city_code)
	-- cityex[base64.encode(row.city_name)] = row.city_code
	cityex[row.city_code] = base64.encode(row.city_name)
	-- print(row.city_name)
	row = cur:fetch (row, "a")
end
cur:close()
local lencn = table.getn(citycn)
print(lencn)
for k,v in pairs(cityex) do
	print(k, base64.decode(v))
end