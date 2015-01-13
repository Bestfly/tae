-- Jijilu <huangqi@rhomobi.com> 20140904 (v0.5.6)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- Service Gateway
package.path = "/data/sgcore/ngx/lib/?.lua;";
local redis = require "resty.redis"
local http = require "resty.http"
-- ready to connect to master redis.
local red, err = redis:new()
if not red then
	ngx.log(ngx.ERR, "failed to instantiate redis: ", err)
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(2000) -- 1 sec
-- nosql connect
local ok, err = red:connect("10.10.130.93", 61390)
if not ok then
	ngx.say("failed to connect redis: ", err)
	return
end
local r, e = red:auth("142ffb5bfa1-cn-jijilu-dg-a75")
if not r then
    ngx.say("failed to authenticate: ", e)
    return
end
-- main
local ips = ngx.shared.iplist;
local uas = ngx.shared.uagent;
local updatedt = ips:get("updatedt");
-- only update banned_ips from Redis once every 20 seconds:
if updatedt == nil or updatedt < ( ngx.now() - 20 ) then
    local updatedips, err = red:smembers("opened:ips");
    if err then
		ngx.log(ngx.WARN, "Redis read error retrieving banned_ips: " .. err);
	else
		-- replace the locally stored banned_ips with the updated values:
		ips:flush_all();
		-- insert the ips into the shared dict:
		for idx, banned_ip in ipairs(updatedips) do
        	ips:set(banned_ip, true);
		end
		ips:set("updatedt", ngx.now());
	end
end
if ngx.var.http_clientip ~= nil then
	if not ips:get(ngx.var.http_clientip) then
		ngx.log(ngx.WARN, "Banned IP detected and refused access: " .. ngx.var.http_clientip);
		return ngx.exit(ngx.HTTP_FORBIDDEN);
	end
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10, 100)
if not ok then
	ngx.log(ngx.ERR, "failed to set keepalive with Redis: ", err)
    return
end