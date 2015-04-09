-- buyhome <huangqi@rhomobi.com> 20150108 (v0.5.2)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- kvdb service of JuHang for HiGDS service
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
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "error001#unKnowed dt/sn#Content"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "error002#Service unSupported now."});
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end
local error004 = JSON.encode({ ["resultCode"] = 4, ["description"] = "error004#SC must NOT be Null whhen dt == 12"});
local error005 = JSON.encode({ ["resultCode"] = 5, ["description"] = "error005#unSupported uk & sn[1]"});
local error006 = JSON.encode({ ["resultCode"] = 6, ["description"] = "error006#unSupported If-Match, Please input http header 'If-Match'"});
local error007 = JSON.encode({ ["resultCode"] = 7, ["description"] = "error007#Nothing need to be done for VB('')"});
local error008 = JSON.encode({ ["resultCode"] = 8, ["description"] = "error008#Please check your header 'If-Match', it must be (number1,number2]."});
-- ready to connect to master redis.
local red, err = redis:new()
if not red then
	-- ngx.say("failed to instantiate redis: ", err)
	ngx.log(ngx.ERR, "failed to instantiate redis: ", err)
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(1000) -- 1 sec
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
local appidc01 = "142ffb5bfa1-cn-jijilu-dg-c01"
local appidc02 = "142ffb5bfa1-cn-jijilu-dg-c02"
local verifykey = "5P826n55x3LkwK5k88S5b3XS4h30bTRg";
if ngx.var.request_method ~= "POST" then
	-- ngx.exit(ngx.HTTP_FORBIDDEN);
	local harg = ngx.req.get_headers();
	local parg = ngx.req.get_uri_args();
	-- ngx.say(type(parg))--table
	-- ngx.say(parg[1],parg[2])--nil
	if harg["Auth-Timestamp"] ~= nil and harg["Auth-Signature"] ~= nil and harg["Auth-Appid"] ~= nil and harg["If-Match"] ~= nil then
		if math.abs(harg["Auth-Timestamp"] - os.time()) >= 3600 and (harg["Auth-Appid"] ~= appidc01 or harg["Auth-Appid"] ~= appidc02) then
			ngx.exit(ngx.HTTP_UNAUTHORIZED);
		else
			if ngx.md5(verifykey .. harg["Auth-Timestamp"] .. harg["Auth-Appid"]) ~= harg["Auth-Signature"] then
				ngx.exit(ngx.HTTP_UNAUTHORIZED);
			else
				if harg["If-Match"] == 'sort' then
					local res, err = red:zrem(ngx.var.s1 .. ":" .. ngx.var.s2, ngx.var.uk)
					if res ~= 1 then
						ngx.print(error003("failed to del: " .. ngx.var.s1 .. ":" .. ngx.var.s2 .. "/" .. ngx.var.uk, err))
						return;
					else
						local ok = memc:delete(ngx.var.s1 .. ngx.md5(ngx.var.s1 .. ":" .. ngx.var.s2 .. ":" .. ngx.var.uk))
						ngx.print(error000(ok))
					end
				end
				if harg["If-Match"] == 'unsort' then
					local res, err = red:hdel(ngx.var.s1 .. ":" .. ngx.var.s2, ngx.var.uk)
					if not err then
						ngx.print(error000(res))
					else
						ngx.print(error003(res))
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
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 1000)
if not ok then
    -- ngx.say("failed to set keepalive: ", err)
	ngx.log(ngx.ERR, "failed to set keepalive with Redis: ", err)
    return
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle timeout
local ok, err = memc:set_keepalive(10000, 1000)
if not ok then
    -- ngx.say("cannot set keepalive: ", err)
	ngx.log(ngx.ERR, "failed to set keepalive with kvdb: ", err)
    return
end