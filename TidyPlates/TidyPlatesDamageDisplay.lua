local addonName, TidyPlates = ...
local DamageDisplay = {}

local DAMAGE_FADE_DURATION = 1.5
local DAMAGE_FLOAT_DISTANCE = 40
local MAX_DAMAGE_TEXTS = 7
local meleeTexture = "Interface\\Icons\\Ability_MeleeDamage"

local MISS_COLORS = {
	["MISS"] = { 0.8, 0.8, 0.8 },   -- Gray
	["DODGE"] = { 0.5, 0.7, 1 },    -- Blueish
	["PARRY"] = { 1, 0.5, 0 },      -- Orange
	["ABSORB"] = { 0.7, 0.7, 1 },   -- Light Blue
	["IMMUNE"] = { 1, 1, 0 },       -- Yellow
	["BLOCK"] = { 0.6, 0.4, 0 },    -- Brown
	["RESIST"] = { 1, 0.3, 0.3 },   -- Reddish
}
-- Timer system for delayed actions
local timers = {}

local timerFrame = CreateFrame("Frame")
timerFrame:SetScript("OnUpdate", function(self, elapsed)
	for i = #timers, 1, -1 do
		local t = timers[i]
		t.delay = t.delay - elapsed
		if t.delay <= 0 then
			t.func(unpack(t.args))
			table.remove(timers, i)
		end
	end
end)

local function After(delay, func, ...)
	table.insert(timers, { delay = delay, func = func, args = { ... } })
end

local spiralAngle = 0

local function CreateDamageWidget(parent)
	local widget = CreateFrame("Frame", nil, parent)
	widget:SetSize(1, 1)
	widget:SetPoint("CENTER", parent, "CENTER")
	widget.texts = {}
	return widget
end

local function CreateDamageText(parent, textValue, texture, color)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetSize(80, 20)

	local icon = frame:CreateTexture(nil, "OVERLAY")
	icon:SetSize(14, 14)
	icon:SetPoint("LEFT", frame, "LEFT")
	icon:SetTexture(texture or meleeTexture)

	local text = frame:CreateFontString(nil, "OVERLAY")
	text:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
	text:SetTextColor(unpack(color or { 1, 0.9, 0 }))
	text:SetPoint("LEFT", icon, "RIGHT", 3, 0)
	text:SetText(textValue)

	local elapsed, duration = 0, DAMAGE_FADE_DURATION
	local angle = spiralAngle
	spiralAngle = (spiralAngle + math.pi / 4) % (2 * math.pi) -- increased angle steps for spacing
	local baseRadius = 20 -- wider spiral

	frame:SetScript("OnUpdate", function(self, dt)
		elapsed = elapsed + dt
		if elapsed >= duration then
			self:SetScript("OnUpdate", nil)
			self:Hide()
			return
		end

		local progress = elapsed / duration
		local dx = math.cos(angle) * baseRadius * progress
		local dy = math.sin(angle) * baseRadius * progress + progress * DAMAGE_FLOAT_DISTANCE

		frame:SetPoint("BOTTOM", parent, "TOP", dx, 20 + dy)
		frame:SetAlpha(1 - progress)
	end)

	return frame
end

local function PushDamageText(widget, amount, spellID, color)
	if #widget.texts >= MAX_DAMAGE_TEXTS then
		local old = table.remove(widget.texts, 1)
		old.frame:SetScript("OnUpdate", nil)
		old.frame:Hide()
	end

	local texture = spellID and select(3, GetSpellInfo(spellID)) or meleeTexture
	local frame = CreateDamageText(widget, amount, texture, color)
	table.insert(widget.texts, { frame = frame })
end

function DamageDisplay:Show(guid, amount, spellID)
	local plate = TidyPlates.NameplatesByGUID[guid]
	if not plate or not plate.extended then return end

	local extended = plate.extended
	if not extended.DamageWidget then
		extended.DamageWidget = CreateDamageWidget(extended)
	end

	PushDamageText(extended.DamageWidget, tonumber(amount), spellID)
end

function DamageDisplay:ShowMiss(guid, missType, spellID)
	local plate = TidyPlates.NameplatesByGUID[guid]
	if not plate or not plate.extended then return end

	local extended = plate.extended
	if not extended.DamageWidget then
		extended.DamageWidget = CreateDamageWidget(extended)
	end

	local color = MISS_COLORS[missType] or { 0.9, 0.9, 0.9 }
	PushDamageText(extended.DamageWidget, missType, spellID, color)
end

function DamageDisplay:Cleanup()
	After(1, function()
		for plate in pairs(TidyPlates.NameplatesByVisible) do
			if plate.extended and plate.extended.DamageWidget then
				local widget = plate.extended.DamageWidget
				for _, entry in ipairs(widget.texts) do
					entry.frame:SetScript("OnUpdate", nil)
					entry.frame:Hide()
				end
				widget.texts = {}
			end
		end
	end)
end


-- Expose to other modules
TidyPlates.After = After
TidyPlates.DamageDisplay = DamageDisplay
