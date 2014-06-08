lines = {
luaH_set = 10,
luaH_get = 24,
luaH_present = 48,
}

a = {}
for n in pairs(lines) do table.insert(a, n) end
table.sort(a)
for i,n in ipairs(a) do print(n) end



-- Main
local ad = "54807975-9730-4850-b6b4-862128352ab4"
local ak = "856474380e125a41" 
local xv = "20111128102912"
local sn = "GetSceneryList"
local ts = os.date("%Y-%m-%d %X", os.time()) .. ".000";
local signtab = { "Version=" .. xv, "AccountID=" .. ad, "ServiceName=" .. sn, "ReqTime=" .. ts }

a = {}
for k,v in pairs(signtab) do table.insert(a, v) end
table.sort(a)
for i,n in ipairs(a) do print(n) end
