local JSON = require 'cjson'

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

local a = "<![CDATA[路南区]]>"


-- a = string.match(a, '[\x80-\xff]', 2)

print(a)
print(os.time())
-- 1403080684
-- 1403080560459
function parseargs(s)
	local arg = {}
	string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
		arg[w] = a
	end)
	return arg
end
function unescape (s)
  s = string.gsub(s, "+", " ")
  s = string.gsub(s, "%%(%x%x)", function (h)
        return string.char(tonumber(h, 16))
      end)
  return s
end
s = "queryParamVO.cabinLevel=&queryParamVO.useAdvanced=&queryParamVO.position=4&queryParamVO.positionRet=4&queryParamVO.tripSegment=&queryParamVO.tripType=ow&queryParamVO.depAirport=&queryParamVO.arrAirport=&queryParamVO.depCityCn=%E6%B7%B1%E5%9C%B3&queryParamVO.depCity=SZX&queryParamVO.arrCityCn=%E4%B8%8A%E6%B5%B7&queryParamVO.arrCity=SHA&queryParamVO.depDate=2014-08-09&suppliers=CZS%2FHUS"

cgi = {}
function decode (s)
  for name, value in string.gfind(s, "([^&=]+)=([^&=]+)") do
    name = unescape(name)
    value = unescape(value)
    cgi[name] = value
  end
end
decode (s)

print(JSON.encode(cgi))
