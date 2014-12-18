-- Jijilu <huangqi@rhomobi.com> 20141218 (v0.5.7)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- Queues service of iRB for RankBus service
-- load library
--[[
-- 0.5.5~ zset to hash
-- 0.5.6~ replace to set for NOT set missing
-- 0.5.7~ md5 precaculate
--]]
local JSON = require 'cjson'
local base64 = require 'base64'
package.path = "/data/usgcore/ngx/lib/?.lua;";
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
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "error002#Service unSupported now"});
local error004 = JSON.encode({ ["resultCode"] = 4, ["description"] = "Get task from Queues is no result"});
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end
local error005 = JSON.encode({ ["resultCode"] = 5, ["description"] = "error005#VB and SC updated within your mission being done"});
local error006 = JSON.encode({ ["resultCode"] = 6, ["description"] = "error006#Call back RankBus Q+ with SC"});
local error007 = JSON.encode({ ["resultCode"] = 7, ["description"] = "error007#RankBus Server have NOT receieved your POST data"});
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
local memc, err = memcached:new()
if not memc then
    -- ngx.say("failed to instantiate memc: ", err)
	ngx.log(ngx.ERR, "failed to instantiate memc: ", err)
    return
end
memc:set_timeout(3000) -- 3 sec
local ok, err = memc:connect("10.10.130.93", 61978)
if not ok then
    ngx.print(error003("failed to connect: ", err))
    return
end
-- end of nosql init.
local verifykey = "5P826n55x3LkwK5k88S5b3XS4h30bTRb";
if ngx.var.request_method == "GET" then
	ngx.exit(ngx.HTTP_FORBIDDEN);
