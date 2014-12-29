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
local redis = require "resty.redis"
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
local error007 = JSON.encode({ ["resultCode"] = 7, ["description"] = "error007#UID & SID#No prior registration channel customers"});
function error009 (code, mes)
	local res = JSON.encode({ ["resultCode"] = code, ["description"] = mes});
	return res
end

-- ready to connect to master redis.
local red, err = redis:new()
if not red then
        ngx.say("failed to instantiate redis: ", err)
        return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(3000) -- 3 sec
-- nosql connect
local ok, err = red:connect("10.10.130.94", 16391)
if not ok then
        ngx.print(error009("failed to connect redis: ", err))
        return
end
local r, e = red:auth("142ffb5bfa1-cn-jijilu-dg-a75")
if not r then
    ngx.print(error009("failed to authenticate: ", e))
    return
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
					local verifykey = sg:get(harg["uid"] .. harg["sid"]);
					if verifykey ~= nil then
						if ngx.md5(harg["Auth-Timestamp"] .. harg["uid"] .. ngx.md5(pcontent .. verifykey) .. harg["sid"] .. harg["ServiceName"]) ~= harg["Auth-Signature"] then
							ngx.exit(ngx.HTTP_UNAUTHORIZED);
						else
							-- Forward Controller
							local srvname = harg["ServiceName"];
							forwarduri = sg:get(srvname);
							if forwarduri ~= JSON.null and forwarduri ~= nil then
								local bollsrv = false
								if srvname == "hotel.list" then
									local pc = JSON.decode(pcontent)
									pr = pc.Request
									CheckInDate = string.gsub(pr.CheckInDate, "-", "")
									CheckOutDate = string.gsub(pr.CheckOutDate, "-", "")
									local tb, er = red:hget(pr.CityId .. ":" .. CheckInDate, CheckOutDate .. pr.PageIndex)
									if not tb or tb ~= nil then
										bollsrv = true
									end
								else
									bollsrv = true
								end
								if bollsrv ~= true then
									ngx.print("tb")
								else
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
						ngx.print(error007)
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
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 1000)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end
