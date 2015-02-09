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
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "error001#unKnow dt#Content"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "error002#Service unSupported now."});
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end
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
local appidc01 = "142ffb5bfa1-cn-jijilu-dg-c01"
local appidc02 = "142ffb5bfa1-cn-jijilu-dg-c02"
local verifykey = "5P826n55x3LkwK5k88S5b3XS4h30bTRg";
if ngx.var.request_method ~= "POST" then
	-- ngx.exit(ngx.HTTP_FORBIDDEN);
	local harg = ngx.req.get_headers();
	local parg = ngx.req.get_uri_args();
	-- ngx.say(type(parg))--table
	-- ngx.say(parg[1],parg[2])--nil
	if harg["Auth-Timestamp"] ~= nil and harg["Auth-Signature"] ~= nil and harg["Auth-Appid"] ~= nil and harg["sn"] ~= nil then
		if math.abs(harg["Auth-Timestamp"] - os.time()) >= 3600 and (harg["Auth-Appid"] ~= appidc01 or harg["Auth-Appid"] ~= appidc02) then
			ngx.exit(ngx.HTTP_UNAUTHORIZED);
		else
			if ngx.md5(verifykey .. harg["Auth-Timestamp"] .. harg["Auth-Appid"]) ~= harg["Auth-Signature"] then
				ngx.exit(ngx.HTTP_UNAUTHORIZED);
			else
				local checknil = false;
				local respbody = {};
			    for key, val in pairs(parg) do
					-- ngx.say(type(val))--boolean
					-- domc/ctrip/20141010.00000000/canbjs: true
					--[[
			        if type(val) == "table" then
			            ngx.say(key, ": ", table.concat(val, ", "))
			        else
			            ngx.say(key, ": ", val)
			        end
					--]]
					-- intl/ctrip/20131130.20131230/bjslon
					local idx1, idx2, idx3, idx4, idx5, idx6, idx7 = string.find(key, '([a-z]+)/([a-z]+)/([0-9]+).([0-9]+)/([a-z]+)');
					if idx2 == 35 and idx3 ~= nil and idx4 ~= nil and idx5 ~= nil and idx6 ~= nil and idx7 ~= nil then
						--[[
						local tkey = "rms/renwu/" .. string.sub(key, 1, 19)
						tkey = string.gsub(tkey, "/", ":")
						local hid = string.sub(key, 21, -1)
						hid = string.gsub(hid, "/", "")
						--]]
						local tkey = harg["sn"] .. ":" .. idx3 .. ":" .. idx4 .. ":" .. idx5
						local hid = idx6 .. idx7
						-- ngx.print(tkey,hid)
						local res, err = red:hget(tkey, hid)
						if not res then
							ngx.print(error003("failed to get vb->>" .. tkey .. '|' .. hid))
							return
						else
							respbody[key] = res
						end
						checknil = true;
					end
				end
				if checknil ~= false then
					ngx.print(JSON.encode(respbody))
				else
					ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
					-- ngx.exit(ngx.HTTP_BAD_REQUEST);
				end
			end
		end
	else
		ngx.exit(ngx.HTTP_NOT_ALLOWED);
	end	
else
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	-- local puri = ngx.var.URI;
	local harg = ngx.req.get_headers();
	-- ["Auth-Timestamp"] = timestamp,
	-- ["Auth-Signature"] = md5.sumhexa(sinakey .. timestamp),
	if not pcontent then
		ngx.exit(ngx.HTTP_BAD_REQUEST);
	else
		if harg["Auth-Timestamp"] ~= nil and harg["Auth-Signature"] ~= nil and harg["Auth-Appid"] ~= nil then
			-- if math.abs(harg["Auth-Timestamp"] - os.time()) >= 3600 then
			if math.abs(harg["Auth-Timestamp"] - os.time()) >= 3600 and (harg["Auth-Appid"] ~= appidc01 or harg["Auth-Appid"] ~= appidc02) then
				ngx.exit(ngx.HTTP_UNAUTHORIZED);
			else
				-- if ngx.md5(verifykey .. harg["Auth-Timestamp"]) ~= harg["Auth-Signature"] then
				if ngx.md5(verifykey .. harg["Auth-Timestamp"] .. harg["Auth-Appid"]) ~= harg["Auth-Signature"] then
					ngx.exit(ngx.HTTP_UNAUTHORIZED);
				else
					-- ngx.print(pcontent);
					pcontent = JSON.decode(pcontent)
					if pcontent.dt ~= nil and pcontent.uk ~= nil then
						if pcontent.dt == 10 then
							-- rms:renwu:domc/ctrip/20141010.00000000/canbjs
							local tkey = pcontent.sn .. ":" .. pcontent.uk
							local idx1, idx2, idx3, idx4, idx5, idx6, idx7, idx8, idx9 = string.find(tkey, '([a-z]+):([a-z]+):([a-z]+)/([a-z]+)/([0-9]+).([0-9]+)/([a-z]+)');
							-- ngx.print(idx3,idx7,idx8,idx9)
							if idx2 == 45 and string.len(idx7) == 8 and string.len(idx8) == 8 and string.len(idx9) == 6 then
								tkey = pcontent.sn .. ":" .. idx5 .. ":" .. idx6 .. ":" .. idx7
								local hid = idx8 .. idx9
								local res, err = red:hset(tkey, hid, pcontent.vb)
								if not res then
									ngx.print(error003("failed to save vb->>" .. tkey .. '|' .. hid .. '|' .. pcontent.vb))
									return
								else
									ngx.print(error000("Sucess to save vb->>" .. tkey .. '|' .. hid .. '|' .. pcontent.vb))
								end
							else
								ngx.print(error003("error001#unKnow sn+uk#Content"))
							end
						else
							if pcontent.dt == 11 then
								ngx.print(error002)
							else
								ngx.print(error001)
							end
						end
					else
						ngx.print(error001)
					end
				end
			end
		else
			ngx.exit(ngx.HTTP_NOT_ALLOWED);
			-- ngx.say(os.time())
			-- ngx.say(math.abs(os.time() - harg["Auth-Timestamp"]))
		end
	end
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 1000)
if not ok then
    -- ngx.say("failed to set keepalive: ", err)
	ngx.log(ngx.ERR, "failed to set keepalive with Redis: ", err)
    return
end