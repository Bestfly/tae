-- jijilu <jijilu.huang@mangocity.com> 20140527 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- ctrip agent service of crawler for bestfly service
-- load library
local socket = require 'socket'
local http = require 'socket.http'
local JSON = require 'cjson'
local md5 = require 'md5'
local zlib = require 'zlib'
local base64 = require 'base64'
local crypto = require 'crypto'
-- local client = require 'soap.client'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
-- local xml = require 'LuaXml'
--[[
local redis = require 'redis'
local params = {
    host = 'sin.bestfly.cn',
    port = 61088,
}
local client = redis.connect(params)
client:select(0) -- for testing purposes
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
--]]
local deflate = require 'compress.deflatelua'
-- local baselua = require 'base64'
-- local t = {}
-- t.input = baselua.decode("string", "H4sIAAAAAAAACw3DhwnAMAwAMP8P2Rdk9s1KoBQR2WK12R1Ol9vj9fn5A/luZ4Y4AAAA")
-- t.output = function(byte) print(string.char(byte)) end
-- deflate.gunzip(t)
-- print("+++++++++++++++++")
-- originality
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "No response because you has inputted airports"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "Get Prices from extension is no response"});
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end
function sleep(n)
   socket.select(nil, nil, n)
end
-- Cloud set.
function urlencode(s) return s and (s:gsub("[^a-zA-Z0-9.~_-]", function (c) return string.format("%%%02x", c:byte()); end)); end
function urldecode(s) return s and (s:gsub("%%(%x%x)", function (c) return char(tonumber(c,16)); end)); end
local function _formencodepart(s)
	return s and (s:gsub("%W", function (c)
		if c ~= " " then
			return format("%%%02x", c:byte());
		else
			return "+";
		end
	end));
end
function formencode(form)
	local result = {};
 	if form[1] then -- Array of ordered { name, value }
 		for _, field in ipairs(form) do
 			-- t_insert(result, _formencodepart(field.name).."=".._formencodepart(field.value));
			table.insert(result, field.name .. "=" .. tostring(field.value));
 		end
 	else -- Unordered map of name -> value
 		for name, value in pairs(form) do
 			-- table.insert(result, _formencodepart(name).."=".._formencodepart(value));
			table.insert(result, name .. "=" .. tostring(value));
 		end
 	end
 	return table.concat(result, "&");
end
function pairsByKeys (t, f)
	local a = {}
	for m,n in pairs(t) do
		table.insert(a, n)
	end
	table.sort(a, f)
	local i = 0-- iterator variable
	local item = function ()-- iterator function
		i = i + 1
		if a[i] == nil then
			return nil
		else 
			return a[i], t[a[i]]
		end
	end
	return item
end
function parseargs(s)
	local arg = {}
	string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
		arg[w] = a
	end)
	return arg
