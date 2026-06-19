--51286347

-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- !! CHANGE THIS !! Replace with Cure Idol's actual 8-digit ID
local CARD_CURE_IDOL = 39517403

function s.initial_effect(c)
    -- Activate: Target 1 "Cure Idol" monster; it gains ATK based on Spells in GY
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_ATKCHANGE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DAMAGE_STEP)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(TIMING_DAMAGE_STEP, TIMING_DAMAGE_STEP + TIMINGS_CHECK_MONSTER)
    e1:SetCountLimit(1, id, EFFECT_COUNT_LIMIT_OATH) -- Hard Once Per Turn
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-- Must be during the Battle Phase, and inside Damage Step it can only activate before Damage Calculation
function s.condition(e, tp, eg, ep, ev, re, r, rp)
    local phase = Duel.GetCurrentPhase()
    return (phase >= PHASE_BATTLE_START and phase <= PHASE_BATTLE)
        and (phase ~= PHASE_DAMAGE or not Duel.IsDamageCalculated())
end

-- Filter for a face-up "Cure Idol" monster
function s.tgfilter(c)
    return c:IsFaceup() and c:IsCode(CARD_CURE_IDOL)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingTarget(s.tgfilter, tp, LOCATION_MZONE, 0, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATKDEF)
    local g = Duel.SelectTarget(tp, s.tgfilter, tp, LOCATION_MZONE, 0, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_ATKCHANGE, g, 1, 0, 0)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        -- Count Spell Cards currently in your Graveyard
        local ct = Duel.GetMatchingGroupCount(Card.IsType, tp, LOCATION_GRAVE, 0, nil, TYPE_SPELL)
        if ct == 0 then return end
        
        -- Apply the ATK boost (1000 * number of Spells) until the End Phase
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(ct * 1000)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
    end
end
