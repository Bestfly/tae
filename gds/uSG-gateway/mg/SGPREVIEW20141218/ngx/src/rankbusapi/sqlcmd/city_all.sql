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
-- AND pd.`proId`=5761
GROUP BY proId 
ORDER BY productNumber DESC;

/**{
"timestemp":"11位时间戳"
"type":"1"
}**/


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
  WHERE pd.`proId` = 5761/**出发地城市**/) 
GROUP BY pa.proId 


/**{
"timestemp":"11位时间戳"
"type":22
"cityKey":5761
}**/




--[[
{
    "departCityName": "深圳",
    "arriveCityName": "北京",
    "listType": "1",
    "departDate": "2015-05-10",
    "travelDays": "5",
    "passScenery": "张家界",
    "linePlay": "",
    "traffic": "",
    "index": "0",
    "themeId": "",
    "sortType": "1",
    "price": [
        500,
        0
    ]
}
--]]