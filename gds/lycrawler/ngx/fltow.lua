-- Jijilu <jijilu.huang@mangocity.com> 20140615 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://jijilu.com/
-- http://lua-users.org/wiki/
-- load library
local socket = require("socket")
local http = require("socket.http")
local ltn12 = require 'ltn12'
local JSON = require 'cjson'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
local deflate = require 'compress.deflatelua'
local http = require "resty.http"
-- originality
function error000 (mes)
	local res = JSON.encode({ ["resultCode"] = 0, ["description"] = mes});
	return res
end
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "error001#Service Name not input"});
function error002 (tid)
	local res = JSON.encode({ ["resultCode"] = 2, ["description"] = "error002#The TradeID " .. tid .. " not found, please buy or contact seller"});
	return res
end
local error003 = JSON.encode({ ["resultCode"] = 3, ["description"] = "error003#Please input the Scenery ID between 0,100000"});
local error004 = JSON.encode({ ["resultCode"] = 4, ["description"] = "error004#StartDate Not found in your headers"});
local error005 = JSON.encode({ ["resultCode"] = 5, ["description"] = "error005#Get IP from Queues is no result"});
local error006 = JSON.encode({ ["resultCode"] = 6, ["description"] = "error006#No IP left, Please buy more"});
function error009 (code, mes)
	local res = JSON.encode({ ["resultCode"] = code, ["description"] = mes});
	return res
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
-- caculate pcontent
function unescape (s)
	s = string.gsub(s, "+", " ")
	s = string.gsub(s, "%%(%x%x)", function (h)
    		return string.char(tonumber(h, 16))
		end)
	return s
end
function urlformdecode (s)
	local cgi = {};
	for name, value in string.gfind(s, "([^&=]+)=([^&=]+)") do
    	name = unescape(name)
    	value = unescape(value)
    	cgi[name] = value
  	end
	return cgi
end
-- base
local baseurl = "http://10.10.1.143";
-- main
if ngx.var.request_method == "GET" then
	ngx.say(ngx.var.srvname, ngx.var.sceneid)
	local puri = string.sub(ngx.var.URI, 4, -1);
	local args = ngx.req.get_headers();
	local parg = ngx.req.get_uri_args();
	
	local formdata = {};
	for k, v in pairs(parg) do
		-- wfile:write(k .. ":" .. v .. "\n");
		table.insert(formdata, k .. "=" .. v);
	end
	
	local hd = {};
	for k, v in pairs(args) do
		-- wfile:write(k .. ":" .. v .. "\n");
		table.insert(hd, k .. "=" .. v);
	end

	local form_data = table.concat(formdata, "&");
	
	-- ngx.say(baseurl .. "/flights" .. puri .. "?" .. form_data)
	
	local hc = http:new()
	local ok, code, headers, status, body = hc:request {
		url = baseurl .. "/flights" .. puri .. "?" .. form_data,
		-- url = "http://localhost:4000/citycns",
		-- proxy = "http://10.123.74.137:808",
		timeout = 10000,
		method = "GET", -- POST or GET
		headers = hd,
		-- body = reqxml,
	}
	if code == 200 then
		ngx.print(body);
	else
		ngx.print(error009(code, body));
	end
else
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	local puri = string.sub(ngx.var.URI, 4, -1);
	local args = ngx.req.get_headers();
	local hd = {};
	for k, v in pairs(args) do
		-- wfile:write(k .. ":" .. v .. "\n");
		table.insert(hd, k .. "=" .. v);
	end
	if pcontent then
		local geturlpara = {}
		local t = urlformdecode(pcontent)
		for k, v in pairs(t) do
			if k ~= "queryParamVO.position" and k ~= "queryParamVO.positionRet" and k ~= "suppliers" then
				table.insert(geturlpara, k .. "=" .. v)
			end
		end
		local form_data = table.concat(geturlpara, "&");
		
		-- http://10.10.1.143/flights/ow/oneway-Cheapest.shtml 
		-- ngx.say(baseurl .. "/flights" .. puri)
		local hc = http:new()
		local ok, code, headers, status, body = hc:request {
			url = baseurl .. "/flights" .. puri .. "?" .. form_data,
			-- url = "http://localhost:4000/citycns",
			-- proxy = "http://10.123.74.137:808",
			timeout = 10000,
			method = "GET", -- POST or GET
			headers = hd,
			-- body = reqxml,
		}
		if code == 200 then
			ngx.print(body);
		else
			ngx.print(error009(code, body));
		end
		--]]
	end
