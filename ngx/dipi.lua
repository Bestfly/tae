-- buyhome <huangqi@rhomobi.com> 20131208 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- Queues service of dipi for TAE service
-- load library
local JSON = require 'cjson'
local base64 = require 'base64'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
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
local error004 = JSON.encode({ ["resultCode"] = 4, ["description"] = "Get task from Queues is no result"});
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
-- end of nosql init.
local verifykey = "5P826n55x3LkwK5k88S5b3XS4h30bTRp";
if ngx.var.request_method == "GET" then
	local harg = ngx.req.get_headers();
	local parg = ngx.req.get_uri_args();
	if harg["Auth-Timestamp"] ~= nil and harg["Auth-Signature"] ~= nil then
		if math.abs(harg["Auth-Timestamp"] - os.time()) >= 3600 then
			-- ngx.exit(ngx.HTTP_UNAUTHORIZED);
			ngx.exit(ngx.HTTP_GONE);
		else
			if ngx.md5(verifykey .. harg["Auth-Timestamp"]) ~= harg["Auth-Signature"] then
				ngx.exit(ngx.HTTP_UNAUTHORIZED);
			else
				local task = {};
				local check = false;
				local resnum = 0;
				for n = 1, ngx.var.num do
					local res, err = red:lpop("dip:list")
					if type(res) ~= "string" then
						task[n] = JSON.null
						break;
					else
						-- local tkey = res[2];
						local tkey = res;
						res, err = memc:get(tkey)
						if not res then
							ngx.say("failed to get originality data of dip: ", tkey, err)
							return
						else
							if string.find(res, "cz%a%a%a\/[0,1]\/") ~= nil then
								task[n] = res
							else
								-- base64 & gzip
								local data = base64.decode(res);
								-- local data = ngx.decode_base64(qbody);
								local output = {}
								deflate.gunzip {
								  input = data,
								  output = function(byte) output[#output+1] = string.char(byte) end
								}
								data = table.concat(output)
								if string.find(data, "ckiPsgSegInfoList") ~= nil then
									task[n] = "czpsg/0/" .. res
								else
									task[n] = "czflt/0/" .. res
								end
							end
							check = true;
							resnum = resnum + 1;
							-- Cancel delete the vd data for webservice developing via redis indexsystem
							--[[
							res, err = memc:delete(tkey)
							if not res then
								ngx.say("failed to delete originality data of dip: ", tkey, err)
								return
							end
							--]]
						end
					end
				end
				if check == true then
					local result = {};
					result["resultCode"] = 0;
					result["tasknumber"] = resnum;
					result["taskQueues"] = task;
					ngx.print(JSON.encode(result))
				else
					ngx.print(error004)
				end
			end
		end
	else
		ngx.exit(ngx.HTTP_NOT_ALLOWED);
	end
else
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	local puri = ngx.var.URI;
	local harg = ngx.req.get_headers();
	if not pcontent then
		ngx.exit(ngx.HTTP_BAD_REQUEST);
	else
		--[[
		--Debug LOGs
		local wname = "/data/logs/rholog.txt"
		local wfile = io.open(wname, "w+");
		wfile:write(os.date());
		wfile:write("\r\n---------------------\r\n");
		wfile:write(pcontent);
		wfile:write("\r\n---------------------\r\n");
		wfile:write(ngx.var.remote_addr);
		wfile:write("\r\n---------------------\r\n");
		wfile:write(puri,"?" .. harg["Auth-Signature"],"?" .. ngx.md5(verifykey .. harg["Auth-Timestamp"]));
		wfile:write("\r\n---------------------\r\n");
		for k, v in pairs(harg) do
			wfile:write(k .. ":" .. v .. "\n");
		end
		wfile:write("\r\n---------------------\r\n");
		io.close(wfile);
		--]]
		if harg["Auth-Timestamp"] ~= nil and harg["Auth-Signature"] ~= nil then
			if math.abs(harg["Auth-Timestamp"] - os.time()) >= 3600 then
				ngx.exit(ngx.HTTP_GONE);
			else
				if ngx.md5(verifykey .. harg["Auth-Timestamp"]) ~= harg["Auth-Signature"] then
					ngx.exit(ngx.HTTP_UNAUTHORIZED);
				else
					pcontent = JSON.decode(pcontent)
					local dt = tonumber(pcontent.dt)
					local uk = pcontent.uk
					local sc = pcontent.sc
					local vb = pcontent.vb
					local idx1, idx2, idx3, idx4 = string.find(pcontent.qn, "([a-z]+)\:([a-z]+)")
					if dt ~= nil and uk ~= nil and sc ~= nil and idx3 ~= nil and idx4 ~= nil and idx2 == 9 then
						local sortkey = ngx.md5(uk) .. string.sub(ngx.encode_base64(uk), 1, 4);
						local tkey = idx3 .. ":vals:" .. idx4;
						-- local tqdata = rightstr .. "/" .. otype .. "/" .. qbody
						vb = idx4 .. "/" .. dt .. "/" .. vb;
						local kvid = idx4 .. ngx.md5(uk);
						local lit = string.sub(sc, 15, -1);
						if lit ~= nil and lit ~= "" then
							sc = os.time({year=string.sub(sc, 1, 4), month=tonumber(string.sub(sc, 5, 6)), day=tonumber(string.sub(sc, 7, 8)), hour=tonumber(string.sub(sc, 9, 10)), min=tonumber(string.sub(sc, 11, 12)), sec=tonumber(string.sub(sc, 13, 14))})
							sc = sc + lit / 10000
						else
							-- sc = tonumber(sc)
							-- the shortest length is 14
							sc = os.time({year=string.sub(sc, 1, 4), month=tonumber(string.sub(sc, 5, 6)), day=tonumber(string.sub(sc, 7, 8)), hour=tonumber(string.sub(sc, 9, 10)), min=tonumber(string.sub(sc, 11, 12)), sec=tonumber(string.sub(sc, 13, 14))})
						end
						local tscres, err = red:zscore(tkey, sortkey)
						tscres = tonumber(tscres)--double
						if tscres ~= nil then
							if sc > tscres then
								-- update sc.
								local res, err = red:zadd(tkey, sc, sortkey)
								if not res then
									ngx.print(error003("failed to save uk's sc->>" .. tkey .. '|' .. tk .. '|' .. sc))
									return
								end
								local ok = memc:replace(kvid, vb)
								if not ok then
									ngx.print(error003("failed to replace vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
									return
								else
									local tmp, trr = red:lrem(idx3 .. ":list", 0, kvid)
									local res, err = red:rpush(idx3 .. ":list", kvid)
									if not res or not tmp then
										ngx.print("failed to rpush uk into dip:list", err)
										return
									else
										ngx.print(error000("Sucess to replace vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
									end
								end
							else
								ngx.print("nothing to do..for: " .. uk);
								-- return--don't cancel
							end
						else
							local res, err = red:zadd(tkey, sc, sortkey)
							if not res then
								ngx.print(error003("failed to save uk's sc->>" .. tkey .. '|' .. tk .. '|' .. sc))
								return
							end
							local ok = memc:set(kvid, vb)
							if not ok then
								ngx.print(error003("failed to replace vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
								return
							else
								local res, err = red:rpush(idx3 .. ":list", kvid)
								if not res then
									ngx.print("failed to rpush tk into dip:list", err)
									return
								else
									ngx.print(error000("Sucess to save vb->>" .. kvid .. '|' .. uk .. '|' .. vb))
								end
							end
						end
					else
						ngx.exit(ngx.HTTP_BAD_REQUEST);
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
local ok, err = memc:set_keepalive(10000, 100)
if not ok then
    ngx.say("cannot set keepalive: ", err)
    return
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 100)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end