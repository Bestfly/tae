-- Jijilu <huangqi@rhomobi.com> 20141020 (v0.5.2)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- Queues service of RankBus for TAE service
-- load library
local JSON = require 'cjson'
package.path = "/mnt/data/usgcore/ngx/lib/?.lua;";
local redis = require "resty.redis"
local http = require "resty.http"
-- local memcached = require "resty.memcached"
-- local deflate = require "compress.deflatelua"
-- originality
function error000 (mes)
	local res = JSON.encode({ ["resultCode"] = 0, ["description"] = mes});
	return res
end
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "error001#Service Name or UID & SID not input"});
function error002 (tid)
	local res = JSON.encode({ ["resultCode"] = 2, ["description"] = "error002#The TradeID " .. tid .. " not found, please buy or contact seller"});
	return res
end
local error007 = JSON.encode({ ["resultCode"] = 3, ["description"] = "error007#Please input the ServiceName or Request body"});
local error004 = JSON.encode({ ["resultCode"] = 4, ["description"] = "error004#StartDate Not found in your headers"});
local error005 = JSON.encode({ ["resultCode"] = 5, ["description"] = "error005#Get IP from Queues is no result"});
local error006 = JSON.encode({ ["resultCode"] = 6, ["description"] = "error006#No IP left, Please buy more"});
function error003 (code, mes)
	local res = JSON.encode({ ["resultCode"] = code, ["description"] = mes});
	return res
end
-- ready to connect to master redis.
local red, err = redis:new()
if not red then
	-- ngx.say("failed to instantiate redis: ", err)
	ngx.log(ngx.ERR, error003("failed to instantiate redis: ", err))
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(3000) -- 3 sec
-- nosql connect
local ok, err = red:connect("10.10.130.93", 61390)
if not ok then
	ngx.print(error003("failed to connect redis: ", err))
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
local verifykey = "19958883-A3B8-4B67-93F3-F73F47B20340";
if ngx.var.request_method == "GET" then
	ngx.exit(ngx.HTTP_FORBIDDEN);
else
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	local harg = ngx.req.get_headers();
	if not pcontent then
		ngx.print(error007)
	else
		if harg["Auth-Timestamp"] ~= nil and harg["Auth-Signature"] ~= nil then
			if math.abs(harg["Auth-Timestamp"] - os.time()) >= 3600 then
				-- ngx.exit(ngx.HTTP_UNAUTHORIZED);
				ngx.exit(ngx.HTTP_GONE);
			else
				if harg["ServiceName"] ~= nil and harg["uid"] ~= nil and harg["sid"] ~= nil then
					if ngx.md5(harg["Auth-Timestamp"] .. harg["uid"] .. ngx.md5(pcontent .. verifykey) .. harg["sid"] .. harg["ServiceName"]) ~= harg["Auth-Signature"] then
						ngx.exit(ngx.HTTP_UNAUTHORIZED);
					else
						-- ngx.print(pcontent);
						pcontent = JSON.decode(pcontent)
						local qbody = pcontent.qbody
						local otype = pcontent.type
						local qn = pcontent.queues
						local idx = string.find(qn, ":");
						if idx ~= nil then
							-- string.sub(qn, idx+1, -1)
							local rightstr = string.sub(qn, idx+1, -1)
							qn = "que:" .. string.sub(qn, 1, idx-1)
							if tonumber(otype) == 0 then
								local res, err = red:rpush(qn, rightstr .. "/0/" .. qbody);
								if not res then
									ngx.exit(ngx.HTTP_BAD_REQUEST);
								else
									-- ngx.exit(ngx.HTTP_OK);
									ngx.print(error000("Sucess to Save Queues->>" .. otype .. '|' .. qn .. '|' .. qbody))
								end
							end
							if tonumber(otype) == 1 then		
								local res, err = red:lpush(qn, rightstr .. "/1/" .. qbody);
								if not res then
									ngx.exit(ngx.HTTP_BAD_REQUEST);
								else
									-- ngx.exit(ngx.HTTP_OK);
									ngx.print(error000("Sucess to Add Queues->>" .. otype .. '|' .. qn .. '|' .. qbody))
								end
							end
						else
							ngx.exit(ngx.HTTP_BAD_REQUEST);
						end
					end
				else
					ngx.print(error001)
				end
			end
		else
			ngx.exit(ngx.HTTP_NOT_ALLOWED);
		end				
	end
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 1000)
if not ok then
	ngx.log(ngx.ERR, "cannot set Redis keepalive: ", err)
    return
end