end
--[[

POST trans to GET

queryParamVO.depDate2014-07-03
--------------
queryParamVO.tripTypeow
--------------
queryParamVO.arrCityCn上海浦东
--------------
queryParamVO.position4
--------------
queryParamVO.positionRet4
--------------
queryParamVO.arrCityPVG
--------------
suppliersCZS/HUS
--------------
queryParamVO.depCityCn深圳
--------------
queryParamVO.arrAirportPVG
--------------
queryParamVO.depCitySZX


-- GET
[root@jijilu-test ngx]# cat /data/logs/rholog.txt 
10.10.224.28
---------------------
/ow/oneway-Cheapest.shtml
---------------------
host:flight.mangocity.com
accept-language:en-US,en;q=0.5
connection:keep-alive
accept:text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
cookie:__ozlvd=1403764709; Hm_lvt_0b2665fd0279a4d150b6ccadb25603e8=1403750173,1403753004,1403753136,1403761562; __utma=29435872.1093196468.1399293978.1403750172.1403761561.6; __utmz=29435872.1403761561.6.2.utmcsr=10.10.1.143|utmccn=(referral)|utmcmd=referral|utmcct=/flights/; _ltype=ow; _scity=%u6DF1%u5733; _ecity=%u5357%u5B81; _sdate=2014-07-15%20%u661F%u671F%u4E8C; _edate=2014-08-22%20%u661F%u671F%u4E94; _scityh=SZX; _ecityh=NNG; SessionID=10.10.7.103.1403752945843957; JSESSIONID_uat04s13=0000qfyuSJgm99kLMZ93t5NM_5T:15qck1e9g; Hm_lpvt_0b2665fd0279a4d150b6ccadb25603e8=1403764710; __utmc=29435872; JSESSIONID_uat03s13=00000LGYYhhS4m32vgeD89HYj2D:15qck0pi8; paraStat=; JESSION_TWEB3=0053R6MQM_OU8vzfkV5-9rOt-lQ:-K8HF5F:-1008R:30FBQNND99:I12FTT7UU:3DDDVMUEJ7:-1404QKR:1RK9VUEJ37:-14EI:-1B5OLRV:-DH87OL; __utmb=29435872.28.10.1403761561
accept-encoding:gzip, deflate
user-agent:Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:29.0) Gecko/20100101 Firefox/29.0

---------------------
queryParamVO.depDate:2014-07-15
queryParamVO.tripType:ow
queryParamVO.arrCityCn:南宁
queryParamVO.arrCity:NNG
queryParamVO.depAirport:
queryParamVO.depCity:SZX
queryParamVO.depCityCn:深圳
queryParamVO.arrAirport:
queryParamVO.tripSegment:

---------------------

-- POST

10.10.224.28
---------------------
/ow/oneway-Cheapest.shtml
---------------------
accept-language:en-US,en;q=0.5
content-type:application/x-www-form-urlencoded
connection:keep-alive
accept:text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
referer:http://flight.mangocity.com/ow/oneway-Cheapest.shtml?queryParamVO.tripSegment=&queryParamVO.tripType=ow&queryParamVO.depAirport=&queryParamVO.arrAirport=&queryParamVO.depCityCn=%E6%B7%B1%E5%9C%B3&queryParamVO.depCity=SZX&queryParamVO.arrCityCn=%E5%8D%97%E5%AE%81&queryParamVO.arrCity=NNG&queryParamVO.depDate=2014-07-15
host:flight.mangocity.com
content-length:388
cookie:__ozlvd=1403767429; Hm_lvt_0b2665fd0279a4d150b6ccadb25603e8=1403750173,1403753004,1403753136,1403761562; __utma=29435872.1093196468.1399293978.1403750172.1403761561.6; __utmz=29435872.1403761561.6.2.utmcsr=10.10.1.143|utmccn=(referral)|utmcmd=referral|utmcct=/flights/; _ltype=ow; _scity=%u6DF1%u5733; _ecity=%u5357%u5B81; _sdate=2014-07-15%20%u661F%u671F%u4E8C; _edate=2014-08-22%20%u661F%u671F%u4E94; _scityh=SZX; _ecityh=NNG; SessionID=10.10.7.103.1403752945843957; JSESSIONID_uat04s13=0000qfyuSJgm99kLMZ93t5NM_5T:15qck1e9g; Hm_lpvt_0b2665fd0279a4d150b6ccadb25603e8=1403767430; __utmc=29435872; JSESSIONID_uat03s13=00000LGYYhhS4m32vgeD89HYj2D:15qck0pi8; paraStat=; JESSION_TWEB3=0054R6MQM_OU8vzfkV5-9rOt-lQ:-K8HF5F:-1008R:30FBQNND99:I12FTT7UU:3DDDVMUEJ7:-1404QKR:1RK9VUEJ37:-14EI:-1B5OLRV:-DH87OL; __utmb=29435872.35.10.1403761561
accept-encoding:gzip, deflate
user-agent:Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:29.0) Gecko/20100101 Firefox/29.0
---------------------
queryParamVO.cabinLevel=&queryParamVO.useAdvanced=&queryParamVO.position=4&queryParamVO.positionRet=4&queryParamVO.tripSegment=&queryParamVO.tripType=ow&queryParamVO.depAirport=&queryParamVO.arrAirport=&queryParamVO.depCityCn=%E6%B7%B1%E5%9C%B3&queryParamVO.depCity=SZX&queryParamVO.arrCityCn=%E4%B8%8A%E6%B5%B7&queryParamVO.arrCity=SHA&queryParamVO.depDate=2014-08-09&suppliers=CZS%2FHUS
--]]
-- put it into the connection pool of size 512,
-- with 0 idle timeout
--[[
local ok, err = red:set_keepalive(0, 512)
if not ok then
	ngx.say("failed to set keepalive main redis: ", err)
	return
end
--]]