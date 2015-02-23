-- buyhome <huangqi@rhomobi.com> 20131118 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- sinaapp test program of extension for bestfly service
local socket = require 'socket'
local http = require 'socket.http'
-- local JSON = require 'cjson'
local md5 = require 'md5'
-- local zlib = require 'zlib'
local base64 = require 'base64'
-- local crypto = require 'crypto'
-- local client = require 'soap.client'
if string.find(_VERSION, "5.2") then
	table.getn = function (t)
		if t.n then
            return t.n
        else
            local n = 0
            for i in pairs(t) do
                if type(i) == "number" then
                    n = math.max(n, i)
                end
            end
        return n
        end
    end
end
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
local baseurl = "http://api.cloudavh.com/";
-- local md5uri = "taei?intl/ctrip/20131130.20131230/bjslon";
-- &intl/ctrip/20141010.00000000/canlax&domc/ctrip/20141010.00000000/cansha&
-- local md5uri = "tae?domc/ctrip/20141010.00000000/canbjs&intl/ctrip/20141010.00000000/canlax&domc/ctrip/20141010.00000000/cansha&";
-- local md5uri = "tae"
local md5uri = "tae?rms:renwu"
local sinakey = "5P826n55x3LkwK5k88S5b3XS4h30bTRg";
local appid = "142ffb5bfa1-cn-jijilu-dg-c02";
local timestamp = os.time() + 1200;
print(timestamp);
print(md5.sumhexa(sinakey .. timestamp))
-- print(urlencode(baseurl .. md5uri));
print("--------------")
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
	timeout = 1,
	method = "GET", -- POST or GET
	-- add post content-type and cookie
	-- headers = { ["Content-Type"] = "application/x-www-form-urlencoded", ["Content-Length"] = string.len(form_data) },
	-- headers = { ["Host"] = "flight.itour.cn", ["X-AjaxPro-Method"] = "GetFlight", ["Cache-Control"] = "no-cache", ["Accept-Encoding"] = "gzip,deflate,sdch", ["Accept"] = "*/*", ["Origin"] = "chrome-extension://fdmmgilgnpjigdojojpjoooidkmcomcm", ["Connection"] = "keep-alive", ["Content-Type"] = "application/json", ["Content-Length"] = string.len(JSON.encode(request)), ["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.65 Safari/537.36" },
	headers = {
		-- ["Host"] = "yougola.sinaapp.com",
		-- ["SOAPAction"] = "http://ctrip.com/Request",
		["Cache-Control"] = "no-cache",
		["Auth-Appid"] = appid,
		-- ["If-Match"] = 'sort',
		["If-Match"] = "[400,400]",
		["Sn"] = "rms:renwu",
		["Auth-Timestamp"] = timestamp,
		["Auth-Signature"] = md5.sumhexa(sinakey .. timestamp .. appid),
		-- ["Accept-Encoding"] = "gzip",
		-- ["Accept"] = "*/*",
		["Connection"] = "keep-alive",
		-- ["Content-Type"] = "text/xml; charset=utf-8",
		-- ["Content-Length"] = string.len(request)
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
local resjson = "";
local reslen = table.getn(respbody)
-- print(reslen)
for i = 1, reslen do
	-- print(respbody[i])
	resjson = resjson .. respbody[i]
end
print("--------------")
print(resjson)
print("--------------")
-- init response table
local respbody = {};
-- local request = md5.sumhexa(resjson) .. timestamp;
-- local request = '{"k":"domc/ctrip/20141010.20141011/canlax","v":"123456ww"}'
local request = ([=[{
    "vb": "AA1111114sIAAAAAAAAZ5iksQY7xGuMrcddntAkchVd4K0WO2iZeHpQ5KQMwCSF4q7fmYd8",
    "sn": "rms:renwu",
    "dt": %s,
    "uk": "domc/ctrip/20141010.00000000/sfohan",
	"sc": 400
}]=]):format(11)
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