end
function collect(s)
	local stack = {}
	local top = {}
	table.insert(stack, top)
	local ni,c,label,xarg, empty
	local i, j = 1, 1
	while true do
		ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
		if not ni then break end
		local text = string.sub(s, i, ni-1)
		if not string.find(text, "^%s*$") then
	  		table.insert(top, text)
		end
		if empty == "/" then  -- empty element tag
	  		table.insert(top, {label=label, xarg=parseargs(xarg), empty=1})
		elseif c == "" then   -- start tag
	  		top = {label=label, xarg=parseargs(xarg)}
	  	  	table.insert(stack, top)   -- new level
		else  -- end tag
	  		local toclose = table.remove(stack)  -- remove top
	  	  	top = stack[#stack]
	  	  	if #stack < 1 then
	    		error("nothing to close with "..label)
	  	  	end
	  	  	if toclose.label ~= label then
	    		error("trying to close "..toclose.label.." with "..label)
	  	  	end
	  	 	table.insert(top, toclose)
		end
		i = j+1
	end
	local text = string.sub(s, i)
	if not string.find(text, "^%s*$") then
		table.insert(stack[#stack], text)
	end
	if #stack > 1 then
		error("unclosed "..stack[#stack].label)
	end
	return stack[1]
end
-- Main
local ad = "54807975-9730-4850-b6b4-862128352ab4"
local ak = "856474380e125a41" 
local xv = "20111128102912"
local GetProvinceList = "GetProvinceList"
local GetSceneryList = "GetSceneryList"
local GetCityList = "GetCityListByProvinceId"
local sn = GetCityList
-- local org = string.sub(arg[1], 1, 3);
-- local dst = string.sub(arg[1], 5, 7);
-- local tkey = string.sub(arg[1], 9, -3);
-- local expiret = os.time({year=string.sub(tkey, 1, 4), month=tonumber(string.sub(tkey, 5, 6)), day=tonumber(string.sub(tkey, 7, 8)), hour="00"})
-- local date = string.sub(arg[1], 9, 12) .. "-" .. string.sub(arg[1], 13, 14) .. "-" .. string.sub(arg[1], 15, 16);
local ts = os.date("%Y-%m-%d %X", os.time()) .. ".000";
-- local ts = "2014-06-06 20:13:18.283"
-- LY.com
local baseurl = "http://tcopenapi.17usoft.com"
local scenuri = "/Handlers/General/AdministrativeDivisionsHandler.ashx"
-- local scenuri = "/handlers/scenery/queryhandler.ashx"
-- {"Version=" + version,"AccountID=" + accountId, "ServiceName="+methodName, "ReqTime="+ reqTime}
local signtab = { "Version=" .. xv, "AccountID=" .. ad, "ServiceName=" .. sn, "ReqTime=" .. ts }
-- print(JSON.encode(signtab))
local signstr = ""
for k, v in pairsByKeys(signtab) do
	signstr = signstr .. k .. "&"
end
signstr = string.sub(signstr, 0, -2) .. ak
-- print(signstr)
local signmd5 = md5.sumhexa(signstr)
-- print("-----------------")
print(signmd5)
print(signstr)
-- Signature=Md5(TimeStamp+AllianceID+MD5(密钥).ToUpper()+SID+RequestType).ToUpper()
-- local ts = "1380250839"
-- local sign = string.upper(md5.sumhexa(ts .. unicode .. string.upper(md5.sumhexa(apikey)) .. siteid .. "OTA_IntlFlightSearch"))
print("-----------------")
-- Get city
print(ts)
-- print(sign)
-- print(string.upper(org), string.upper(dst), date, today)
local Citybody = ([=[<provinceId>%s</provinceId>]=]):format(2)
local Scenerybody = ([=[
	<clientIp>127.0.0.1</clientIp>
	<cityId>321</cityId>
	<page>3</page>
	<pageSize>1</pageSize>]=])
print("------------------------------------------")
local reqxml = ([=[<?xml version='1.0' encoding='utf-8'?>
<request>
	<header>
		<version>%s</version>
		<accountID>%s</accountID>
		<serviceName>%s</serviceName>
		<digitalSign>%s</digitalSign>
		<reqTime>%s</reqTime>
	</header>
	<body>
		%s
	</body>
</request>]=]):format(xv, ad, sn, signmd5, ts, Citybody)
-- reqxml = string.gsub(reqxml, "<", "&lt;")
print(reqxml)
print("-----------------")
-- init response table
local respbody = {};
-- local hc = http:new()
local body, code, headers, status = http.request {
-- local ok, code, headers, status, body = http.request {
	-- url = "http://cloudavh.com/data-gw/index.php",
	url = baseurl .. scenuri,
	-- proxy = "http://10.123.74.137:808",
	-- proxy = "http://" .. tostring(arg[2]),
	timeout = 3000,
	method = "POST", -- POST or GET
	-- add post content-type and cookie
	-- headers = { ["Content-Type"] = "application/x-www-form-urlencoded", ["Content-Length"] = string.len(form_data) },
	-- headers = { ["Host"] = "flight.itour.cn", ["X-AjaxPro-Method"] = "GetFlight", ["Cache-Control"] = "no-cache", ["Accept-Encoding"] = "gzip,deflate,sdch", ["Accept"] = "*/*", ["Origin"] = "chrome-extension://fdmmgilgnpjigdojojpjoooidkmcomcm", ["Connection"] = "keep-alive", ["Content-Type"] = "application/json", ["Content-Length"] = string.len(JSON.encode(request)), ["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.65 Safari/537.36" },
	headers = {
		["Host"] = "tcopenapi.17usoft.com",
		-- ["SOAPAction"] = "http://ctrip.com/Request",
		["Cache-Control"] = "no-cache",
		["Accept-Encoding"] = "gzip",
		["Accept"] = "*/*",
		["Connection"] = "keep-alive",
		["Content-Type"] = "text/xml; charset=utf-8",
		["Content-Length"] = string.len(reqxml),
		["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.65 Safari/537.36"
	},
	-- body = formdata,
	-- source = ltn12.source.string(form_data);
	source = ltn12.source.string(reqxml),
	sink = ltn12.sink.table(respbody)
}
if code == 200 then
	local resxml = "";
	local reslen = table.getn(respbody)
	-- print(reslen)
	for i = 1, reslen do
		-- print(respbody[i])
		resxml = resxml .. respbody[i]
	end
	-- resxml = deflate.gunzip(resxml)
	-- change to use compress.deflatelua
	local output = {}
	deflate.gunzip {
	  input = resxml,
	  output = function(byte) output[#output+1] = string.char(byte) end
	}
	resxml = table.concat(output)
	-- resxml = zlib.decompress(resxml)
	-- resxml = string.gsub(resxml, "&lt;", "<")
	-- resxml = string.gsub(resxml, "&gt;", ">")
	print(resxml)
	-- local pr_xml = xml.eval(resxml);
	-- local xscene = pr_xml:find("response");
else
	-- debug
	print(code,status)
end