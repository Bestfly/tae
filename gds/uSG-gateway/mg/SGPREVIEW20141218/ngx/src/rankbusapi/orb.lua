-- Jijilu <huangqi@rhomobi.com> 20141218 (v0.5.7)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- Queues service of oRB for RankBus service
-- load library
--[[
-- 0.5.5~ zset to hash
-- 0.5.6~ replace to set for NOT set missing
-- 0.5.7~ md5 precaculate
--]]
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
local error004 = JSON.encode({ ["resultCode"] = 4, ["description"] = "error004#Get task from Queues is no result"});
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end
local error005 = JSON.encode({ ["resultCode"] = 5, ["description"] = "[]"});
-- ready to connect to master redis.
local red, err = redis:new()
if not red then
	-- ngx.say("failed to instantiate redis: ", err)
	ngx.log(ngx.ERR, "failed to instantiate redis: ", err)
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(3000) -- 3 sec
-- nosql connect
local ok, err = red:connect("10.171.99.210", 61390)
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
    -- ngx.say("failed to instantiate memc: ", err)
	ngx.log(ngx.ERR, "failed to instantiate memc: ", err)
    return
end
memc:set_timeout(3000) -- 3 sec
local ok, err = memc:connect("127.0.0.1", 61978)
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
				if tonumber(ngx.var.num) ~= nil then
					for n = 1, ngx.var.num do
						local res, err = red:lpop(ngx.var.que .. ":list")
						if type(res) ~= "string" then
							task[n] = JSON.null
							break;
						else
							if not red:srem(ngx.var.que .. ":sets", res) then
								red:lpush(ngx.var.que .. ":list", res)
								ngx.log(ngx.ERR, error003("failed to srem data of sets index: ", res))
								ngx.print(error003("failed to srem data of sets index: ", res))
							else
								-- local tkey = res[2];
								local tkey = res;
								res, err = memc:get(tkey)
								if not res then
									ngx.log(ngx.ERR, error003("failed to get originality data from kvdb: ", tkey, err))
									ngx.print(error003("failed to get originality data from kvdb: ", tkey, err))
									return
								else
									if string.find(res, '[0,1]/%a%a%a%a%a/') ~= nil then
										task[n] = string.sub(res, 33, -1)
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
					local checknil = false;
					local respbody = {};
				    for key, val in pairs(parg) do
						if key ~= nil and string.len(key) ~= 0 then
							local res, err = memc:get(ngx.var.que .. ngx.var.num .. ngx.md5(key))
							if res ~= nil then
								-- task[n] = string.sub(res, 33, -1)
								task[key] = res;
								check = true;
								resnum = resnum + 1;
							end
							checknil = true;
						end
					end
					if checknil ~= false then
						if check == true then
							local result = {};
							result["resultCode"] = 0;
							result["tasknumber"] = resnum;
							result["taskQueues"] = task;
							ngx.print(JSON.encode(result))
							-- ngx.print(JSON.encode(respbody))
						else
							ngx.print(error005)
						end
					else
						-- 上面是根据指定的uk（支持批量）返回，下面是不指定uk情况下，穷举qn[1]:qn[2]的uk全面返回
						local r, e = red:hkeys(ngx.var.que .. ":vals:" .. ngx.var.num)
						if not r then
							ngx.print(error003("failed to get kvid from Redis: ", e))
							return
						else
							if type(r) == "table" then
								for n = 1, table.getn(r) do
									res, err = memc:get(ngx.var.que .. ngx.var.num .. r[n])
									if res ~= nil then
										-- task[n] = string.sub(res, 33, -1)
										task[n] = res;
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
							ngx.print(error005)
						end
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
    -- ngx.say("cannot set keepalive: ", err)
	ngx.log(ngx.ERR, "failed to set keepalive with kvdb: ", err)
    return
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 1000)
if not ok then
    -- ngx.say("failed to set keepalive: ", err)
	ngx.log(ngx.ERR, "failed to set keepalive with Redis: ", err)
    return
end