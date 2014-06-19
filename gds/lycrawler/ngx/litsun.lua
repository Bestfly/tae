-- Jijilu <jijilu.huang@mangocity.com> 20131118 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://jijilu.com/topics/
-- little sun corp interface test program of extension for bestfly service
local socket = require 'socket'
local http = require 'socket.http'
-- local JSON = require 'cjson'
local md5 = require 'md5'
-- local zlib = require 'zlib'
local base64 = require 'base64'
-- local crypto = require 'crypto'
-- local client = require 'soap.client'
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

local baseurl = "http://www.skyecho.com";
local md5uri = "/cgishell/module/xml/air_other.pl?";

local Corp_ID = "MANGGO";
local md5key = "D%d3L8#F";
-- local args = ("Air_date=2014.06.30&Airline=CZ&Arrive=CSX&Corp_ID=%s&Depart=CAN&Type=FDBLKD"):format(Corp_ID)
local args = ("Air_date=2014.06.30&Airline=CZ&Corp_ID=%s&Trip=SZXSHA&Type=FDBLKD"):format(Corp_ID)
local sign = string.upper(md5.sumhexa(args))
args = args .. "&Sign=" .. sign
print("--------------")
local respbody = {};
-- local body, code, headers = http.request(baseurl .. md5uri)
local body, code, headers, status = http.request {
-- local ok, code, headers, status, body = http.request {
	-- url = "http://cloudavh.com/data-gw/index.php",
	-- url = "http://yougola.sinaapp.com/tools/proxy2/?url=" .. urlencode(baseurl .. md5uri),
	url = baseurl .. md5uri .. args,
	-- proxy = "http://112.124.211.29:18085",
	-- proxy = "http://" .. tostring(arg[2]),
	timeout = 10000,
	method = "GET", -- POST or GET
	-- add post content-type and cookie
	-- headers = { ["Content-Type"] = "application/x-www-form-urlencoded", ["Content-Length"] = string.len(form_data) },
	-- headers = { ["Host"] = "flight.itour.cn", ["X-AjaxPro-Method"] = "GetFlight", ["Cache-Control"] = "no-cache", ["Accept-Encoding"] = "gzip,deflate,sdch", ["Accept"] = "*/*", ["Origin"] = "chrome-extension://fdmmgilgnpjigdojojpjoooidkmcomcm", ["Connection"] = "keep-alive", ["Content-Type"] = "application/json", ["Content-Length"] = string.len(JSON.encode(request)), ["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.65 Safari/537.36" },
	headers = {
		-- ["Host"] = "yougola.sinaapp.com",
		-- ["SOAPAction"] = "http://ctrip.com/Request",
		["Cache-Control"] = "no-cache",
		-- ["Auth-Timestamp"] = timestamp,
		-- ["Auth-Signature"] = md5.sumhexa(sinakey .. timestamp),
		-- ["Accept-Encoding"] = "gzip",
		-- ["Accept"] = "*/*",
		["Connection"] = "keep-alive",
		["Content-Type"] = "text/xml; charset=GB2312",
		-- ["Content-Length"] = string.len(request)
	},
	-- body = formdata,
	-- source = ltn12.source.string(form_data);
	-- source = ltn12.source.string(request),
	sink = ltn12.sink.table(respbody)
}
print(code, status, body)
for k, v in pairs(headers) do
	print(k, v)
end
local resjson = "";
local reslen = table.getn(respbody)
print(reslen)
for i = 1, reslen do
	-- print(respbody[i])
	resjson = resjson .. respbody[i]
end
print(resjson)
