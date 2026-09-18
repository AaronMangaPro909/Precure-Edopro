local s, id = GetID()

local CARD_MERORON = 5826302
local CARD_RIBBON  = 78010496 -- Black & White Precure Ribbon's ID

function s.initial_effect(c)
    c:EnableReviveLimit()
    
    -- Must be Special Summoned by Ribbon (Fixed)
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(s.splimit)
    c:RegisterEffect(e0)
    
    -- Name/Race Treatment Rules
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_ADD_CODE)
    e1:SetValue(CARD_MERORON)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EFFECT_ADD_RACE)
    e2:SetValue(RACE_FAIRY)
    c:RegisterEffect(e2)
    
    -- Continuous Stat Buff
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTargetRange(LOCATION_MZONE, 0)
    e3:SetValue(500)
    c:RegisterEffect(e3)
    local e4 = e3:Clone()
    e4:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e4)
    
    -- Defense Position Attacking Rules
    local e5 = Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_DEFENSE_ATTACK)
    e5:SetValue(1)
    c:RegisterEffect(e5)
end

-- Validates that the summoning effect belongs to the Ribbon card
function s.splimit(e, se, sp, st)
    return se and se:GetHandler():IsCode(CARD_RIBBON)
end