else
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	local puri = ngx.var.URI;
	local harg = ngx.req.get_headers();
	if not pcontent then
		-- ngx.exit(ngx.HTTP_BAD_REQUEST);
		ngx.print(error007)
	else
		-- Debug LOGs
		--[[
		local wname = "/data/logs/rholog.txt"
		local wfile = io.open(wname, "a+");
		wfile:write(os.date());
		wfile:write("\r\n---------------------\r\n");
		wfile:write(pcontent);
		wfile:write("\r\n---------------------\r\n");
		wfile:write(ngx.var.remote_addr);
		-- wfile:write("\r\n---------------------\r\n");
		-- wfile:write(puri,"?" .. harg["Auth-Signature"],"?" .. ngx.md5(verifykey .. harg["Auth-Timestamp"]));
		wfile:write("\r\n---------------------\r\n");
		for k, v in pairs(harg) do
			wfile:write(k .. ":" .. v .. "\n");
		end
		wfile:write("\r\n+++++++++++++++++++++\r\n");
		io.close(wfile);--]]
		if harg["Auth-Timestamp"] ~= nil and harg["Auth-Signature"] ~= nil then
			if math.abs(harg["Auth-Timestamp"] - os.time()) >= 3600 then
				ngx.exit(ngx.HTTP_GONE);
			else
				if ngx.md5(verifykey .. harg["Auth-Timestamp"]) ~= harg["Auth-Signature"] then
					ngx.exit(ngx.HTTP_UNAUTHORIZED);
				else
					pcontent = JSON.decode(pcontent)
					if pcontent.dt ~= nil and string.len(pcontent.dt) == 2 then
						local dt = tonumber(pcontent.dt)
						local uk = pcontent.uk
						local sc = pcontent.sc
						local idx1, idx2, idx3, idx4 = string.find(pcontent.qn, "([a-z]+):([a-z]+)")
						if dt ~= nil and uk ~= nil and idx3 ~= nil and idx4 ~= nil and idx2 == 9 then
							local md5uk = ngx.md5(uk)
							local kvid = idx4 .. md5uk
							-- sc must NOT be nil
							if sc ~= nil and sc ~= '' and sc ~= JSON.null then
								if dt < 10 then
									-- Q type data which been posted into RankBus first time
									-- dt 01,00
									local vb = pcontent.vb
									local md5vb = ngx.md5(vb)
									local share = string.sub(ngx.encode_base64(uk), 1, 3)
									local sortkey = md5uk;
									local tkey = idx3 .. ":vals:" .. idx4 .. ":" .. share;
									-- local tqdata = rightstr .. "/" .. otype .. "/" .. qbody
									-- callBack < 10
									-- vb = retry .. pcontent.dt .. "/" .. idx4 .. "/" .. vb;
									vb = pcontent.dt .. "/" .. idx4 .. "/" .. vb;
									-- vb = idx4 .. "/" .. dt .. "/" .. vb;
									local lit = string.sub(sc, 15, -1);
									if lit ~= nil and lit ~= "" then
										sc = os.time({year=string.sub(sc, 1, 4), month=tonumber(string.sub(sc, 5, 6)), day=tonumber(string.sub(sc, 7, 8)), hour=tonumber(string.sub(sc, 9, 10)), min=tonumber(string.sub(sc, 11, 12)), sec=tonumber(string.sub(sc, 13, 14))})
										sc = sc + lit / 10000
									else
										-- sc = tonumber(sc)
										-- the shortest length is 14
										sc = os.time({year=string.sub(sc, 1, 4), month=tonumber(string.sub(sc, 5, 6)), day=tonumber(string.sub(sc, 7, 8)), hour=tonumber(string.sub(sc, 9, 10)), min=tonumber(string.sub(sc, 11, 12)), sec=tonumber(string.sub(sc, 13, 14))})
									end
									local tscres, err = red:hget(tkey, sortkey)
									tscres = tonumber(tscres)--double
									if tscres ~= nil then
										if sc > tscres then
											-- update sc first.
											local res, err = red:hset(tkey, sortkey, sc)
											if not res then
												ngx.print(error003("failed to update uk's sc->>" .. tkey .. '|' .. uk .. '|' .. sc))
												return
											end
											local tvb = memc:get(kvid)
											local tmd = ""
											if tvb ~= nil then
												tmd = string.sub(tvb, 1, 32)
											end
											if md5vb ~= tmd then
												local ok = memc:replace(kvid, md5vb .. vb)
												if not ok then
													ngx.print(error003("failed to replace vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
													return
												else
													local tmp, trr = red:lrem(idx3 .. ":list", 0, kvid)
													if dt ~= 1 then
														local res, err = red:rpush(idx3 .. ":list", kvid)
														if not res or not tmp then
															ngx.print(error003("failed to rpush uk into " .. idx3 .. ":list->>" .. err))
															return
														else
															ngx.print(error000("Sucess to replace vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
														end
													else
														local res, err = red:lpush(idx3 .. ":list", kvid)
														if not res or not tmp then
															ngx.print(error003("failed to lpush uk into " .. idx3 .. ":list->>" .. err))
															return
														else
															ngx.print(error000("Sucess to replace vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
														end
													end
												end
											else
												ngx.print(error000(sc .. '#Nothing to do..for:' .. uk .. '#' .. vb));
												-- return--don't cancel
											end
										else
											ngx.print(error003(sc .. '#Nothing to do..for:' .. uk .. '#' .. tscres));
											-- return--don't cancel
										end
									else
										local res, err = red:hset(tkey, sortkey, sc)
										if not res then
											ngx.print(error003("failed to save uk's sc->>" .. tkey .. '|' .. uk .. '|' .. sc))
											return
										else
											local ok = memc:set(kvid, md5vb .. vb)
											if not ok then
												ngx.print(error003("failed to replace vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
												return
											else
												if dt ~= 1 then
													local res, err = red:rpush(idx3 .. ":list", kvid)
													if not res then
														ngx.print(error003("failed to rpush uk into " .. idx3 .. ":list->>" .. err))
														return
													else
														ngx.print(error000("Sucess to save vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
													end
												else
													local res, err = red:lpush(idx3 .. ":list", kvid)
													if not res then
														ngx.print(error003("failed to lpush uk into " .. idx3 .. ":list->>" .. err))
														return
													else
														ngx.print(error000("Sucess to save vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
													end
												end
											end
										end
									end
								else
									if tonumber(dt) == 12 then
										-- NOT Q type data which been posted into RankBus first
										-- dt 12
										local vb = pcontent.vb
										local sortkey = md5uk;
										local tkey = "elg:vals:" .. idx3;
										-- local tqdata = rightstr .. "/" .. otype .. "/" .. qbody
										vb = dt .. "/" .. idx4 .. "/" .. vb;
										-- vb = idx4 .. "/" .. dt .. "/" .. vb;
										local kvid = idx3 .. sortkey;
										local lit = string.sub(sc, 15, -1);
										if lit ~= nil and lit ~= "" then
											sc = os.time({year=string.sub(sc, 1, 4), month=tonumber(string.sub(sc, 5, 6)), day=tonumber(string.sub(sc, 7, 8)), hour=tonumber(string.sub(sc, 9, 10)), min=tonumber(string.sub(sc, 11, 12)), sec=tonumber(string.sub(sc, 13, 14))})
											sc = sc + lit / 10000
										else
											-- sc = tonumber(sc)
											-- the shortest length is 14
											sc = os.time({year=string.sub(sc, 1, 4), month=tonumber(string.sub(sc, 5, 6)), day=tonumber(string.sub(sc, 7, 8)), hour=tonumber(string.sub(sc, 9, 10)), min=tonumber(string.sub(sc, 11, 12)), sec=tonumber(string.sub(sc, 13, 14))})
										end
										local tscres, err = red:hget(tkey, sortkey)
										tscres = tonumber(tscres)--double
										if tscres ~= nil then
											if sc > tscres then
												-- update sc.
												local res, err = red:hset(tkey, sortkey, sc)
												if not res then
													ngx.print(error003("failed to save uk's sc->>" .. tkey .. '|' .. uk .. '|' .. sc))
													return
												end
												local ok = memc:replace(kvid, vb)
												if not ok then
													ngx.print(error003("failed to replace vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
													return
												else
													ngx.print(error000("Sucess to replace vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
												end
											else
												ngx.print(error003(sc .. '#Nothing to do..for:' .. uk .. '#' .. tscres));
												-- return--don't cancel
											end
										else
											local res, err = red:hset(tkey, sortkey, sc)
											if not res then
												ngx.print(error003("failed to save uk's sc->>" .. tkey .. '|' .. uk .. '|' .. sc))
												return
											end
											local ok = memc:set(kvid, vb)
											if not ok then
												ngx.print(error003("failed to replace vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
												return
											else
												ngx.print(error000("Sucess to save vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
											end
										end
									else
										ngx.print(error006)
									end
								end
							else
								if dt >= 10 then
									-- Job failure to Call back RankBus Q+
									-- dt 11,10,21,20,31,30 ~ 90,91
									-- callBack < 10
									local tmp, trr = red:lrem(idx3 .. ":list", 0, kvid)
									if tmp ~= 0 then
										-- vb update within the mission being done.
										local res, err = red:lpush(idx3 .. ":list", kvid)
										if not res or not tmp then
											ngx.print(error003("failed to lpush uk in Calling back RankBus Q+: " .. idx3 .. ":list->>" .. err))
											-- must be logged or changed to use while ... do;
											return
										else
											ngx.print(error005)
										end
									else
										local rdata, rerr = memc:get(kvid)
										if not rdata then
											ngx.print(error003("failed to get originality data from kvdb: " .. kvid .. "->> kv GET Error"))
											return
										else
											local vb = string.sub(rdata, 1, 32) .. dt .. string.sub(rdata, 35, -1)
											rdata, rerr = memc:replace(kvid, vb)
											if not rdata then
												ngx.print(error003("failed to replace vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
												return
											else
												if tonumber(string.sub(dt, 0, -1)) ~= 1 then
													local res, err = red:rpush(idx3 .. ":list", kvid)
													if not res or not tmp then
														ngx.print(error003("failed to rpush uk into " .. idx3 .. ":list->>" .. err))
														return
													else
														ngx.print(error000("Sucess to Callback RankBus Q+ >>" .. kvid .. '|' .. uk .. '|' .. idx3))
													end
												else
													local res, err = red:lpush(idx3 .. ":list", kvid)
													if not res or not tmp then
														ngx.print(error003("failed to rpush uk into " .. idx3 .. ":list->>" .. err))
														return
													else
														ngx.print(error000("Sucess to Callback RankBus Q+ >>" .. kvid .. '|' .. uk .. '|' .. idx3))
													end
												end
											end
										end
									end
								else
									-- except the sc == '' or JSON.null or nil with dt < 10
									-- ngx.exit(ngx.HTTP_BAD_REQUEST);
									ngx.print(error003("sc must NOT be nil when DT < 10 :" .. dt .. "->>" .. sc))
								end
							end
						else
							ngx.exit(ngx.HTTP_BAD_REQUEST);
						end
					else
						ngx.print(error001)
					end
				end
			end
		else
			ngx.exit(ngx.HTTP_NOT_ALLOWED);
		end
	end
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