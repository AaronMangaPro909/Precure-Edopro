-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

function s.initial_effect(c)
    -- Activate: Continuous Spell
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)

    -- 1. Normal Summon or Set without tributes (Unlimited)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_DECREASE_TRIBUTE)
    e2:SetRange(LOCATION_SZONE)
    e2:SetTargetRange(LOCATION_HAND, 0)
    e2:SetValue(0x1a000f) -- Removes all tributes required for Normal Summon / Set
    c:RegisterEffect(e2)

    -- 2. Unlimited Normal Summons/Sets per turn
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
    e3:SetRange(LOCATION_SZONE)
    e3:SetTargetRange(LOCATION_HAND + LOCATION_MZONE, 0)
    c:RegisterEffect(e3)
    
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_EXTRA_SET_COUNT)
    e4:SetRange(LOCATION_SZONE)
    e4:SetTargetRange(LOCATION_HAND, 0)
    c:RegisterEffect(e4)

    -- 3. End Phase Trigger: Place 1 Counter on opponent's End Phase
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 0))
    e5:SetCategory(CATEGORY_COUNTER)
    e5:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    e5:SetCode(EVENT_PHASE + PHASE_END)
    e5:SetRange(LOCATION_SZONE)
    e5:SetCountLimit(1)
    e5:SetCondition(function(e, tp) return Duel.GetTurnPlayer() ~= tp end)
    e5:SetOperation(s.ctrop)
    c:RegisterEffect(e5)
end

-------------------------------------------------------------------------
-- COUNTER ENGINE
-------------------------------------------------------------------------
function s.ctrop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        c:AddCounter(0x1, 1) -- Standard generic counter ID (0x1)
        if c:GetCounter(0x1) >= 10 then
            Duel.Destroy(c, REASON_EFFECT)
        end
    end
end
