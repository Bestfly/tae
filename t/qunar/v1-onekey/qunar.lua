--[[
全量：http://api.mangocity.com/HotelInfoList/hotelService?cl=qunarnew&q=info
报价：http://api.mangocity.com/HOI/hotelService?cl=qunarnew&q=bd&hotelId=30228367&fromDate=2014-10-13&toDate=2014-10-14
试预定：http://api.mangocity.com/HOI/hotelService?cl=qunarnew&q=bd&hotelId=30228367&fromDate=2014-10-13&toDate=2014-10-14&roomId=1376815&usedFor=order
积积路  20:13:30
]]
-- Jijilu <jijilu.huang@mangocity.com> 20141011 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- sinaapp test program of extension for bestfly service
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
local deflate = require 'compress.deflatelua'
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
-- http://yougola.sinaapp.com/checker/?/intl/ctrip/20131201.20131231/shalon
-- http://yougola.sinaapp.com/checker/?intl/ctrip/20131130.20131230/bjslon
local sinaapp = false;
-- local baseurl = "http://yougola.sinaapp.com/";
-- local baseurl = "http://api.bestfly.cn:3000/";
-- local baseurl = "http://api.mangocity.com/HotelInfoList/hotelService?cl=qunarnew&q=info"
local baseurl = "http://api.mangocity.com/"
-- local baseurl = "http://rhomobi.com/topics/217"
-- local md5uri = "taei?intl/ctrip/20131130.20131230/bjslon";
-- &intl/ctrip/20141010.00000000/canlax&domc/ctrip/20141010.00000000/cansha&
-- local md5uri = "tae?domc/ctrip/20141010.00000000/canbjs&intl/ctrip/20141010.00000000/canlax&domc/ctrip/20141010.00000000/cansha&";
local md5uri = "HOI/hotelService?cl=qunarnew&q=bd&hotelId=30073268&fromDate=2014-12-15&toDate=2014-12-17"
-- local sinakey = "5P826n55x3LkwK5k88S5b3XS4h30bTRg";
-- local appid = "142ffb5bfa1-cn-jijilu-dg-c01";
-- local timestamp = os.time();
-- local timestamp = os.clock();
local t = socket.gettime()
print(os.date("%Y-%m-%d %X", os.time()));
-- print("Milliseconds: " .. socket.gettime()*1000)
-- print(md5.sumhexa(sinakey .. timestamp))
-- print(urlencode(baseurl .. md5uri));
print("--------------------------------")
-- print(md5.sumhexa("BJS0650/DXB1150-DXB1445/LON1825,LON1335/DXB0035-DXB0335/BJS1445"))
-- init response table
local respbody = {};
-- local body, code, headers = http.request(baseurl .. md5uri)
local body, code, headers, status = http.request {
-- local ok, code, headers, status, body = http.request {
	-- url = "http://cloudavh.com/data-gw/index.php",
	-- url = "http://yougola.sinaapp.com/tools/proxy2/?url=" .. urlencode(baseurl .. md5uri),
	url = baseurl .. md5uri,
	-- proxy = "http://112.124.211.29:18085",
	-- proxy = "http://" .. tostring(arg[2]),
	timeout = 2000,
	method = "GET", -- POST or GET
	-- add post content-type and cookie
	-- headers = { ["Content-Type"] = "application/x-www-form-urlencoded", ["Content-Length"] = string.len(form_data) },
	-- headers = { ["Host"] = "flight.itour.cn", ["X-AjaxPro-Method"] = "GetFlight", ["Cache-Control"] = "no-cache", ["Accept-Encoding"] = "gzip,deflate,sdch", ["Accept"] = "*/*", ["Origin"] = "chrome-extension://fdmmgilgnpjigdojojpjoooidkmcomcm", ["Connection"] = "keep-alive", ["Content-Type"] = "application/json", ["Content-Length"] = string.len(JSON.encode(request)), ["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.65 Safari/537.36" },
	headers = {
		["Cache-Control"] = "no-cache",
		["Accept-Encoding"] = "gzip",
		["Accept"] = "*/*",
		["Connection"] = "keep-alive",
		-- ["Content-Type"] = "text/xml; charset=utf-8",
		-- ["Content-Length"] = string.len(request),
		["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.65 Safari/537.36"
	},
	-- body = formdata,
	-- source = ltn12.source.string(form_data);
	-- source = ltn12.source.string(request),
	sink = ltn12.sink.table(respbody)
}
-- print(code, status, body)
--[[
for k, v in pairs(headers) do
	print(k, v)
end
print("--------------")
print(body)
print("--------------")
print(status)
print("--------------")
--]]
if code == 200 then
	local resjson = "";
	local reslen = table.getn(respbody)
	-- print(reslen)
	-- print("++++++")
	for i = 1, reslen do
		-- print(respbody[i])
		resjson = resjson .. respbody[i]
	end
	-- Change the time cacu after gunzip
	
	local output = {}
	deflate.gunzip {
	  input = resjson,
	  output = function(byte) output[#output+1] = string.char(byte) end
	}
	resjson = table.concat(output)
	
	-- Debug LOGs
	--[[
	local wname = "/data/logs/rholog.txt"
	local wfile = io.open(wname, "w+");
	wfile:write(os.date());
	wfile:write("\r\n---------------------\r\n");
	wfile:write(resjson);
	wfile:write("\r\n---------------------\r\n");
	io.close(wfile);
	--]]
	print(resjson)
	-- print("+++++----++++++")
	-- print(string.format("cl Elapsed time: %.5f", os.clock() - timestamp))
	-- print("--------------")
	print(code,string.format("ms elapsed time: %.3f", (socket.gettime() - t)*1000))
else
	print(code,string.format("ms elapsed time: %.3f", (socket.gettime() - t)*1000))
end
print("++++++++++++++++++++++++++++++++\n")
--[[
print("--------------")
-- init response table
local respbody = {};
-- local request = md5.sumhexa(resjson) .. timestamp;
-- local request = '{"k":"domc/ctrip/20141010.20141011/canlax","v":"123456ww"}'
local request = ([=[{
    "vb": "H4sIAAAAAAAAZ5iksQY7xGuMrcddntAkchVd4K0WO2iZeHpQ5KQMwCSF4q7fmYd8",
    "sn": "rms:renwu",
    "dt": %s,
    "uk": "domc/ctrip/20141010.00000000/canbjs"
}]=]):format(10)
print(request);
print("-------开始发送POST请求-------")
-- local body, code, headers = http.request(baseurl .. md5uri)
local body, code, headers, status = http.request {
-- local ok, code, headers, status, body = http.request {
	-- url = "http://cloudavh.com/data-gw/index.php",
	url = baseurl .. md5uri,
	-- proxy = "http://112.124.211.29:18085",
	-- proxy = "http://" .. tostring(arg[2]),
	timeout = 1,
	method = "POST", -- POST or GET
	-- add post content-type and cookie
	-- headers = { ["Content-Type"] = "application/x-www-form-urlencoded", ["Content-Length"] = string.len(form_data) },
	-- headers = { ["Host"] = "flight.itour.cn", ["X-AjaxPro-Method"] = "GetFlight", ["Cache-Control"] = "no-cache", ["Accept-Encoding"] = "gzip,deflate,sdch", ["Accept"] = "*/*", ["Origin"] = "chrome-extension://fdmmgilgnpjigdojojpjoooidkmcomcm", ["Connection"] = "keep-alive", ["Content-Type"] = "application/json", ["Content-Length"] = string.len(JSON.encode(request)), ["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.65 Safari/537.36" },
	headers = {
		-- ["Host"] = "yougola.sinaapp.com",
		-- ["SOAPAction"] = "http://ctrip.com/Request",
		["Cache-Control"] = "no-cache",
		["Auth-Appid"] = appid,
		["Auth-Timestamp"] = timestamp,
		["Auth-Signature"] = md5.sumhexa(sinakey .. timestamp .. appid),
		-- ["Accept-Encoding"] = "gzip",
		-- ["Accept"] = "*/*",
		["Connection"] = "keep-alive",
		-- ["Content-Type"] = "text/xml; charset=utf-8",
		["Content-Length"] = string.len(request)
	},
	-- body = formdata,
	-- source = ltn12.source.string(form_data);
	source = ltn12.source.string(request),
	sink = ltn12.sink.table(respbody)
}
print(code, status, body)
print("--------------")
print(body)
print("--------------")
print(status)
print("--------------")
local resjson = "";
local reslen = table.getn(respbody)
print(reslen)
for i = 1, reslen do
	-- print(respbody[i])
	resjson = resjson .. respbody[i]
end
print(resjson)
--]]