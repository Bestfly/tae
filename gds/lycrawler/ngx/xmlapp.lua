-- Jijilu <jijilu.huang@mangocity.com> 20140615 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://jijilu.com/
-- http://lua-users.org/wiki/
-- load library
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
local error003 = JSON.encode({ ["resultCode"] = 3, ["description"] = "error003#Please input the ServiceName or Request body"});
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
-- Main
local ad = "54807975-9730-4850-b6b4-862128352ab4"
local ak = "856474380e125a41" 
local xv = "20111128102912"
local GetSceneryList = "GetSceneryList"
local GetSceneryDetail = "GetSceneryDetail"
local GetSceneryTrafficInfo = "GetSceneryTrafficInfo"
local GetNearbyScenery = "GetNearbyScenery"
local GetSceneryImageList = "GetSceneryImageList"
local GetSceneryPrice = "GetSceneryPrice"
local GetPriceCalendar = "GetPriceCalendar"
-- api url
local baseurl = "http://tcopenapi.17usoft.com";
local scenuri = "/handlers/scenery/queryhandler.ashx";
local verifykey = "19958883-A3B8-4B67-93F3-F73F47B20340";
if ngx.var.request_method == "POST" then
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	local harg = ngx.req.get_headers();
	if harg["Auth-Timestamp"] ~= nil and harg["Auth-Signature"] ~= nil then
		if math.abs(harg["Auth-Timestamp"] - os.time()) >= 3600 then
			-- ngx.exit(ngx.HTTP_UNAUTHORIZED);
			ngx.exit(ngx.HTTP_GONE);
		else
			if ngx.md5(harg["Auth-Timestamp"] .. harg["uid"] .. ngx.md5(pcontent .. verifykey) .. harg["sid"] .. harg["ServiceName"]) ~= harg["Auth-Signature"] then
				ngx.exit(ngx.HTTP_UNAUTHORIZED);
			else
				local srvname = harg["ServiceName"]
				if srvname ~= nil and srvname ~= "" and pcontent ~= nil and pcontent ~= "" then
					local ts = os.date("%Y-%m-%d %X", os.time()) .. ".000";
					local signtab = { "Version=" .. xv, "AccountID=" .. ad, "ServiceName=" .. srvname, "ReqTime=" .. ts };
					local signstr = "";
					for k, v in pairsByKeys(signtab) do
						signstr = signstr .. k .. "&"
					end
					signstr = string.sub(signstr, 0, -2) .. ak;
					local signmd5 = ngx.md5(signstr);
					local reqxml = ([=[<?xml version='1.0' encoding='utf-8'?>
					<request>
						<header>
							<version>%s</version>
							<accountID>%s</accountID>
							<serviceName>%s</serviceName>
							<digitalSign>%s</digitalSign>
							<reqTime>%s</reqTime>
						</header>
						%s
					</request>]=]):format(xv, ad, srvname, signmd5, ts, pcontent)
					local hc = http:new()
					local ok, code, headers, status, body = hc:request {
						url = baseurl .. scenuri,
						-- url = "http://localhost:4000/citycns",
						-- proxy = "http://10.123.74.137:808",
						timeout = 4000,
						method = "POST", -- POST or GET
						headers = {
							["Host"] = "tcopenapi.17usoft.com",
							-- ["SOAPAction"] = "http://ctrip.com/Request",
							["Cache-Control"] = "no-cache",
							-- ["Accept-Encoding"] = "gzip",
							["Accept"] = "*/*",
							["Connection"] = "keep-alive",
							["Content-Type"] = "text/xml; charset=utf-8",
							["Content-Length"] = string.len(reqxml),
							["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.65 Safari/537.36"
						},
						body = reqxml,
					}
					if code == 200 then
						ngx.print(body);
					else
						ngx.print(error009(code, body))
					end
				else
					ngx.print(error003)
				end
			end
		end
	else
		ngx.exit(ngx.HTTP_NOT_ALLOWED);
	end
else
	ngx.exit(ngx.HTTP_FORBIDDEN);
end