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
local xml = require 'LuaXml'

local redis = require 'redis'
local params = {
    host = '127.0.0.1',
    port = 6399,
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
function retry(mission)
	local queuesurl = "http://api.bestfly.cn/";
	local md5uri = "task-queues";
	-- local sinakey = "5P826n55x3LkwK5k88S5b3XS4h30bTRg";
	print("--------------")
	print(queuesurl .. md5uri, mission);
	print("--------------")
	-- init response table
	local resp = {};
	-- local body, code, headers = http.request(baseurl .. md5uri)
	local body, code, headers, status = http.request {
	-- local ok, code, headers, status, body = http.request {
		-- url = "http://cloudavh.com/data-gw/index.php",
		url = queuesurl .. md5uri,
		-- proxy = exProxy,
		-- proxy = "http://10.123.74.137:808",
		-- proxy = "http://" .. tostring(arg[2]),
		timeout = 10000,
		method = "POST", -- POST or GET
		-- add post content-type and cookie
		headers = {
			["Host"] = "api.bestfly.cn",
			-- ["SOAPAction"] = "http://ctrip.com/Request",
			["Cache-Control"] = "no-cache",
			-- ["Auth-Timestamp"] = filet,
			-- ["Auth-Signature"] = md5.sumhexa(sinakey .. filet),
			-- ["Accept-Encoding"] = "gzip",
			-- ["Accept"] = "*/*",
			["Connection"] = "keep-alive",
			-- ["Content-Type"] = "text/xml; charset=utf-8",
			["Content-Length"] = string.len(mission)
		},
		-- body = formdata,
		-- source = ltn12.source.string(form_data);
		source = ltn12.source.string(mission),
		sink = ltn12.sink.table(resp)
	}
	if code == 200 then
		return code
	else
		return 400
	end
end
-- Main
local ad = "54807975-9730-4850-b6b4-862128352ab4"
local ak = "856474380e125a41" 
local xv = "20111128102912"
local GetProvinceList = "GetProvinceList"
local GetSceneryList = "GetSceneryList"
local GetCityList = "GetCityListByProvinceId"
local GetCountyList = "GetCountyListByCityId"
local GetSceneryDetail = "GetSceneryDetail"
local GetSceneryTrafficInfo = "GetSceneryTrafficInfo"
local GetNearbyScenery = "GetNearbyScenery"
local GetSceneryImageList = "GetSceneryImageList"
local sn = GetSceneryList
local ts = os.date("%Y-%m-%d %X", os.time()) .. ".000";
-- local ts = "2014-06-06 20:13:18.283"
-- LY.com
local baseurl = "http://tcopenapi.17usoft.com"
-- local scenuri = "/Handlers/General/AdministrativeDivisionsHandler.ashx"
local scenuri = "/handlers/scenery/queryhandler.ashx"
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
print(signmd5,signstr)
print("-----------------")
print(ts)
-- Get GetSceneryDetail
function GetScenery(sceneryId,ServiceName,cs)
	local ts = os.date("%Y-%m-%d %X", os.time()) .. ".000";
	local signtab = { "Version=" .. xv, "AccountID=" .. ad, "ServiceName=" .. ServiceName, "ReqTime=" .. ts }
	-- print(JSON.encode(signtab))
	local signstr = ""
	for k, v in pairsByKeys(signtab) do
		signstr = signstr .. k .. "&"
	end
	signstr = string.sub(signstr, 0, -2) .. ak
	-- print(signstr)
	local signmd5 = md5.sumhexa(signstr)
	local Scenerybody = ([=[<sceneryId>%s</sceneryId><cs>%s</cs>]=]):format(sceneryId,cs)
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
	</request>]=]):format(xv, ad, ServiceName, signmd5, ts, Scenerybody)
	-- print(reqxml)
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
			-- ["Accept-Encoding"] = "gzip",
			["Accept"] = "*/*",
			["Connection"] = "keep-alive",
			-- ["Content-Type"] = "text/xml; charset=utf-8",
			["Content-Type"] = "application/xml; charset=utf-8",
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
		--[[
		local output = {}
		deflate.gunzip {
		  input = resxml,
		  output = function(byte) output[#output+1] = string.char(byte) end
		}
		resxml = table.concat(output)
		--]]
		return resxml,0
	else
		return JSON.null,1
	end
end
-- init basedata of localcity.
local luasql = require "luasql.mysql"
local env = assert(luasql.mysql())
-- base_flights_city
local con = assert (env:connect("ticketbase", "rhomobi_dev", "b6x7p6b6x7p6", "localhost", 3306))
-- local con = assert (env:connect("biyifei_base", "rhomobi_dev", "b6x7p6b6x7p6", "localhost", 3306))
con:execute("SET NAMES utf8")
local sqlcmd = "SELECT `cLyId`, `id` FROM `city`";
local cur = assert (con:execute(sqlcmd))
local row = cur:fetch ({}, "a")
local citycn = {};
while row do
	citycn[row.id] = row.cLyId
	row = cur:fetch (row, "a")
end
cur:close()
-- print basedata
-- print(table.getn(citycn))
local i = 0
for keyid,vcLyId in pairs(citycn) do
	ts = os.date("%Y-%m-%d %X", os.time()) .. ".000";
	local signtab = { "Version=" .. xv, "AccountID=" .. ad, "ServiceName=" .. sn, "ReqTime=" .. ts }
	-- print(JSON.encode(signtab))
	local signstr = ""
	for k, v in pairsByKeys(signtab) do
		signstr = signstr .. k .. "&"
	end
	signstr = string.sub(signstr, 0, -2) .. ak
	local signmd5 = md5.sumhexa(signstr)
	-- print(kid,vcLy)
	local resly = {};
	--[[
	resly["CityId"]
	resly["DivisionId"]
	resly["sLyId"]
	#resly["grade"]
	resly["commentCount"]
	resly["questionCount"]
	resly["viewCount"]
	resly["blogCount"]
	#resly["glon"]
	#resly["glat"]
	resly["blon"]
	resly["blat"]
	resly["name"]
	#resly["aliasName"]
	resly["address"]
	#resly["traffic"]
	resly["summary"]
	resly["SceneryDetail"]
	resly["imgPath"]
	resly["bookFlag"]	tinyint(4) NULL	-1：暂时下线, 0：不可预订, 1：可预订
	resly["ifUseCard"]	tinyint(1) NULL	是否需要证件, 0：不需要, 1：需要
	resly["LowestPrice"]	decimal(10,2) NULL	该景点的最低价格，可能是儿童价
	resly["payMode"]	tinyint(1) NULL	1 面付, 2 在线付, 3456789预留
	resly["buyNotie"]	varchar(320) NULL	 
	#resly["remark"]
	--]]
	-- Get Scenerylist
	local Scenerylist = ([=[<clientIp>127.0.0.1</clientIp>
			<cityId>%s</cityId>
			<pageSize>100</pageSize>
			<cs>2</cs>]=]):format(vcLyId)
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
	</request>]=]):format(xv, ad, sn, signmd5, ts, Scenerylist)
	print(reqxml)
	print("-----------------")
	-- init response table
	local respbody = {};
	-- local hc = http:new()
	local body, code, headers, status = http.request {
	-- local ok, code, headers, status, body = http.request {
		-- url = "http://cloudavh.com/data-gw/index.php",
		url = baseurl .. scenuri,
		-- url = "http://localhost:3000/citycns",
		-- proxy = "http://10.123.74.137:808",
		-- proxy = "http://" .. tostring(arg[2]),
		timeout = 3000,
		method = "POST", -- POST or GET
		-- add post content-type and cookie
		-- headers = { ["Content-Type"] = "application/x-www-form-urlencoded", ["Content-Length"] = string.len(form_data) },
		-- headers = { ["Host"] = "flight.itour.cn", ["X-AjaxPro-Method"] = "GetFlight", ["Cache-Control"] = "no-cache", ["Accept-Encoding"] = "gzip,deflate,sdch", ["Accept"] = "*/*", ["Origin"] = "chrome-extension://fdmmgilgnpjigdojojpjoooidkmcomcm", ["Connection"] = "keep-alive", ["Content-Type"] = "application/json", ["Content-Length"] = string.len(JSON.encode(request)), ["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.65 Safari/537.36" },
		headers = {
			-- ["Host"] = "tcopenapi.17usoft.com",
			-- ["SOAPAction"] = "http://ctrip.com/Request",
			["Cache-Control"] = "no-cache",
			-- ["Accept-Encoding"] = "gzip",
			["Accept"] = "*/*",
			["Connection"] = "keep-alive",
			-- ["Content-Type"] = "text/xml; charset=utf-8",
			["Content-Type"] = "application/xml; charset=utf-8",
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
		-- print(resxml)
		--[[
		local output = {}
		deflate.gunzip {
		  input = resxml,
		  output = function(byte) output[#output+1] = string.char(byte) end
		}
		resxml = table.concat(output)
		--]]
		-- resxml = zlib.decompress(resxml)
		-- resxml = string.gsub(resxml, "&lt;", "<")
		-- resxml = string.gsub(resxml, "&gt;", ">")
		-- local pr_xml = xml.eval(resxml);
		-- local xscene = pr_xml:find("response");
		local idx1 = string.find(resxml, "<response>");
		local idx2 = string.find(resxml, "</response>");
		if idx1 ~= nil and idx2 ~= nil then
			local prdata = string.sub(resxml, idx1, idx2+11);
			-- print(prdata)
			-- print("-----------------")
			local pr_xml = collect(prdata);
			local rspCode = "";
			for i = 1, table.getn(pr_xml[1][1]) do
				if pr_xml[1][1][i]["label"] == "rspCode" then
					rspCode = pr_xml[1][1][i][1]
				end
			end
			if rspCode == "0000" then
				local sl = {};
				local imgbaseURL = "";
				for i = 1, table.getn(pr_xml[1][2]) do
					imgbaseURL = pr_xml[1][2][i]["xarg"]["imgbaseURL"]
					if pr_xml[1][2][i]["label"] == "sceneryList" then
						-- print(table.getn(pr_xml[1][2][i]))
						for j = 1, table.getn(pr_xml[1][2][i]) do
							if pr_xml[1][2][i][j]["label"] == "scenery" then
								local sd = {};
								for k = 1, table.getn(pr_xml[1][2][i][j]) do
									sd[pr_xml[1][2][i][j][k]["label"]] = pr_xml[1][2][i][j][k][1]
								end
								table.insert(sl, sd);
							end
						end
					end
				end
				-- print(imgbaseURL)
				-- print("+++++++++++++++++")
				-- print(JSON.encode(sl))
				-- print("+++++++++++++++++")
				-- resly = {};
				print("+++ { " .. table.getn(sl) .. " } GetSceneryList 总量+++");
				for i = 1, table.getn(sl) do
					print("-- begin to do the {" .. i .. "} SceneryDetails...")
					local resly = {};
					resly["CityId"] = keyid;
					resly["DivisionId"] = sl[i]["countyId"];
					resly["sLyId"] = sl[i]["sceneryId"];
					if sl[i]["gradeId"] ~= nil then
						resly["grade"] = string.len(sl[i]["gradeId"])
					end
					resly["commentCount"] = tonumber(sl[i]["commentCount"]);
					resly["questionCount"] = tonumber(sl[i]["questionCount"]);
					resly["viewCount"] = tonumber(sl[i]["viewCount"]);
					resly["blogCount"] = tonumber(sl[i]["blogCount"]);
					resly["name"] = string.sub(sl[i]["sceneryName"], 10, -4)
					-- resly["aliasName"]
					if sl[i]["sceneryAddress"] ~= nil then
						resly["address"] = string.sub(sl[i]["sceneryAddress"], 10, -4)
					end
					-- resly["traffic"]
					if sl[i]["scenerySummary"] ~= nil then
						resly["summary"] = string.sub(sl[i]["scenerySummary"], 10, -4)
					end
					-- resly["SceneryDetail"]
					if sl[i]["imgPath"] ~= nil and sl[i]["imgPath"] ~= "" then
						resly["imgPath"] = imgbaseURL .. string.sub(sl[i]["imgPath"], 10, -4)
					end
					resly["bookFlag"] = tonumber(sl[i]["bookFlag"]);
					local res, err = client:hset('sce:lycom:city:' .. keyid, sl[i]["sceneryId"], 1)
					if not res then
						print("-------Failed to hset " .. keyid .. ":" .. sl[i]["sceneryId"] .. "--------")
					else
						print("-------well done " .. keyid .. ":" .. sl[i]["sceneryId"] .. "--------")
					end
				end
			else
				print(error003(resxml))
			end
		end
	else
		-- debug
		print(code,status)
	end
	sleep(1)
	i = i + 1
end