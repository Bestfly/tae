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
						print(tmpline)