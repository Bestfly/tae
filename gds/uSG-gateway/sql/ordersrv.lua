-- buyhome <huangqi@rhomobi.com> 20140417 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- Order service for s1 & pkg via cc/web/app
-- load library
local JSON = require 'cjson'
local JSON_safe = require 'cjson.safe'
local redis = require "resty.redis"
function error0000 (mes)
	local res = JSON.encode({ ["resultCode"] = 0, ["description"] = mes});
	return res
end
local error0001 = JSON.encode({ ["Code"] = "0001", ["Message"] = "系统异常"});
local error0012 = JSON.encode({ ["Code"] = "0012", ["Message"] = "参数格式错误"});
local error0013 = JSON.encode({ ["Code"] = "0013", ["Message"] = "订单编号类型不符合规范"});
local error0014 = JSON.encode({ ["Code"] = "0014", ["Message"] = "订单编号类型为空"});
local error0100 = JSON.encode({ ["Code"] = "100", ["Message"] = "请求参数为空"});
function error0003 (mes)
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
red:set_timeout(3000) -- 3 sec
-- nosql connect
local ok, err = red:connect("127.0.0.1", 16390)
if not ok then
	ngx.print(error0003("failed to connect redis: ", err))
	return
end
local r, e = red:auth("142ffb5bfa1-cn-jijilu-dg-a75")
if not r then
    ngx.print(error0003("failed to authenticate: ", e))
    return
end
--[[
function incrman(farekey)
	-- Caculate
	-- Add oraclefids to protect the farekey is unique.
	local farekey = ngx.md5(oraclefids .. content.org .. content.dst .. content.baseAirLine .. content.airPortPath .. content.sellStartDate .. content.sellEndDate .. content.travelerTypeId);
	local cavhcmd = content.org .. content.dst .. content.baseAirLine;
	local avhmulti = content.org .. "/" .. content.dst .. "/" .. content.baseAirLine .. "/";
	local fid = "";
	-- ngx.print("AVHCMD is: ", cavhcmd);
	-- ngx.print("\r\n---------------------\r\n");
	-- ngx.print("avhmulti is: ", avhmulti);
	-- ngx.print("\r\n---------------------\r\n");
	-- ngx.print(farekey);
	-- ngx.print("\r\n---------------------\r\n");
	local getfidres, getfiderr = red:get("fare:" .. farekey .. ":id")
	if not getfidres then
		ngx.print("failed to get " .. "fare:" .. farekey .. ":id: ", getfiderr)
		return
	end
	-- ngx.print(getfidres);
	-- ngx.print("\r\n---------------------\r\n");
	if tonumber(getfidres) == nil then
		-- fare:id INCR
		-- local farecounter, cerror = red:incr("next.fare.id")
		local farecounter, cerror = red:incr("fare:id")
		if not farecounter then
			ngx.print("failed to INCR fare: ", cerror);
			return
		end
		-- ngx.print("INCR fare result: ", farecounter);
		-- ngx.print("\r\n---------------------\r\n");
		local resultsetnx, fiderror = red:setnx("fare:" .. farekey .. ":id", farecounter)
		if not resultsetnx then
			ngx.print("failed to SETNX fid: ", fiderror);
			return
		end
		-- ngx.print("SETNX fid result: ", resultsetnx);
		-- ngx.print("\r\n---------------------\r\n");
		-- if resultsetnx ~= 1 that is SETNX is NOT sucess.
		if resultsetnx == 1 then
			fid = farecounter;
		else
			fid = red:get("fare:" .. farekey .. ":id");
		end
		-- Get the fid = fare:[farekey]:id
		-- ngx.print("The real fare.id is fid: ", fid);
		-- ngx.print("\r\n---------------------\r\n");
	else
		ngx.print("The FARE had already been stored!");
		ngx.print("\r\n---------------------\r\n");
		ngx.print("fare:" .. farekey .. ":id: ", getfidres);
		ngx.print("\r\n---------------------\r\n");
	end
end
--]]
if ngx.var.request_method ~= "GET" then
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	-- local puri = ngx.var.URI;
	local harg = ngx.req.get_headers();
	if not pcontent then
		-- ngx.exit(ngx.HTTP_BAD_REQUEST);
		ngx.print(error0100)
	else
		pcontent = JSON_safe.decode(pcontent)
		if not pcontent then
			ngx.print(error0012)
		else
			if pcontent.OrderType ~= nil then
				-- ngx.say(type(pcontent.productId))
				if (type(pcontent.OrderType) ~= 'string' and type(pcontent.OrderType) ~= 'number') or tonumber(pcontent.OrderType) == nil or string.len(pcontent.OrderType) ~= 1 then
					ngx.print(error0012)
					return
				else
					local tmprandom1 = math.random(1,9)
					local tmprandom2 = math.random(0,9)
					local ts = os.time()
					local today = os.date("%Y%m%d", ts)
					-- wnvm,1234
					local tkey = ""
					if tonumber(pcontent.OrderType) == 1 then
						tkey = "W"
					end
					if tonumber(pcontent.OrderType) == 2 then
						tkey = "N"
					end
					if tonumber(pcontent.OrderType) == 3 then
						tkey = "V"
					end
					if tonumber(pcontent.OrderType) == 4 then
						tkey = "M"
					end
					if tkey ~= "" then
						local farecounter, cerror = red:incr("inc:" .. today .. ":" .. tkey)
						if not farecounter then
							ngx.print("failed to INCR fare: ", cerror);
							return
						else
							tmprandom1 = tmprandom1 * 1000000 + farecounter * 10 + tmprandom2
							local orderid = today .. tmprandom1 .. tkey
							local resultsetnx, fiderror = red:hsetnx("pkg:" .. today .. ":" .. tkey, orderid, ts)
							if not resultsetnx then
								ngx.print("failed to hSETNX fid: ", fiderror, orderid, ts, "pkg:" .. today .. ":" .. tkey);
								return
							else
								if resultsetnx == 1 then
									-- ngx.print(orderid)
									local r = {};
									local t = {};
									t["ordercd"] = orderid
									r["Result"] = t
									r["Message"] = "生成订单编号成功"
									r["Code"] = "0"
									ngx.print(JSON.encode(r))
								else
									local getfidres, getfiderr = red:hget("pkg:" .. today .. ":" .. tkey, orderid)
									if not getfidres then
										ngx.print("failed to get OrderID:<<" .. orderid .. ">>in pkg:" .. today .. ":" .. tkey, getfiderr)
										return
									else
										if tonumber(getfidres) ~= nil then
											local r = {};
											local t = {};
											t["ordercd"] = orderid
											r["Result"] = t
											r["Message"] = "生成订单编号成功"
											r["Code"] = "0"
											ngx.print(JSON.encode(r))
										else
											local r = {};
											r["Message"] = "生成订单编号失败"
											r["Code"] = "400"
											ngx.print(JSON.encode(r))
										end
									end
								end
							end
						end
					else
						ngx.print(error0013)
						return
					end
				end
			else
				ngx.print(error0014)
				return
			end
		end
	end
else
	ngx.exit(ngx.HTTP_FORBIDDEN)
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 1000)
if not ok then
    -- ngx.say("failed to set keepalive: ", err)
	ngx.log(ngx.ERR, "failed to set keepalive with Redis: ", err)
    return
end