-- File: TidyPlatesDamageDisplay.lua
local addonName, TidyPlates = ...
local DamageDisplay = {}

local DAMAGE_FADE_DURATION = 1.5
local DAMAGE_FLOAT_DISTANCE = 40
local MAX_DAMAGE_TEXTS = 7
local meleeTexture = "Interface\\Icons\\Ability_MeleeDamage"

local MISS_COLORS = {
	["MISS"] = { 0.8, 0.8, 0.8 },
	["DODGE"] = { 0.5, 0.7, 1 },
	["PARRY"] = { 1, 0.5, 0 },
	["ABSORB"] = { 0.7, 0.7, 1 },
	["IMMUNE"] = { 1, 1, 0 },
	["BLOCK"] = { 0.6, 0.4, 0 },
	["RESIST"] = { 1, 0.3, 0.3 },
}

-- Timer system for delayed actions
local timers = {}
local timerFrame = CreateFrame("Frame")
timerFrame:SetScript("OnUpdate", function(frame, elapsed)
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

-- Use DEFAULT_CHAT_FRAME:AddMessage for in-game debug messages
local function DebugMessage(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	end
end

DamageDisplay.DetachedTexts = {}

local function DetachedAnimation(self, dt)
    self._anim_elapsed = self._anim_elapsed + dt
    if self._anim_elapsed >= self._anim_duration then
        self:SetScript("OnUpdate", nil)
        self:Hide()
        return
    end
    local progress = self._anim_elapsed / self._anim_duration
    local dx = math.cos(self._anim_angle) * self._anim_baseRadius * progress
    local dy = math.sin(self._anim_angle) * self._anim_baseRadius * progress + progress * self._anim_floatDistance
    -- Use the stored base coordinates (set at detachment) as the starting point.
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", self._detachBaseX + dx, self._detachBaseY + dy)
    self:SetAlpha(1 - progress)
end

local function DetachDamageText(frame)
    if not frame then
        DEFAULT_CHAT_FRAME:AddMessage("DetachDamageText: frame is nil!")
        return
    end

    local x, y = frame:GetCenter()
    if not (x and y) then
        DEFAULT_CHAT_FRAME:AddMessage("DetachDamageText: Invalid center coordinates")
        return
    end

    local scale = UIParent:GetEffectiveScale()
    local newX = x / scale
    local newY = y / scale

    frame:ClearAllPoints()
    frame:SetParent(UIParent)
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", newX, newY)
    frame:Show()
    frame:SetAlpha(1)
    -- Store these absolute coordinates as the new base for the detached animation.
    frame._detachBaseX = newX
    frame._detachBaseY = newY

    -- Switch to the detached animation function.
    frame:SetScript("OnUpdate", DetachedAnimation)
end

DamageDisplay.DetachDamageText = DetachDamageText

local function CreateDamageText(parent, textValue, texture, color, isCrit)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(80, 20)

    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", frame, "LEFT")
    icon:SetTexture(texture or meleeTexture)

    local text = frame:CreateFontString(nil, "OVERLAY")
    local fontSize = 13
    if isCrit then
        fontSize = 18  -- Larger font for crits
    end
    text:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    -- If no color is provided, use a different color for crits
    if not color then
        if isCrit then
            color = { 1, 0.2, 0.2 }  -- e.g. a red hue for crits
        else
            color = { 1, 0.9, 0 }
        end
    end
    text:SetTextColor(unpack(color))
    text:SetPoint("LEFT", icon, "RIGHT", 3, 0)
    text:SetText(textValue)

    -- Use a longer duration for crits (making them sticky)
    local duration = DAMAGE_FADE_DURATION
    if isCrit then
        duration = duration + 1.0  -- crit texts persist longer
    end
    local elapsed = 0
    local angle = spiralAngle
    spiralAngle = (spiralAngle + math.pi / 4) % (2 * math.pi)
    local baseRadius = 20

    -- Store animation parameters for later (useful for detachment)
    frame._anim_elapsed = elapsed
    frame._anim_duration = duration
    frame._anim_angle = angle
    frame._anim_baseRadius = baseRadius
    frame._anim_floatDistance = DAMAGE_FLOAT_DISTANCE
    frame._isCrit = isCrit

    frame:SetScript("OnUpdate", function(self, dt)
        self._anim_elapsed = self._anim_elapsed + dt
        if self._anim_elapsed >= self._anim_duration then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            return
        end
        local progress = self._anim_elapsed / self._anim_duration
        local dx = math.cos(self._anim_angle) * self._anim_baseRadius * progress
        local dy = math.sin(self._anim_angle) * self._anim_baseRadius * progress + progress * self._anim_floatDistance
        self:SetPoint("BOTTOM", self:GetParent(), "TOP", dx, 20 + dy)
        self:SetAlpha(1 - progress)
    end)

    frame:Show()
    return frame
end

local function PushDamageText(widget, amount, spellID, color, isCrit)
    if #widget.texts >= MAX_DAMAGE_TEXTS then
        local old = table.remove(widget.texts, 1)
        old.frame:SetScript("OnUpdate", nil)
        old.frame:Hide()
    end

    local texture = spellID and select(3, GetSpellInfo(spellID)) or meleeTexture
    local frame = CreateDamageText(widget, amount, texture, color, isCrit)
    table.insert(widget.texts, { frame = frame })
end


function DamageDisplay:Show(guid, amount, spellID, isCrit)
    local plate = TidyPlates.NameplatesByGUID[guid]
    if not plate or not plate.extended then return end

    local extended = plate.extended
    if not extended.DamageWidget then
        extended.DamageWidget = CreateDamageWidget(extended)
    end

    PushDamageText(extended.DamageWidget, tonumber(amount), spellID, nil, isCrit)
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

-- Expose for other modules
TidyPlates.After = After
TidyPlates.DamageDisplay = DamageDisplay
