local addonName, TidyPlates = ...
local DamageDisplay = TidyPlates.DamageDisplay

local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", function(_, event, ...)
	if not TidyPlatesOptions or not TidyPlatesOptions.ShowDamageText then return end

	local arg = { ... }
	local eventType, sourceGUID, destGUID = arg[2], arg[3], arg[6]

	if sourceGUID ~= UnitGUID("player") then return end

	if eventType == "SPELL_DAMAGE" then
		local spellID, spellName, amount = arg[9], arg[10], arg[12]

		DEFAULT_CHAT_FRAME:AddMessage(string.format("✨ SPELL_DAMAGE: %s dmg (spell: %s)", amount, spellName))
		DamageDisplay:Show(destGUID, amount or 0, spellID)
	elseif eventType == "SWING_DAMAGE" then
		local amount = arg[9]

		DEFAULT_CHAT_FRAME:AddMessage(string.format("⚔️ SWING_DAMAGE: %s dmg", amount))
		DamageDisplay:Show(destGUID, amount or 0, 0)
	end
end)