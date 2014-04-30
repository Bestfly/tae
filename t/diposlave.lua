-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- load library
local JSON = require 'cjson'
local base64 = require 'base64'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
local redis = require "resty.redis"
local http = require "resty.http"
local memcached = require "resty.memcached"
local deflate = require "compress.deflatelua"
local memc, err = memcached:new()
if not memc then
    ngx.say("failed to instantiate memc: ", err)
    return
end
memc:set_timeout(1000) -- 1 sec
local ok, err = memc:connect("127.0.0.1", 1978)
if not ok then
    ngx.say("failed to connect: ", err)
    return
end
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
	ngx.say("failed to instantiate redis: ", err)
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(1000) -- 1 sec
-- nosql connect
local ok, err = red:connect("10.123.96.148", 6399)
if not ok then
	ngx.say("failed to connect redis: ", err)
	return
end
local r, e = red:auth("142ffb5bfa1-cn-jijilu-dg-a02")
if not r then
    ngx.say("failed to authenticate: ", e)
    return
end
-- end of nosql init.
if ngx.var.request_method == "GET" then
	local task = {};
	local check = false;
	local resnum = 0;
	for n = 1, ngx.var.num do
		local res, err = red:lpop("dip:list")
		if type(res) ~= "string" then
			task[n] = JSON.null
			break;
		else
			-- local tkey = res[2];
			local tkey = res;
			res, err = memc:get(tkey)
			if not res then
				ngx.say("failed to get originality data of dip: ", tkey, err)
				return
			else
				if string.find(res, "cz%a%a%a\/[0,1]\/") ~= nil then
					task[n] = res
				else
					-- base64 & gzip
					local data = base64.decode(res);
					-- local data = ngx.decode_base64(qbody);
					local output = {}
					deflate.gunzip {
					  input = data,
					  output = function(byte) output[#output+1] = string.char(byte) end
					}
					data = table.concat(output)
					if string.find(data, "ckiPsgSegInfoList") ~= nil then
						task[n] = "czpsg/0/" .. res
					else
						task[n] = "czflt/0/" .. res
					end
				end
				check = true;
				resnum = resnum + 1;
				-- ngx.say(tkey)
				res, err = memc:delete(tkey)
				if not res then
					ngx.say("failed to delete originality data of dip: ", tkey, err)
					return
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
		ngx.print(error002)
	end
else
	ngx.exit(ngx.HTTP_FORBIDDEN);
end
-- put it into the connection pool of size 512,
-- with 0 idle timeout
local ok, err = red:set_keepalive(0, 512)
if not ok then
	ngx.say("failed to set keepalive redis: ", err)
	return
end
