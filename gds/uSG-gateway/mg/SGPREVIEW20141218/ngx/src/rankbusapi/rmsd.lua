-- buyhome <huangqi@rhomobi.com> 20150108 (v0.5.2)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- kvdb service of JuHang for HiGDS service
-- load library
local JSON = require 'cjson'
local base64 = require 'base64'
package.path = "/mnt/dc/usgcore/ngx/lib/?.lua;";
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
red:set_timeout(3000) -- 1 sec
-- nosql connect
local ok, err = red:connect("127.0.0.1", 61398)
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
local ok, err = memc:connect("127.0.0.1", 11978)
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
	if harg["Auth-Timestamp"] ~= nil and harg["Auth-Signature"] ~= nil and harg["Auth-Appid"] ~= nil and harg["sn"] ~= nil then
		if math.abs(harg["Auth-Timestamp"] - os.time()) >= 3600 and (harg["Auth-Appid"] ~= appidc01 or harg["Auth-Appid"] ~= appidc02) then
			ngx.exit(ngx.HTTP_UNAUTHORIZED);
		else
			if ngx.md5(verifykey .. harg["Auth-Timestamp"] .. harg["Auth-Appid"]) ~= harg["Auth-Signature"] then
				ngx.exit(ngx.HTTP_UNAUTHORIZED);
			else
				if harg["If-Match"] ~= nil then
					if harg["If-Match"] == 'unsort' then
						local checknil = false;
						local respbody = {};
						local resnum = 0;
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
								if red:exists("avh:" .. tkey) ~= 0 then
									local res, err = red:hget(tkey, hid)
									if not res then
										ngx.print(error003("failed to get vb->>" .. tkey .. '|' .. hid))
										return
									else
										respbody[key] = res
										checknil = true
										resnum = resnum + 1
									end
								else
									respbody[key] = JSON.null
									checknil = true
									resnum = resnum + 1
									red:del(tkey);
								end
							end
						end
						if checknil ~= false then
							-- ngx.print(JSON.encode(respbody))
							local result = {};
							result["resultCode"] = 0;
							result["dataNumber"] = resnum;
							result["dataDetail"] = respbody;
							ngx.print(JSON.encode(result))
						else
							ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
							-- ngx.exit(ngx.HTTP_BAD_REQUEST);
						end
					else
						if harg["If-Match"] == 'sort' then
							local checknil = false;
							local respbody = {};
							local resnum = 0;
						    for key, val in pairs(parg) do
								if red:exists("avh:" .. key) ~= 0 then
									local res, err = red:zrange(key, 0, 0, "WITHSCORES") -- ZRANGE myzset 0 -1
									if not res then
										ngx.print(error003("failed to get vb->>" .. key .. '|' .. ngx.now()))
										return
									else
										if table.getn(res) ~= 0 then
											local i = 1;
											-- ngx.say(table.getn(res),res[1],res[2],res[3],res[4])
											while i < table.getn(res) do
												local t = {}
												t[res[i]] = res[i + 1]
												-- pcontent.sn .. ":" .. pcontent.uk
												local kvid = string.sub(key, 1, 3) .. ngx.md5(key .. ":" .. res[i])
												local resultvb = memc:get(kvid)
												if not resultvb then
													-- respbody[res[1]] = res[2]
													ngx.log(ngx.ERR, error003("failed to get originality data from kvdb: ", kvid, err))
													-- ngx.print(error003("failed to get originality data from kvdb: ", kvid, err))
													-- return
													-- 取不到值也不要退出，避免过去的vb是空或者''
												else
												-- ngx.say(res[1])
													t["oriValue"] = resultvb
												end
												checknil = true
												resnum = resnum + 1
												i = i + 2
												table.insert(respbody,t)
											end
										else
											checknil = true
										end
									end
								else
									t = JSON.null
									checknil = true
									resnum = resnum + 1
									table.insert(respbody,t)
									red:del(tkey);
								end
							end
							if checknil ~= false then
								-- ngx.print(JSON.encode(respbody))
								local result = {};
								result["resultCode"] = 0;
								result["dataNumber"] = resnum;
								result["dataDetail"] = respbody;
								ngx.print(JSON.encode(result))
							else
								ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
								-- ngx.exit(ngx.HTTP_BAD_REQUEST);
							end
						else
							local idx1,idx2,idx3,idx4 = string.find(harg["If-Match"], '(%d+),(%d+)')
							if tonumber(idx3) ~= nil and tonumber(idx4) ~= nil then
								local checknil = false;
								local respbody = {};
								local resnum = 0;
							    for key, val in pairs(parg) do
									-- ngx.say(red:exists("avh:" .. key))
									-- true 1, false 0
									if red:exists("avh:" .. key) ~= 0 then
										local res, err = red:zrangebyscore(key, idx3, idx4, "WITHSCORES")
										if not res then
											ngx.print(error003("failed to get vb->>" .. key .. '|' .. ngx.now()))
											return
										else
											if table.getn(res) ~= 0 then
												local i = 1;
												while i < table.getn(res) do
													local t = {}
													t[res[i]] = res[i + 1]
													-- pcontent.sn .. ":" .. pcontent.uk
													local kvid = string.sub(key, 1, 3) .. ngx.md5(key .. ":" .. res[i])
													local resultvb = memc:get(kvid)
													if not resultvb then
														-- respbody[res[1]] = res[2]
														ngx.log(ngx.ERR, error003("failed to get originality data from kvdb: ", kvid, err))
													else
													-- ngx.say(res[1])
														t["oriValue"] = resultvb
													end
													checknil = true
													resnum = resnum + 1
													i = i + 2
													table.insert(respbody,t)
												end
											else
												checknil = true
											end
										end
									else
										t = JSON.null
										checknil = true
										resnum = resnum + 1
										table.insert(respbody,t)
										red:del(tkey);
									end
								end
								if checknil ~= false then
									-- ngx.print(JSON.encode(respbody))
									local result = {};
									result["resultCode"] = 0;
									result["dataNumber"] = resnum;
									result["dataDetail"] = respbody;
									ngx.print(JSON.encode(result))
								else
									ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
									-- ngx.exit(ngx.HTTP_BAD_REQUEST);
								end
							else
								ngx.print(error008)
							end
						end
					end
				else
					ngx.print(error006)
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
					if pcontent.dt ~= nil and pcontent.uk ~= nil and pcontent.sn ~= nil then
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
									-- client:expire('intl:ctrip:' .. tkey, (expiret - os.time()))
									if tonumber(pcontent.tl) ~= nil then
										local r, e = red:set("avh:" .. tkey, 1)
										if not e then
											red:expire("avh:" .. tkey, tonumber(pcontent.tl))
										end
									end
									ngx.print(error000("Sucess to save vb->>" .. tkey .. '|' .. hid .. '|' .. pcontent.vb))
								end
							else
								ngx.print(error003("error001#unKnow sn+uk#Content"))
							end
						else
							if pcontent.dt == 11 then
								if pcontent.sc ~= nil then
									-- ngx.print(error002)
									local tkey = pcontent.sn .. ":" .. pcontent.uk
									local idx1, idx2, idx3, idx4, idx5 = string.find(tkey, '([a-z]+):([0-9a-zA-Z]+):(.+)');
									-- sn[1] = 3 & uk > 3
									if string.len(idx3) == 3 and string.len(idx5) > 2 then
										local res, err = red:zadd(pcontent.sn, tonumber(pcontent.sc), pcontent.uk)
										if not res then
											ngx.print(error003("failed to add sort vb->>" .. pcontent.sn .. '|' .. pcontent.sc .. '|' .. pcontent.uk))
											return
										else
											if pcontent.vb ~= nil then
												if pcontent.vb ~= "" then
													local ok = memc:set(idx3 .. ngx.md5(tkey), pcontent.vb)
													if not ok then
														ngx.print(error003("failed to save vb->>" .. idx3 .. tkey .. '|' .. pcontent.uk .. '|' .. pcontent.vb))
														return
													else
														ngx.print(error000("Sucess to save vb->>" .. idx3 .. tkey .. '|' .. pcontent.uk .. '|' .. pcontent.vb))
													end
												else
													ngx.print(error007)
												end
											else
												ngx.print(error000("Sucess to add sort vb->>" .. pcontent.sn .. '|' .. pcontent.sc .. '|' .. pcontent.uk))
											end
											-- client:expire('intl:ctrip:' .. tkey, (expiret - os.time()))
											if tonumber(pcontent.tl) ~= nil then
												local r, e = red:set("avh:" .. tkey, 1)
												if not e then
													r,e = red:expire("avh:" .. tkey, tonumber(pcontent.tl))
													ngx.say(r,e)
												end
											end
										end
									else
										ngx.print(error005)
									end
								else
									ngx.print(error004)
								end
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
