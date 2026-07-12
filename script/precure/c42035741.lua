-- ultimate neos
local s, id = GetID()

local CARD_NEOS      = 89943723
local CARD_SKY       = 14757249
local CARD_PRISM     = 16635445
local CARD_BUTTERFLY = 17472956
local CARD_WING      = 30633157
local CARD_MAJESTY   = 90753989

function s.initial_effect(c)
    c:EnableReviveLimit()
    Fusion.AddProcMixN(c, true, true, 
        aux.FilterBoolFunction(Card.IsCode, CARD_NEOS), 1,
        aux.FilterBoolFunction(Card.IsCode, CARD_SKY), 1,
        aux.FilterBoolFunction(Card.IsCode, CARD_PRISM), 1,
        aux.FilterBoolFunction(Card.IsCode, CARD_BUTTERFLY), 1,
        aux.FilterBoolFunction(Card.IsCode, CARD_WING), 1,
        aux.FilterBoolFunction(Card.IsCode, CARD_MAJESTY), 1)

    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) end)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)

    local e2 = Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_ATKCHANGE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetCost(s.atkcost)
    e2:SetOperation(s.atkop)
    c:RegisterEffect(e2)

    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_DAMAGE_STEP_END)
    e3:SetCondition(function(e) return e:GetHandler() == Duel.GetAttacker() end)
    e3:SetOperation(function(e, tp) Duel.Damage(1 - tp, 500, REASON_EFFECT) end)
    c:RegisterEffect(e3)

    local e4 = Effect.CreateEffect(c)
    e4:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetCondition(function(e, tp, eg, ep, ev, re, r, rp) return rp ~= tp and Duel.IsChainNegatable(ev) end)
    e4:SetCost(function(e, tp, eg, ep, ev, re, r, rp, chk)
        if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, nil) end
        Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST + REASON_DISCARD)
    end)
    e4:SetTarget(function(e, tp, eg, ep, ev, re, r, rp, chk)
        if chk == 0 then return true end
        Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
        if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
            Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
        end
    end)
    e4:SetOperation(function(e, tp, eg, ep, ev, re, r, rp)
        if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
            Duel.Destroy(eg, REASON_EFFECT)
        end
    end)
    c:RegisterEffect(e4)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1 - tp) end
    if chk == 0 then return Duel.IsExistingTarget(Card.IsDestructable, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectTarget(tp, Card.IsDestructable, tp, 0, LOCATION_MZONE, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then Duel.Destroy(tc, REASON_EFFECT) end
end

function s.costfilter(c)
    return (c:IsSetCard(0x3008) or c:IsSetCard(0xb54)) and c:IsAbleToRemoveAsCost()
end
function s.atkcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_GRAVE, 0, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
    local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil)
    Duel.Remove(g, POS_FACEUP, REASON_COST)
end
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(1000)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        c:RegisterEffect(e1)
    end
end
