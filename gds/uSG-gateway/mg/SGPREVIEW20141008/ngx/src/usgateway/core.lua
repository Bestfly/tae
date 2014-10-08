-- Jijilu <jijilu.huang@mangocity.com> 20140730 (v0.5.7)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://jijilu.com/
-- http://lua-users.org/wiki/
-- load library
local JSON = require 'cjson'
package.path = "/data/sgcore/ngx/lib/?.lua;";
local deflate = require 'compress.deflatelua'
local http = require "resty.http"
-- originality
function error000 (mes)
	local res = JSON.encode({ ["resultCode"] = 0, ["description"] = mes});
	return res
end
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "error001#Service Name or UID & SID not input"});
function error002 (tid)
	local res = JSON.encode({ ["resultCode"] = 2, ["description"] = "error002#The TradeID " .. tid .. " not found, please buy or contact seller"});
	return res
end
local error003 = JSON.encode({ ["resultCode"] = 3, ["description"] = "error003#Please input the ServiceName or Request body"});
local error004 = JSON.encode({ ["resultCode"] = 4, ["description"] = "error004#StartDate Not found in your headers"});
local error005 = JSON.encode({ ["resultCode"] = 5, ["description"] = "error005#Get IP from Queues is no result"});
local error006 = JSON.encode({ ["resultCode"] = 6, ["description"] = "error006#NGX DICT ERROR"});
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
-- init the DICT.
local sg = ngx.shared.sgcore;
-- Main
-- api url
local forwarduri = ""
local verifykey = "19958883-A3B8-4B67-93F3-F73F47B20340";
local verifykey1 = "19888395-A3B8-4B67-93F3-B20340F73F47";
if ngx.var.request_method == "POST" then
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	local harg = ngx.req.get_headers();
	if not pcontent then
		ngx.print(error003)
	else
		if harg["Auth-Timestamp"] ~= nil and harg["Auth-Signature"] ~= nil then
			if math.abs(harg["Auth-Timestamp"] - os.time()) >= 3600 then
				-- ngx.exit(ngx.HTTP_UNAUTHORIZED);
				ngx.exit(ngx.HTTP_GONE);
			else
				if harg["ServiceName"] ~= nil and harg["uid"] ~= nil and harg["sid"] ~= nil then
					if ngx.md5(harg["Auth-Timestamp"] .. harg["uid"] .. ngx.md5(pcontent .. verifykey) .. harg["sid"] .. harg["ServiceName"]) ~= harg["Auth-Signature"] and ngx.md5(harg["Auth-Timestamp"] .. harg["uid"] .. ngx.md5(pcontent .. verifykey1) .. harg["sid"] .. harg["ServiceName"]) ~= harg["Auth-Signature"] then
						ngx.exit(ngx.HTTP_UNAUTHORIZED);
					else
						-- Forward Controller
						local srvname = harg["ServiceName"];
						forwarduri = sg:get(srvname);
						if forwarduri ~= JSON.null and forwarduri ~= nil then
						-- if baseurl ~= JSON.null and scenuri ~= JSON.null then
							local hc = http:new()
							local ok, code, headers, status, body = hc:request {
								url = forwarduri,
								-- url = "http://localhost:4000/citycns",
								-- proxy = "http://10.123.74.137:808",
								timeout = 30000,
								method = "POST", -- POST or GET
								headers = {
									-- ["Host"] = "tcopenapi.17usoft.com",
									-- ["SOAPAction"] = "http://ctrip.com/Request",
									["uid"] = harg["uid"],
									["sid"] = harg["sid"],
									-- ["Data-Format"] = "json",
									["Data-Format"] = harg["data-format"],
									["Cache-Control"] = "no-cache",
									-- ["Accept-Encoding"] = "gzip",
									["Accept"] = "*/*",
									["Connection"] = "keep-alive",
									["Content-Type"] = "application/json; charset=utf-8",
									["Content-Length"] = string.len(pcontent),
									["User-Agent"] = "Rhongx by huangqi for uMsg-Gateway v0.5.7"
								},
								body = pcontent,
							}
							if code == 200 then
								ngx.print(body);
							else
								-- ngx.say("-------" .. code .. "+++++++++")
								-- if code == nil or code == JSON.null or code == "" then
								if tonumber(code) ~= nil then
									ngx.print(error009(code, body))
								else
									ngx.print(error000(code))
								end
							end
						else
							if forwarduri == "" then
								ngx.print(error006)
							else
								ngx.print(error003)
							end
						end
					end
				else
					ngx.print(error001)
				end
			end
		else
			ngx.exit(ngx.HTTP_NOT_ALLOWED);
		end
	end
else
	ngx.exit(ngx.HTTP_FORBIDDEN);
end
