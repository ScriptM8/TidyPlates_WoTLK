local addonName, TidyPlates = ...
local DamageDisplay = TidyPlates.DamageDisplay

local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

frame:SetScript("OnEvent", function(_, event, ...)
	if not TidyPlatesOptions or not TidyPlatesOptions.ShowDamageText then return end

	local arg = { ... }
	local eventType, sourceGUID, destGUID = arg[2], arg[3], arg[6]

	if sourceGUID ~= UnitGUID("player") then return end

	local spellID, spellName, amount, missType

	if eventType == "SPELL_DAMAGE" or eventType == "SPELL_PERIODIC_DAMAGE" then
		spellID, spellName, amount = arg[9], arg[10], arg[12]
		DamageDisplay:Show(destGUID, amount, spellID)

	elseif eventType == "SWING_DAMAGE" then
		amount = arg[9]
		DamageDisplay:Show(destGUID, amount, nil)

	elseif eventType == "RANGE_DAMAGE" then
		spellID, spellName, amount = arg[9], arg[10], arg[12]
		DamageDisplay:Show(destGUID, amount, spellID)

	elseif eventType == "SPELL_MISSED" or eventType == "SPELL_PERIODIC_MISSED" or eventType == "RANGE_MISSED" then
		spellID, spellName, missType = arg[9], arg[10], arg[12]
		DamageDisplay:ShowMiss(destGUID, missType, spellID)

	elseif eventType == "SWING_MISSED" then
		missType = arg[9]
		DamageDisplay:ShowMiss(destGUID, missType, nil)
	end
end)
