if string.find(_VERSION, "5.2") then
	table.getn = function (t)
		if t.n then
            return t.n
        else
            local n = 0
            for i in pairs(t) do
                if type(i) == "number" then
                    n = math.max(n, i)
                end
            end
        return n
        end
    end
end
local tmpline = "淘米";
local bool = false;
-- 1 电信, 2 联通, 3 移动, 4 教育, 5 长宽
local linet = {"电信","联通","移动","教育","长"};
for i = 1,table.getn(linet) do
	local idx = string.find(linet[i], tmpline)
	if idx ~= nil then
		tmpline = i;
		bool = true;
		break;
	end
end
if bool ~= true then
	tmpline = 0
end
-- print(tmpline)
--[[
0
1
45
rms
renwu
domc
ctrip
20141010
00000000
canbjs
--]]
local a = "rms:renwu:domc/ctrip/20141010.00000000/canbjs"
local idx1, idx2, idx3, idx4, idx5, idx6, idx7, idx8, idx9 = string.find(a, '([a-z]+):([a-z]+):([a-z]+)/([a-z]+)/([0-9]+).([0-9]+)/([a-z]+)')
print(idx1)
print(idx2)
print(idx3)
print(idx4)
print(idx5)
print(idx6)
print(idx7)
print(idx8)
print(idx9)


a = "intl/ctrip/20131130.20131230/bjslon"
local idx1, idx2, idx3, idx4, idx5, idx6, idx7 = string.find(a, '([a-z]+)/([a-z]+)/([0-9]+).([0-9]+)/([a-z]+)')
print(idx1)
print(idx2)
print(idx3)
print(idx4)
print(idx5)
print(idx6)
print(idx7)

a = "rms:renwu:fejwifjewoifjweqfojqwefl:few3jfeof"
local idx1, idx2, idx3, idx4, idx5 = string.find(a, '([a-z]+):([a-z]+):(.+)')
print(idx1)
print(idx2)
print(idx3)
print(idx4)
print(idx5)


a = "(234234,234234234]"
local idx1,idx2,idx3,idx4 = string.find(a, '(%d+),(%d+)')
print(idx3,idx4)
print(string.sub(a,1,idx1-1),string.sub(a,idx2+1,-1))