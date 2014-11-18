-- Jijilu <huangqi@rhomobi.com> 20140925 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- Queues service of oRB for RankBus service
-- load library
local JSON = require 'cjson'
local base64 = require 'base64'
package.path = "/mnt/data/usgcore/ngx/lib/?.lua;";
local redis = require "resty.redis"
local http = require "resty.http"
local memcached = require "resty.memcached"
local deflate = require "compress.deflatelua"
-- originality
function error000 (mes)
	local res = JSON.encode({ ["resultCode"] = 0, ["description"] = mes});
	return res
end
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "error001#unKnow dt#Content"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "error002#Service unSupported now."});
local error004 = JSON.encode({ ["resultCode"] = 4, ["description"] = "Get task from Queues is no result"});
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
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
local ok, err = red:connect("10.171.99.210", 16390)
if not ok then
	ngx.print(error003("failed to connect redis: ", err))
	return
end
local r, e = red:auth("142ffb5bfa1-cn-jijilu-dg-a75")
if not r then
    ngx.print(error003("failed to authenticate: ", e))
    return
end
local memc, err = memcached:new()
if not memc then
    ngx.say("failed to instantiate memc: ", err)
    return
end
memc:set_timeout(3000) -- 3 sec
local ok, err = memc:connect("10.171.99.210", 11978)
if not ok then
    ngx.print(error003("failed to connect: ", err))
    return
end
-- end of nosql init.
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
				if tonumber(ngx.var.num) ~= 0 then
					for n = 1, ngx.var.num do
						local res, err = red:lpop(ngx.var.que .. ":list")
						if type(res) ~= "string" then
							task[n] = JSON.null
							break;
						else
							-- local tkey = res[2];
							local tkey = res;
							res, err = memc:get(tkey)
							if not res then
								ngx.print(error003("failed to get originality data from kvdb: ", tkey, err))
								return
							else
								if string.find(res, "[0,1]/el%a%a%a/") ~= nil then
									task[n] = res
								else
									task[n] = JSON.null
									-- ngx.say("Bad data got from kvdb: ", tkey, err)
									-- return
								end
								check = true;
								resnum = resnum + 1;
								-- Cancel delete the vd data for webservice developing via redis indexsystem
								--[[
								res, err = memc:delete(tkey)
								if not res then
									ngx.print(error003("failed to delete originality data of dip: ", tkey, err))
									return
								end
								--]]
							end
						end
					end
					if check == true then
						local result = {};
						result["resultCode"] = 0;
						result["tasknumber"] = resnum;
						result["taskQueues"] = task;
						ngx.print(JSON.encode(result))
					else
						ngx.print(error004)
					end
				else
					local r, e = red:zrange("elg:vals:" .. ngx.var.que, 0, -1)
					if not r then
						ngx.print(error003("failed to get kvid from Redis: ", e))
						return
					else
						if type(r) == "table" then
							for n = 1, table.getn(r) do
								task[n] = memc:get(ngx.var.que .. r[n])
								if task[n] ~= nil then
									check = true;
									resnum = resnum + 1;
								end
							end
						end
					end
					if check == true then
						local result = {};
						result["resultCode"] = 0;
						result["tasknumber"] = resnum;
						result["taskQueues"] = task;
						ngx.print(JSON.encode(result))
					else
						ngx.print(error001)
					end
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
-- with 10 seconds max idle timeout
local ok, err = memc:set_keepalive(10000, 1000)
if not ok then
    ngx.say("cannot set keepalive: ", err)
    return
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 1000)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end
