local GetTime = Inspect.Time.Real
local tinsert, tremove, format = table.insert, table.remove, string.format
local data = {}
local ctx = UI.CreateContext("RotLatency")
local frame = UI.CreateFrame("Frame", "RotLatency", ctx)
local text = UI.CreateFrame("Text", "Text", frame)
text:SetFontSize(15)
text:SetText("--RotLatency--")
local ability_list = {"Searing Strike", "Punishing Blow"}
local count = 0
local width = 0

local abilities = Inspect.Ability.List()
for k,v in pairs(abilities) do
	local details = Inspect.Ability.Detail(k)
	if details then
		data[k] = {id=k, name=details.name, cooldown=details.cooldown or 1.5, text=UI.CreateFrame("Text", details.name, frame)}
		if details.cooldown then
			count = count + 1
			table.insert(ability_list, details.name)
		end 
	end
end

local oldFrame = text
for _, name in pairs(ability_list) do
	for k, v in pairs(data) do
		local details = Inspect.Ability.Detail(k)
		if details and details.name == name then
			
			data[k].text:SetPoint("TOPLEFT", oldFrame, "BOTTOMLEFT")
			oldFrame = data[k].text
			local txt = " ."..details.name..". "
			data[k].text:SetText(txt)
			data[k].text:SetVisible(true)
			local w = data[k].text:GetWidth()
			if w > width then width = w end
		end
	end
end


frame:SetPoint("CENTER", UIParent, "CENTER", -300, -(#abilities * text:GetHeight()))
frame:SetHeight(count * text:GetHeight())
frame:SetWidth(width)
frame:SetBackgroundColor(0, 0, 0, 1)
text:SetPoint("TOPLEFT", frame, "TOPLEFT")
text:SetVisible(true)

table.insert(Event.Ability.Cooldown.Begin, {function(cooldowns)
	local time = GetTime()
	for id, v in pairs(cooldowns) do
		local ability = Inspect.Ability.Detail(id)
		if ability then
			data[id] = data[id] or {cooldown=ability.cooldown, name=ability.name}	
			tinsert(data[id], {start=time, remaining=ability.currentCooldownRemaining})
		end
	end
end, "RotLatency", "refresh"})

table.insert(Event.Ability.Cooldown.End, {function(cooldowns)
	local time = GetTime()
	for id, v in pairs(cooldowns) do
		local entry = data[id] and data[id][#data[id]]
		if entry and data[id].cooldown then 
			entry.finish = GetTime() 
		end
	end
end, "RotLatency", "refresh"})

local function isMember(txt, tgt)
	for _, v in pairs(tgt) do
		if v.name == txt then return true end
	end
end

local lastUpdate = GetTime()
local function update()
	local elapsed = GetTime() - lastUpdate
	if elapsed > 1 then
		lastUpdate = GetTime()
		for id, v in pairs(data) do
			local entry1 = v[#v]
			local entry2 = v[#v - 1]
			data[id].total = data[id].total or 0
			local total = 0
			local i = 1
			for k, vv in pairs(data) do
				if entry2 and v.cooldown and entry1.remaining then
					entry2.finish = entry2.finish or entry2.start
					local tm1 = tonumber(format("%.2f", entry2.finish - entry2.start))
					local tm2 = tonumber(format("%.2f", entry1.remaining))
					local tm3 = tonumber(format("%.2f", v.cooldown - .01))
					local tm4 = tonumber(format("%.2f", entry1.start - entry2.finish))
					vv.i = (vv.i or 1) + 1
					vv.total = ((vv.total or 0) + tm1)
					local total = tonumber(format("%.2f", vv.total))
					local perc = total / vv.i
					local txt
					if tm1 >= tm3 and tm2 >= tm3 then
						vv.count = (vv.count or 0) + 1
				
						
						txt = format("(%d) %s: (%.2f sec) - %.2f avg", vv.count, vv.name, tm4, perc)
					else
						vv.count = 0
						txt = format("(%d) %s (<0.1 sec)  - $.2f avg", vv.count, v.name, perc)
					end
					vv.text:SetText(txt)
					vv.text:ResizeToText()

					i = i + 1
				end
			end
			v.text:ResizeToText()
		end
	end
end

table.insert(Event.System.Update.Begin, {update, "StarTip", "refresh"})
