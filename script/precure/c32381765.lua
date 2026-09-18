-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- !! CHANGE THIS !! Replace with Cure Kiss's actual 8-digit ID
local CARD_CURE_KISS = 60519833 

function s.initial_effect(c)
    -- Synchro Summon Procedure ("Cure Kiss" + 1+ non-Tuner)
    c:EnableReviveLimit()
    Synchro.AddProcedure(c, s.tfilter, 1, 1, Synchro.NonTuner(nil), 1, 99)
    
    -- 1. Main Phase: Gain 500 ATK until the End Phase
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_ATKCHANGE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTarget(s.atktg)
    e1:SetOperation(s.atkop)
    c:RegisterEffect(e1)
    
    -- 2. Double Attack
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_EXTRA_ATTACK)
    e2:SetValue(1)
    c:RegisterEffect(e2)
    
    -- 3. Quick Effect: Negate and destroy Spell/Trap
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.negcon)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)
end

-- Tuner filter logic to isolate Cure Kiss specifically
function s.tfilter(c, scard, sumtype, tp)
    return c:IsCode(CARD_CURE_KISS, scard, sumtype, tp) or c:IsHasEffect(EFFECT_ADD_CODE) and c:GetCardEffect(EFFECT_ADD_CODE):GetValue() == CARD_CURE_KISS
end

-- 1. ATK Gain Logic
function s.atktg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_ATKCHANGE, e:GetHandler(), 1, 0, 0)
end
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(500)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE + RESET_PHASE + PHASE_END)
        c:RegisterEffect(e1)
    end
end

-- 3. Spell/Trap Negation Logic
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev) and re:IsActiveType(TYPE_SPELL + TYPE_TRAP)
end
function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end
function s.negop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end
