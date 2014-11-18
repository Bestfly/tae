-- Jijilu <huangqi@rhomobi.com> 20141020 (v0.5.2)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- Queues service of RankBus for TAE service
-- load library
local JSON = require("cjson");
local redis = require "resty.redis"
local http = require "resty.http"
-- originality
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "No response because you has inputted error"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "Get task from Queues is no result"});
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end
-- ready to connect to master redis.
local red, err = redis:new()
if not red then
	ngx.log(ngx.ERR, error003("failed to instantiate redis: ", err))
	-- ngx.say("failed to instantiate redis: ", err)
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(3000) -- 3 sec
-- nosql connect
local ok, err = red:connect("10.171.99.210", 16390)
if not ok then
	ngx.log(ngx.ERR, error003("failed to connect redis: ", err))
	-- ngx.print(error003("failed to connect redis: ", err))
	return
end
local r, e = red:auth("142ffb5bfa1-cn-jijilu-dg-a75")
if not r then
    ngx.print(error003("failed to authenticate: ", e))
    return
end
-- end of nosql init.
-- init the DICT.
-- local byfs = ngx.shared.biyifei;
local verifykey = "5P826n55x3LkwK5k88S5b3XS4h30bTRb";
if ngx.var.request_method == "GET" then
	local harg = ngx.req.get_headers();
	local parg = ngx.req.get_uri_args();
	if harg["Auth-Timestamp"] ~= nil and harg["Auth-Signature"] ~= nil then
		if math.abs(harg["Auth-Timestamp"] - os.time()) >= 3600 then
			-- ngx.exit(ngx.HTTP_UNAUTHORIZED);
			ngx.exit(ngx.HTTP_GONE);
		else
			if ngx.md5(verifykey .. harg["Auth-Timestamp"]) ~= harg["Auth-Signature"] then
				ngx.exit(ngx.HTTP_UNAUTHORIZED);
			else
				local task = {};
				local check = false;
				local resnum = 0;
				for n = 1, ngx.var.num do
					local res, err = red:lpop("que:" .. ngx.var.que)
					if type(res) ~= "string" then
						task[n] = JSON.null
						break;
					else
						task[n] = res
						check = true;
						resnum = resnum + 1;
						-- red:set_keepalive(10000, 500)
					end
					--[[
					-- Do NOT support set_keepalive
					local res, err = red:blpop("que:" .. ngx.var.que, 0)
					if res then
						task[n] = res[2]
						check = true;
						resnum = resnum + 1;
					else
						task[n] = JSON.null
						break;
					end
					--]]
				end
				if check == true then
					local result = {};
					result["resultCode"] = 0;
					result["tasknumber"] = resnum;
					result["taskQueues"] = task;
					ngx.print(JSON.encode(result))
				else
					ngx.print(error002)
				end
			end
		end
	else
		ngx.exit(ngx.HTTP_NOT_ALLOWED);
	end
else
	ngx.exit(ngx.HTTP_FORBIDDEN);
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 500)
if not ok then
	ngx.log(ngx.ERR, "cannot set Redis keepalive: ", err)
    return
end