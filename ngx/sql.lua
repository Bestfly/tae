-- buyhome <huangqi@rhomobi.com> 20131208 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- kvdb service of rmsi for TAE service
-- load library
local JSON = require 'cjson'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
local mysql = require "resty.mysql"
-- local memcached = require "resty.memcached"
-- local deflate = require "compress.deflatelua"
-- originality
function error000 (mes)
	local res = JSON.encode({ ["resultCode"] = 0, ["description"] = mes});
	return res
end
local db, err = mysql:new()
if not db then
	ngx.print(ngx.ERR, "failed to instantiate mysql: ", err)
	-- ngx.log(ngx.ERR, "failed to instantiate mysql: ", err)
	return
end
db:set_timeout(1000) -- 1 sec
local ok, err, errno, sqlstate = db:connect{
    host = "123.57.188.136",
    port = 13306,
    database = "Jijilu_wp",
    user = "rhomobi_gds",
    password = "b6x7p6b6x7p6",
    max_packet_size = 1024 * 1024 }
if not ok then
    ngx.print("failed to connect: ", err, ": ", errno, " ", sqlstate)
    return
else
	ngx.print("connected to mysql.")
end
--[[
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
--]]
-- end of nosql init.
if ngx.var.request_method ~= "GET" then
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	-- local puri = ngx.var.URI;
	local harg = ngx.req.get_headers();
	-- ["Auth-Timestamp"] = timestamp,
	-- ["Auth-Signature"] = md5.sumhexa(sinakey .. timestamp),
	if not pcontent then
		ngx.exit(ngx.HTTP_BAD_REQUEST);
	else
		ngx.print(pcontent)
	end
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 100)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end