-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- price of extension for elong website : http://flight.elong.com/beijing-shanghai/cn_day19.html
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
local r, e = red:auth("142ffb5bfa1-cn-jijilu-dg-a01")
if not r then
    ngx.say("failed to authenticate: ", e)
    return
end
-- end of nosql init.
-- init the DICT.
-- local byfs = ngx.shared.biyifei;
if ngx.var.request_method == "GET" then
	local task = {};
	local check = false;
	local resnum = 0;
	for n = 1, ngx.var.num do
		local res, err = red:blpop("que:" .. ngx.var.que, 0)
		if res then
			task[n] = res[2]
			check = true;
			resnum = resnum + 1;
		else
			task[n] = JSON.null
			break;
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
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 100)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end