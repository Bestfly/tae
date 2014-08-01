-- buyhome <huangqi@rhomobi.com> 20140730 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- Service Gateway
local sg = ngx.shared.sgcore;
sg:flush_all();
-- load mysql forward data into kvdb
local luasql = require "luasql.mysql"
local env = assert(luasql.mysql())
-- base_flights_city
local con = assert (env:connect("servicegate", "srvg", "srvg321'", "10.10.40.57", 3306))
-- local con = assert (env:connect("biyifei_base", "rhomobi_dev", "b6x7p6b6x7p6", "localhost", 3306))
con:execute("SET NAMES utf8")
-- local sqlcmd = "SELECT `serviceName`, `serviceUrl` FROM `tbl_service_map` WHERE `typeId` = '2'";
local sqlcmd = "SELECT `serviceName`, `serviceUrl` FROM `tbl_service_map`";
local cur = assert (con:execute(sqlcmd))
local row = cur:fetch ({}, "a")
while row do
	sg:set(row.serviceName, ngx.encode_base64(row.serviceUrl));
	row = cur:fetch (row, "a")
end
cur:close();