-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- !! CHANGE THIS !! Replace 12345678 with the actual ID of "Cure Kyun-Kyun"
local CARD_CURE_KYUN_KYUN = 26805130

function s.initial_effect(c)
    -- Activate: Target 1 "Cure Kyun-Kyun" or "Precure" monster; it gains 2000 ATK
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_ATKCHANGE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DAMAGE_STEP)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(TIMING_DAMAGE_STEP, TIMING_DAMAGE_STEP + TIMINGS_CHECK_MONSTER)
    e1:SetCountLimit(1, id, EFFECT_COUNT_LIMIT_OATH) -- You can only activate 1 per turn
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-- Ensure it can be activated during the Damage Step safely (since it alters ATK)
function s.condition(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() ~= PHASE_DAMAGE or not Duel.IsDamageCalculated()
end

-- Filter for a face-up "Cure Kyun-Kyun" OR a "Precure" (0xb54) monster
function s.filter(c)
    return c:IsFaceup() and (c:IsCode(CARD_CURE_KYUN_KYUN) or c:IsSetCard(0xb54))
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.IsExistingTarget(s.filter, tp, LOCATION_MZONE, 0, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATKDEF)
    local g = Duel.SelectTarget(tp, s.filter, tp, LOCATION_MZONE, 0, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_ATKCHANGE, g, 1, 0, 0)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        -- Apply the 2000 ATK boost until the end of the turn
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(2000)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
    end
end
