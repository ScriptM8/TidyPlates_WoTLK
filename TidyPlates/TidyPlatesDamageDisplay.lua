-- File: TidyPlatesDamageDisplay.lua
local addonName, TidyPlates = ...
local DamageDisplay = {}

local DAMAGE_FADE_DURATION = 1.5
local DAMAGE_FLOAT_DISTANCE = 40
local MAX_DAMAGE_STACK_TIME = 0.5
local MAX_DAMAGE_TEXTS = 5
local meleeTexture = "Interface\\Icons\\Ability_MeleeDamage"

local function CreateDamageWidget(parent)
	local widget = CreateFrame("Frame", nil, parent)
	widget:SetSize(1, 1)
	widget:SetPoint("CENTER", parent, "CENTER", 0, 0)
	widget.texts = {}
	return widget
end

local function CreateDamageText(parent, amount, texture)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetSize(60, 20)
	frame:SetPoint("BOTTOM", parent, "TOP", 0, 10)  -- fixed initial offset above plate

	local icon = frame:CreateTexture(nil, "OVERLAY")
	icon:SetSize(16, 16)
	icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
	icon:SetTexture(texture or meleeTexture)
	frame.icon = icon

	local text = frame:CreateFontString(nil, "OVERLAY")
	text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	text:SetTextColor(1, 0.9, 0, 1)
	text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
	text:SetText(amount)
	frame.text = text

	frame:SetAlpha(1)
	frame:Show()

	local elapsed = 0
	local duration = DAMAGE_FADE_DURATION
	local floatDist = DAMAGE_FLOAT_DISTANCE

	frame:SetScript("OnUpdate", function(self, dt)
		elapsed = elapsed + dt
		if elapsed >= duration then
			self:SetScript("OnUpdate", nil)
			self:Hide()
			return
		end

		local offset = (elapsed / duration) * floatDist
		self:SetPoint("BOTTOM", parent, "TOP", 0, 10 + offset)

		self:SetAlpha(1 - (elapsed / duration))
	end)

	return frame
end

local function PushDamageText(widget, amount, spellID)
	local now = GetTime()

	-- Combine recent hits
	local last = widget.texts[#widget.texts]
	if last and now - last.time <= MAX_DAMAGE_STACK_TIME then
		last.amount = last.amount + amount
		last.frame.text:SetText(last.amount)
		last.time = now -- refresh timer
		return
	end

	if #widget.texts >= MAX_DAMAGE_TEXTS then
		local old = table.remove(widget.texts, 1)
		old.frame:SetScript("OnUpdate", nil)
		old.frame:Hide()
	end

	-- New hits always appear at the same position
	local texture = spellID and select(3, GetSpellInfo(spellID)) or meleeTexture
	local frame = CreateDamageText(widget, amount, texture)

	table.insert(widget.texts, { frame = frame, amount = amount, time = now })
end

function DamageDisplay:Show(guid, amount, spellID)
	local plate = TidyPlates.NameplatesByGUID[guid]
	if not plate or not plate.extended then return end
	local extended = plate.extended

	if not extended.DamageWidget then
		extended.DamageWidget = CreateDamageWidget(extended)
	end

	PushDamageText(extended.DamageWidget, amount, spellID)
end

function DamageDisplay:Cleanup()
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
end

TidyPlates.DamageDisplay = DamageDisplay
