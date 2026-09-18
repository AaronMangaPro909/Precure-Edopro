-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()
function s.initial_effect(c)
    Pendulum.AddProcedure(c, false)
    c:EnableReviveLimit()
    Fusion.AddProcMix(c, true, true, 42760112, 52303611)
    -- Pendulum
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetRange(LOCATION_PZONE)
    e1:SetTargetRange(LOCATION_PZONE, 0)
    e1:SetValue(1)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e2:SetRange(LOCATION_PZONE)
    e2:SetCountLimit(1)
    e2:SetCondition(s.pnegcon)
    e2:SetTarget(s.pnegtg)
    e2:SetOperation(s.pnegop)
    c:RegisterEffect(e2)
    --- Monster Effect
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_TOGRAVE)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCondition(s.tgcon)
    e3:SetTarget(s.tgtg)
    e3:SetOperation(s.tgop)
    c:RegisterEffect(e3)
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_UPDATE_ATTACK)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetValue(s.atkval)
    c:RegisterEffect(e4)
    local e5 = e4:Clone()
    e5:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e5)
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetCode(EFFECT_PIERCE)
    c:RegisterEffect(e6)
    local e7 = Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e7:SetCode(EVENT_PRE_BATTLE_DAMAGE)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCondition(s.damcon)
    e7:SetOperation(s.damop)
    c:RegisterEffect(e7)
    local e8 = Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id, 2))
    e8:SetType(EFFECT_TYPE_QUICK_O)
    e8:SetCode(EVENT_FREE_CHAIN)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCountLimit(1)
    e8:SetOperation(s.attop)
    c:RegisterEffect(e8)
    local e9 = Effect.CreateEffect(c)
    e9:SetDescription(aux.Stringid(id, 3))
    e9:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e9:SetType(EFFECT_TYPE_QUICK_O)
    e9:SetCode(EVENT_CHAINING)
    e9:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e9:SetRange(LOCATION_MZONE)
    e9:SetCountLimit(1)
    e9:SetCondition(s.negcon)
    e9:SetCost(s.negcost)
    e9:SetTarget(s.negtg)
    e9:SetOperation(s.negop)
    c:RegisterEffect(e9)
    local e10 = Effect.CreateEffect(c)
    e10:SetDescription(aux.Stringid(id, 4))
    e10:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e10:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e10:SetProperty(EFFECT_FLAG_DELAY)
    e10:SetCode(EVENT_DESTROYED)
    e10:SetCondition(s.pencon)
    e10:SetTarget(s.pentg)
    e10:SetOperation(s.penop)
    c:RegisterEffect(e10)
end

s.listed_names = {42760112, 52303611}
s.darkness_archetype = 0xb54 -- Precure Archetype

-- Pendulum
function s.pnegcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.GetTurnPlayer() ~= tp and Duel.IsChainNegatable(ev)
end

function s.pnegtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end

function s.pnegop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end

-- Monster Effect
function s.tgcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.tgfilter1(c)
    local code, subcode = c:GetCode()
    return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsSetCard(0xb54) and c:IsAbleToGrave()
end
function s.tgfilter2(c)
    local code, subcode = c:GetCode()
    return c:IsAttribute(ATTRIBUTE_DARK) and c:IsSetCard(0xb54) and c:IsAbleToGrave()
end
function s.tgtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsExistingMatchingCard(s.tgfilter1, tp, LOCATION_DECK, 0, 1, nil)
            and Duel.IsExistingMatchingCard(s.tgfilter2, tp, LOCATION_DECK, 0, 1, nil)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 2, tp, LOCATION_DECK)
end
function s.tgop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local g1 = Duel.SelectMatchingCard(tp, s.tgfilter1, tp, LOCATION_DECK, 0, 1, 1, nil)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local g2 = Duel.SelectMatchingCard(tp, s.tgfilter2, tp, LOCATION_DECK, 0, 1, 1, nil)
    if #g1 > 0 and #g2 > 0 then
        g1:Merge(g2)
        Duel.SendToGrave(g1, REASON_EFFECT)
    end
end
function s.atkfilter(c)
    return c:IsType(TYPE_MONSTER) and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK))
end

function s.atkval(e, c)
    return Duel.GetMatchingGroupCount(s.atkfilter, c:GetControler(), LOCATION_GRAVE, LOCATION_GRAVE, nil) * 1000
end

function s.damcon(e, tp, eg, ep, ev, re, r, rp)
    local eq = e:GetHandler()
    return Duel.GetAttacker() == eq and eq:IsControler(tp)
end

function s.damop(e, tp, eg, ep, ev, re, r, rp)
    Duel.ChangeBattleDamage(ep, ev * 2)
end
function s.attop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        local att = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 1))
        local chosen_att = (att == 0) and ATTRIBUTE_LIGHT or ATTRIBUTE_DARK
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CHANGE_ATTRIBUTE)
        e1:SetValue(chosen_att)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        c:RegisterEffect(e1)
    end
end
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
end

function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, nil) end
    Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST + REASON_DISCARD)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end
function s.pencon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return c:IsPreviousControler(tp) and c:IsReason(REASON_EFFECT) and rp ~= tp
end

function s.pentg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.CheckLocation(tp, LOCATION_PZONE, 0) or Duel.CheckLocation(tp, LOCATION_PZONE, 1) end
end

function s.penop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.MoveToField(c, tp, tp, LOCATION_PZONE, POS_FACEUP, true)
    end
end
