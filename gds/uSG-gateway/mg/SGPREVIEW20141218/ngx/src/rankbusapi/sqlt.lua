-- buyhome <huangqi@rhomobi.com> 20131208 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- kvdb service of rmsi for TAE service
-- load library
local JSON = require 'cjson'
-- package.path = "/mnt/dc/usgcore/ngx/lib/?.lua;";
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
    host = "10.169.210.134",
    port = 13306,
    database = "vacation",
    user = "rhomobi_gds",
    password = "b6x7p6b6x7p6",
    max_packet_size = 1024 * 1024 }
if not ok then
    ngx.print("failed to connect: ", err, ": ", errno, " ", sqlstate)
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
	if not pcontent or not harg["servicename"] then
		ngx.exit(ngx.HTTP_BAD_REQUEST);
	else
		pcontent = JSON.decode(pcontent)
		
		local pdata = "";
		if pcontent.departCityName ~= nil and pcontent.arriveCityName ~= nil and harg["servicename"] == "vacation.list" then
			pdata = ([=[

			/**列表页查询SQL
			* add by cc 2015-03-23
			***/
			SELECT DISTINCT X.* FROM (
			SELECT
			    z.id,
			    z.productId,
			    z.productName,
			    z.imageUrl,
			    z.tagList,
			    z.orignalPrice,
			    z.Price,
			    z.travelNumbers
			FROM
			  ((SELECT 
			    a.id,
			    a.orderCount,
			    a.thirdpartId AS productId,
			    a.vacationName AS productName,
			    a.`pictureUrl` AS imageUrl,
			    a.`tags` AS tagList,
			    a.`marketPrice` AS orignalPrice,
			    a.`salePrice` AS Price,
			    a.`orderCount` AS travelNumbers
			  FROM
			    product a  WHERE a.`status`=1 AND a.`onSale`=1 AND a.`productType`=1
				/**1跟团2自助**/
	
	
			    /**listType
			    AND a.ID IN (SELECT 
			      PRODUCTID 
			    FROM
			      pm_tui 
			    WHERE paramid = 
			      (SELECT 
			        id 
			      FROM
			        pm_params 
			      WHERE id = 10091
        
			      ))**/
				/**类型**/
	
	
	
	
			    /**-- AND a.`departureDate` LIKE '%%' 
			    /**departDate**/
	
	
	
	
			    -- AND a.`maxtravelDays` = 1
			    /**travelDays**/
	
			    -- AND a.`lineType` = 1
			    /**linePlay**/
	
			    -- AND a.`trafficType` = 1 
			    /**trafficType**/
	
			    -- AND a.`salePrice`>10 AND a.`salePrice`<500
	
	
	
			    -- AND c.`code`='21531'/**themeId**/
	
	
	
			    /**sortType**/
			    ORDER BY (CASE '0'
			        WHEN '0' THEN a.`id`
			        WHEN '1' THEN a.`salePrice`
			        WHEN '2' THEN a.`salePrice`
			        WHEN '3' THEN a.`orderCount`
			        WHEN '4' THEN a.`orderCount`
			        WHEN '5' THEN a.`ratings`
			        ELSE ID END)/****/) z
			    RIGHT JOIN 
			      (SELECT 
			        NAME,
			        productId 
			      FROM
			        product_arrival pa 
			      WHERE pa.`name`= '三亚'
			        /**arriveCityId**/
		
			      ) b 
			      ON z.id = b.productId 
			      LEFT JOIN product_theme c
			      ON z.id = c.`productId`
    
			  )) X
			  LEFT JOIN 
			    (SELECT 
			      productId,
			      NAME 
			    FROM
			      product_departure pd 
			    WHERE pd.`name` = '北京'
			      /**departCityId**/
	  
	  
			    ) Y
			    ON X.id = Y.productId 
			LIMIT 1 , 12 /**index**/


			]=]):format(pcontent.arriveCityName, pcontent.departCityName)
			-- ngx.print(pcontent)
			
		end
		
		if pcontent.timestemp ~= nil and tonumber(pcontent.type) ~= nil and harg["servicename"] == "static.data.city.update" then
			if tonumber(pcontent.cityKey) ~= nil then
				
				pdata = ([=[

				/** type=22根据出发地城市返回所有目的地城市**/
				SELECT 
				  COUNT(productid) AS productNumber,
				  NAME AS cityName,
				  proId AS cityId,
				  pa.code AS cityKey 
				FROM
				  product_arrival pa
				  WHERE pa.productid IN 
				  (SELECT 
				    productid 
				  FROM
				    product_departure pd 
				  WHERE pd.`proId` = %s/**出发地城市**/) 
				GROUP BY pa.proId 


				]=]):format(pcontent.cityKey)
				
			else
				
				pdata = ([=[

				/**返回所有出发地城市**/
				SELECT 
				  COUNT(productid) AS productNumber,
				  NAME AS cityName,
				  proId AS cityId ,
				  pd.code AS cityKey
				FROM
				  product_departure pd 
				  LEFT JOIN product p 
				    ON p.`id` = pd.`productId` 
				WHERE p.`productType` = %s
				GROUP BY proId 
				ORDER BY productNumber DESC;


				]=]):format(pcontent.type)
				
				
			end
		end
		
		if pcontent.timestemp ~= nil and tonumber(pcontent.type) ~= nil and harg["servicename"] == "static.data.theme.update" then
			pdata = ([=[

			SELECT 
			  COUNT(productid) AS productNumber,
			  NAME AS themeName,
			  proid AS themeId 
			FROM
			  product_theme pt 
			  LEFT JOIN product p 
			    ON pt.`productId` = p.`id` 
			WHERE p.`productType` = %s
			GROUP BY proId 
			ORDER BY productNumber DESC 

			]=]):format(pcontent.type)
		end
		
		
		
        -- run a select query, expected about 10 rows in
        -- the result set:
        res, err, errno, sqlstate =
            db:query(pdata)
        if not res then
            ngx.print("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
            return
		else
			-- ngx.print(JSON.encode(res))
			local t = {}
			local r = {}
			t["productData"] = res
			t["isAll"] = 1
			r["Result"] = t
			r["Code"] = 0
			ngx.print(JSON.encode(r))
        end
	end
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.print("failed to set keepalive: ", err)
    return
end