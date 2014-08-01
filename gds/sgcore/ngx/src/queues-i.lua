-- buyhome <huangqi@rhomobi.com> 20131208 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- kvdb service of rmsi for TAE service
-- load library
local JSON = require 'cjson'
package.path = "/data/sgcore/ngx/lib/?.lua;";
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
local error003 = JSON.encode({ ["resultCode"] = 3, ["description"] = "error003#Please input the ServiceName or Request body"});
local error004 = JSON.encode({ ["resultCode"] = 4, ["description"] = "error004#StartDate Not found in your headers"});
local error005 = JSON.encode({ ["resultCode"] = 5, ["description"] = "error005#Get IP from Queues is no result"});
local error006 = JSON.encode({ ["resultCode"] = 6, ["description"] = "error006#No IP left, Please buy more"});
function error009 (code, mes)
	local res = JSON.encode({ ["resultCode"] = code, ["description"] = mes});
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
local r, e = red:auth("142ffb5bfa1-cn-jijilu-dg-a75")
if not r then
    ngx.say("failed to authenticate: ", e)
    return
end
-- end of nosql init.
-- init the DICT.
-- local byfs = ngx.shared.biyifei;
-- local port = ngx.shared.airport;
-- local porg = port:get(string.upper(ngx.var.org));
-- local pdst = port:get(string.upper(ngx.var.dst));
-- local city = ngx.shared.citycod;
-- local torg = city:get(string.upper(ngx.var.org));
-- local tdst = city:get(string.upper(ngx.var.dst));
local verifykey = "19958883-A3B8-4B67-93F3-F73F47B20340";
if ngx.var.request_method == "GET" then
	ngx.exit(ngx.HTTP_FORBIDDEN);
else
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	local harg = ngx.req.get_headers();
	if not pcontent then
		ngx.print(error003)
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
							local leftstr = string.sub(qn, 1, idx-1)
							if string.len(rightstr) ~= 5 then
								ngx.exit(ngx.HTTP_BAD_REQUEST);
							else
								if leftstr ~= "dom" and leftstr ~= "room" then
									ngx.exit(ngx.HTTP_BAD_REQUEST);
								else
									if leftstr == "room" then
										qn = "que:room"
									end
									if leftstr == "hotel" then
										qn = "que:hotel"
									end
									if tonumber(otype) == 0 then
										local res, err = red:rpush(qn, rightstr .. "/0/" .. qbody);
										if not res then
											ngx.exit(ngx.HTTP_BAD_REQUEST);
										else
											ngx.exit(ngx.HTTP_OK);
										end
									end
									if tonumber(otype) == 1 then		
										local res, err = red:lpush(qn, rightstr .. "/1/" .. qbody);
										if not res then
											ngx.exit(ngx.HTTP_BAD_REQUEST);
										else
											ngx.exit(ngx.HTTP_OK);
										end
									end
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