-- buyhome <huangqi@rhomobi.com> 20140517 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- kvdb service of rmsi for TAE service
-- load library
local JSON = require 'cjson'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
local redis = require "resty.redis"
local http = require "resty.http"
-- local memcached = require "resty.memcached"
-- local deflate = require "compress.deflatelua"
-- originality
function error000 (mes)
	local res = JSON.encode({ ["resultCode"] = 0, ["description"] = mes});
	return res
end
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "error001#tradeID not input"});
function error002 (tid)
	local res = JSON.encode({ ["resultCode"] = 2, ["description"] = "error002#The TradeID " .. tid .. " not found, please buy or contact seller"});
	return res
end
local error003 = JSON.encode({ ["resultCode"] = 3, ["description"] = "error003#Please input the limit between 0,1000"});
function error009 (mes)
	local res = JSON.encode({ ["resultCode"] = 9, ["description"] = mes});
	return res
end
-- ready to connect to master redis.
local red, err = redis:new()
if not red then
	ngx.say("failed to instantiate redis: ", err)
	return
end
-- nosql connect
local ok, err = red:connect("127.0.0.1", 6399)
if not ok then
	ngx.say("failed to connect redis: ", err)
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(1000) -- 1 sec
-- nosql connect
if ngx.var.request_method == "GET" then
	-- ngx.exit(ngx.HTTP_FORBIDDEN);
	-- local harg = ngx.req.get_headers();
	local parg = ngx.req.get_uri_args();
	local tmp = {};
	for key, val in pairs(parg) do
		tmp[string.lower(key)] = val
	end
	local tid = tmp["tradeid"]
	-- ngx.say(type(tid))
	if type(tid) ~= "boolean" and tid ~= nil and tid ~= "" and tid ~= JSON.null then
		local num, err = red:zscore("proxy:tid", tid)
		if not num then
			ngx.print(error009("error009#failed to find the number result of tradeID->>" .. tid))
			return
		else
			if num ~= nil and num ~= JSON.null then
				local limit = tonumber(tmp["limit"]);
				if limit ~= nil then
					if 0 < limit and limit <= 1000 then
						-- line & country & repeat
						
						ngx.say(limit)
					else
						ngx.print(error003)
					end
				else
					ngx.print(num);
				end
			else
				ngx.print(error002(tid));
			end
		end
	else
		ngx.print(error001);
	end
else
	ngx.exit(ngx.HTTP_FORBIDDEN);
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 100)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end