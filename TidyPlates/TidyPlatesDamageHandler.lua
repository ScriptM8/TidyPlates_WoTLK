local addonName, TidyPlates = ...
local DamageDisplay = TidyPlates.DamageDisplay

local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

-- Handler using indices derived from user logs and MSBT analysis
frame:SetScript("OnEvent", function(_, event, ...)
    -- Exit if feature disabled
    if not TidyPlatesOptions or not TidyPlatesOptions.ShowDamageText then return end

    -- Capture args and get basic info (Indices adjusted based on user logs/analysis)
    local arg = { ... }
    local eventType  = arg[2]
    local sourceGUID = arg[3] -- Index 3 based on user logs
    local destGUID   = arg[6] -- Index 6 based on user logs

    -- Only process events originating from the player
    if sourceGUID ~= UnitGUID("player") then return end

    -- Declare variables
    local spellID, spellName, amount, missType, isCrit

    -- === Damage Events ===
    if eventType == "SPELL_DAMAGE" or eventType == "SPELL_PERIODIC_DAMAGE" or eventType == "RANGE_DAMAGE" then
        -- Indices based on user logs for ID/Name/Amount, and MSBT for Crit flag
        spellID   = arg[9]
        spellName = arg[10]
        amount    = arg[12]
        -- Check index 18 (used by MSBT) for crit flag (value is 1 if crit, nil otherwise)
        isCrit    = (arg[18] == 1)

		-- Uncomment the line below for debugging specific spell/range events
		-- DEFAULT_CHAT_FRAME:AddMessage(string.format("%s: Amt=%s CritFlag(18)=%s Crit=%s", eventType, amount, tostring(arg[18]), tostring(isCrit)))
		DamageDisplay:Show(destGUID, amount, spellID, isCrit)

    elseif eventType == "SWING_DAMAGE" then
        -- Use index 9 for Amount (common, aligns with MSBT), index 15 for Crit (MSBT, user comment)
        amount = arg[9]
        -- Check index 15 (used by MSBT and user comment) for crit flag
        isCrit = (arg[15] == 1)

		-- Uncomment the line below for debugging swing events
		-- DEFAULT_CHAT_FRAME:AddMessage(string.format("SWING_DAMAGE: Amt=%s CritFlag(15)=%s Crit=%s", amount, tostring(arg[15]), tostring(isCrit)))
		DamageDisplay:Show(destGUID, amount, nil, isCrit) -- No spellID for swings

    -- === Miss Events === (Using plausible standard indices, check if accurate on your server)
    elseif eventType == "SPELL_MISSED" or
           eventType == "SPELL_PERIODIC_MISSED" or
           eventType == "RANGE_MISSED" then
        spellID   = arg[9]  -- Plausible index
        spellName = arg[10] -- Plausible index
        missType  = arg[12] -- Plausible index for spell/range miss type
        DamageDisplay:ShowMiss(destGUID, missType, spellID)

    elseif eventType == "SWING_MISSED" then
        missType = arg[9] -- Plausible index for swing miss type
        DamageDisplay:ShowMiss(destGUID, missType, nil)

    -- === Environmental Damage === (Using plausible standard indices)
    elseif eventType == "ENVIRONMENTAL_DAMAGE" then
        local envType = arg[9]    -- Plausible index
        local envAmount = arg[10] -- Plausible index
        -- Show damage if amount exists and is greater than 0
		DamageDisplay:Show(destGUID, envAmount, nil) -- No crit/spellID usually
    end
end)

-- Optional: Add a confirmation message that this version loaded
-- DEFAULT_CHAT_FRAME:AddMessage("TidyPlates Damage Handler Updated (Hybrid Indices)")
