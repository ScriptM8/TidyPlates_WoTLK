-- File: TidyPlatesDamageDisplay.lua (WoTLK-Compatible)
local addonName, TidyPlates = ...
local DamageDisplay = {}

local DAMAGE_FADE_DURATION = 1.0
local MAX_DAMAGE_STACK_TIME = 0.3
local MAX_DAMAGE_TEXTS = 5

local meleeTexture = "Interface\\Icons\\Ability_MeleeDamage"

local function CreateDamageWidget(parent)
    local widget = CreateFrame("Frame", nil, parent)
    widget:SetSize(1, 1)
    widget:SetPoint("CENTER", parent, "CENTER", 0, 30) -- Directly above plate
    widget.texts = {}
    widget.icon = nil
    widget:Show()
    return widget
end

local function CreateDamageText(parent)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    text:SetTextColor(1, 0.9, 0, 1) -- Bright yellow
    text:SetPoint("CENTER", parent, "CENTER", 0, 0)

    local ag = text:CreateAnimationGroup()
    local fade = ag:CreateAnimation("Alpha")
    fade:SetChange(-1) -- WoTLK-compatible
    fade:SetDuration(DAMAGE_FADE_DURATION)
    fade:SetSmoothing("OUT")
    ag:SetScript("OnFinished", function() text:Hide() end)
    text.anim = ag
    return text
end

local function CreateDamageIcon(parent)
    local icon = parent:CreateTexture(nil, "OVERLAY")
    icon:SetSize(20, 20)
    icon:SetPoint("RIGHT", parent, "LEFT", -2, 0)

    local ag = icon:CreateAnimationGroup()
    local fade = ag:CreateAnimation("Alpha")
    fade:SetChange(-1) -- WoTLK-compatible
    fade:SetDuration(DAMAGE_FADE_DURATION)
    fade:SetSmoothing("OUT")
    ag:SetScript("OnFinished", function() icon:Hide() end)
    icon.anim = ag
    return icon
end

local function PushDamageText(widget, amount, spellID)
    local now = GetTime()

    -- Stack recent hits
    local last = widget.texts[#widget.texts]
    if last and now - last.time <= MAX_DAMAGE_STACK_TIME then
        last.amount = last.amount + amount
        last.text:SetText(last.amount)
        if last.text.anim:IsPlaying() then last.text.anim:Stop() end
        last.text:SetAlpha(1)
        last.text.anim:Play()
        return
    end

    if #widget.texts >= MAX_DAMAGE_TEXTS then
        local removed = table.remove(widget.texts, 1)
        removed.text:Hide()
    end

    local text = CreateDamageText(widget)
    text:SetText(amount)
    text:SetAlpha(1)
    text:Show()
    text.anim:Play()

    local icon = widget.icon or CreateDamageIcon(widget)
    local texture = spellID and select(3, GetSpellInfo(spellID)) or meleeTexture
    icon:SetTexture(texture)
    icon:SetAlpha(1)
    icon:Show()
    icon.anim:Play()

    widget.icon = icon
    table.insert(widget.texts, { text = text, amount = amount, time = now })
end

function DamageDisplay:Show(guid, amount, spellID)
    local plate = TidyPlates.NameplatesByGUID[guid]
    DEFAULT_CHAT_FRAME:AddMessage(string.format("🛡️ Plate found: %s", plate and "Yes" or "No"))

    if not plate or not plate.extended then
        DEFAULT_CHAT_FRAME:AddMessage("❌ No plate or no extended frame.")
        return
    end

    local extended = plate.extended
    if not extended.DamageWidget then
        extended.DamageWidget = CreateDamageWidget(extended)
        DEFAULT_CHAT_FRAME:AddMessage("🆕 Created DamageWidget")
    end

    PushDamageText(extended.DamageWidget, amount, spellID)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("💥 Pushed dmg text: %s", amount))
end

function DamageDisplay:Cleanup()
    for plate in pairs(TidyPlates.NameplatesByVisible) do
        local widget = plate.extended and plate.extended.DamageWidget
        if widget then
            for _, entry in ipairs(widget.texts) do
                if entry.text.anim:IsPlaying() then entry.text.anim:Stop() end
                entry.text:Hide()
            end
            if widget.icon and widget.icon.anim:IsPlaying() then
                widget.icon.anim:Stop()
            end
            if widget.icon then widget.icon:Hide() end
            widget.texts = {}
        end
    end
end

TidyPlates.DamageDisplay = DamageDisplay
