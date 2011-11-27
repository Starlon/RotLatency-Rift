local GetTime = Inspect.Time.Frame
local tinsert, tremove, format = table.insert, table.remove, string.format
local data = {}
local texts = {}
local ctx = UI.CreateContext("RotLatency")
local frame = UI.CreateFrame("Frame", "RotLatency", ctx)
local text = UI.CreateFrame("Text", "Text", frame)
local FormatDuration = LibStub("LibScriptablePluginLuaTexts-1.0"):New({}).FormatDuration


local abilities = Inspect.Ability.List()
local oldFrame = text
local count = 0

text:SetPoint("TOPLEFT", frame, "TOPLEFT")
text:SetVisible(true)
text:SetText("--RotLatency--")
text:ResizeToText()

frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, 40)
frame:SetBackgroundColor(0, 0, 0, 1)
frame:SetWidth(text:GetWidth())
frame:SetHeight(text:GetHeight())
frame:SetVisible(true)

local height = text:GetHeight()
local width = text:GetWidth()

local within = function(tbl, txt)
	for _, val in pairs(tbl) do
		if val == txt then return txt end
	end
end

local record = {}
local count = 0
for k,v in pairs(abilities or {}) do
	local details = Inspect.Ability.Detail(k)
	if details then
		count = count + 1
		local text = UI.CreateFrame("Text", "Text"..count, frame)
		text:SetText(details.name)
		text:ResizeToText()
		if text:GetWidth() > width then
			width = text:GetWidth()
		end
		data[k] ={id=k, 
			name=details.name, 
			cooldown=details.cooldown or 1.5, i = count}
		text:SetText(details.name)
		text:ResizeToText()
		text:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, count * height)
		tinsert(texts, text)
	end
end

frame:SetWidth(width)
frame:SetHeight((count + 1) * height )

table.insert(Event.Ability.Cooldown.Begin, {function(cooldowns)
	local time = GetTime()
	
	for id, v in pairs(cooldowns) do
		local ability = Inspect.Ability.Detail(id)
		if ability and data[id] then
			local remaining = ability.currentCooldownRemaining or 0
			tinsert(data[id], {start=time, remaining=remaining})
		end
	end
end, "RotLatency", "refresh"})


local lastUpdate = GetTime()
local lastFrame = text
local toDraw = {}
table.insert(Event.Ability.Cooldown.End, {function(cooldowns)
	local time = GetTime()
        local elapsed = time - lastUpdate
	local width = frame:GetWidth()
	local height = text:GetHeight()
	local count = 0
	lastFrame = text
	for id, v in pairs(cooldowns) do
		if data[id] then
			local entry1 = data[id][#data[id]] or {} -- trash
			local entry2 = #data[id] > 1 and data[id][#data[id]-1]
			entry1.finish = GetTime() 
			if entry1 and entry2 then
				local vv = data[id]
				vv.elapsed = (vv.elapsed or 0) + elapsed
				local text = data[id].text
				local latency = entry1.start - (entry2.finish or entry1.start)
				if latency < 0.5 then
					vv.elapsed = 0
				end

				local perc = (vv.total or 1) / #vv
				local dur = FormatDuration(data[id].elapsed, "f")
				vv.txt = format("(%s) %s: (%.2f sec) - %.2f avg", tostring(dur), data[id].name, latency, perc)
			end
		end
	end
	count = 0


end, "RotLatency", "Cooldown.End"})

function draw()
	for k, v in pairs(texts) do
		v:SetText("")
	end
	local count = 1
	for i, v in pairs(data) do
		local text = texts[count]
		text:SetText(v.txt or v.name)
		text:ResizeToText()
		local w = text:GetWidth()
		local h = text:GetHeight()
		if w > width then 
			width = w 
		end
		if h > height then
			height = w
		end
		count = count + 1
	end
	frame:SetWidth(width)
	frame:SetHeight(height * (count + 1))

end


table.insert(Event.System.Update.Begin, {draw, "RotLatency", "refresh"})
