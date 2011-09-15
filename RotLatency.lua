
local GetTime = Inspect.Time.Real
local tinsert, tremove, format = table.insert, table.remove, string.format
local gcd = "Power Strike"
local data = {}
local ctx = UI.CreateContext("RotLatency")
local text = UI.CreateFrame("Text", "Text", ctx)
text:SetPoint("CENTER", UIParent, "CENTER")
text:SetFontSize(15)
text:SetVisible(false)
local ability = "Path of the Wind"

table.insert(Event.Ability.Cooldown.Begin, {function(cooldowns)
	local time = GetTime()
	for id, v in pairs(cooldowns) do
		local ability = Inspect.Ability.Detail(id)
		data[id] = data[id] or {cooldown=ability.cooldown, name=ability.name}	
		tinsert(data[id], {start=time, remaining=ability.currentCooldownRemaining})
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

local lastUpdate = GetTime()
local function update()
	local elapsed = GetTime() - lastUpdate
	if elapsed > 1 then
		lastUpdate = GetTime()
		local i = 1
		for id, v in pairs(data) do
			local entry1 = v[#v]
			local entry2 = v[#v - 1]
			if entry2 and v.name == ability then
				entry2.finish = entry2.finish or entry2.start
				local tm1 = tonumber(format("%.2f", entry2.finish - entry2.start + .02))
				local tm2 = tonumber(format("%.2f", entry1.remaining))
				local tm3 = tonumber(format("%.2f", v.cooldown - .02))
				local tm1 = tonumber(format("%.2f", entry2.finish - entry2.start))
				local tm2 = tonumber(format("%.2f", entry1.remaining))
				local tm3 = tonumber(format("%.2f", v.cooldown))
				if tm1 >= tm3 and tm2 >= tm3 then
					count = (count or 0) + 1
					text:SetText("(" .. count .. ") " ..  v.name .. ": " .. format("%.2f", entry1.start - entry2.finish))
					text:ResizeToText()
					text:SetVisible(true)
				else
					text:SetText("wtf")
					text:SetVisible(false)
				end
			end
			i = i + 1
		end
	end
end

table.insert(Event.System.Update.Begin, {update, "StarTip", "refresh"})
