-- buyhome <huangqi@rhomobi.com> 20131208 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- queues service of crawler for bestfly service
-- load library
local JSON = require 'cjson'
local redis = require 'resty.redis'
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
local ok, err = red:connect("127.0.0.1", 6399)
if not ok then
	ngx.say("failed to connect redis: ", err)
	return
end
local r, e = red:auth("142ffb5bfa1-cn-jijilu-dg-a02")
if not r then
    ngx.say("failed to authenticate: ", e)
    return
end
if ngx.var.request_method == "POST" then
	ngx.exit(ngx.HTTP_FORBIDDEN);
else
	local t = tonumber(ngx.var.num);
	if t > 0 then
		local res, err = red:lrange("dip:list", 1, t)
	    if not res then
	        ngx.say("failed to lrange dip:list for [" .. t .. "] keys", err)
	        return
		else
			if type(res) ~= "table" then
				-- task[n] = JSON.null
				ngx.print(error002);
			else
				ngx.print(JSON.encode(res))
			end
	    end
	else
		ngx.print(error002);
	end
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 100)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end