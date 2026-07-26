-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

local CARD_CURE_IDOL   = 39517403
local CARD_CRITIAS     = 85800949
local CARD_TIMAEUS     = 80019195
local CARD_HERMOS      = 84565800
local CARD_DESTINY     = 53315891

local CARD_CURE_WINK     = 21287436
local CARD_CURE_KYUN     = 26805130
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833

function s.initial_effect(c)
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_ADD_CODE)
    e0:SetValue(CARD_DESTINY)
    c:RegisterEffect(e0)

    c:EnableReviveLimit()
    Fusion.AddProcMix(c, true, true, CARD_CURE_IDOL, CARD_CRITIAS, CARD_TIMAEUS, CARD_HERMOS)

    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCondition(s.altcon)
    e1:SetOperation(s.altop)
    c:RegisterEffect(e1)

    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetRange(LOCATION_MZONE)
    e3:SetValue(s.atkval)
    c:RegisterEffect(e3)

    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_PIERCE)
    c:RegisterEffect(e4)
    local e5 = Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_PRE_BATTLE_DAMAGE)
    e5:SetCondition(s.damcon)
    e5:SetOperation(s.damop)
    c:RegisterEffect(e5)

    local e6 = Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id, 1))
    e6:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e6:SetType(EFFECT_TYPE_QUICK_O)
    e6:SetCode(EVENT_CHAINING)
    e6:SetRange(LOCATION_MZONE)
    e6:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e6:SetCondition(function(e, tp, eg, ep, ev, re, r, rp) return rp ~= tp and Duel.IsChainNegatable(ev) end)
    e6:SetTarget(s.negtg)
    e6:SetOperation(s.negop)
    c:RegisterEffect(e6)
end

function s.matfilter(c)
    return c:IsFaceup() and (c:IsCode(CARD_CURE_IDOL) or c:IsCode(CARD_CRITIAS) or c:IsCode(CARD_TIMAEUS) or c:IsCode(CARD_HERMOS)) and c:IsAbleToGraveAsCost()
end
function s.altcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > -1
        and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, CARD_CURE_IDOL), tp, LOCATION_MZONE, 0, 1, nil)
        and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, CARD_CRITIAS), tp, LOCATION_MZONE, 0, 1, nil)
        and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, CARD_TIMAEUS), tp, LOCATION_MZONE, 0, 1, nil)
        and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, CARD_HERMOS), tp, LOCATION_MZONE, 0, 1, nil)
end
function s.altop(e, tp, eg, ep, ev, re, r, rp, c)
    local g1 = Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsCode, CARD_CURE_IDOL), tp, LOCATION_MZONE, 0, nil)
    local g2 = Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsCode, CARD_CRITIAS), tp, LOCATION_MZONE, 0, nil)
    local g3 = Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsCode, CARD_TIMAEUS), tp, LOCATION_MZONE, 0, nil)
    local g4 = Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsCode, CARD_HERMOS), tp, LOCATION_MZONE, 0, nil)
    g1:Merge(g2)
    g1:Merge(g3)
    g1:Merge(g4)
    Duel.SendtoGrave(g1, REASON_COST)
end

function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    local rc = re and re:GetHandler()
    return rc and (rc:IsCode(CARD_CURE_WINK) or rc:IsCode(CARD_CURE_KYUN) or rc:IsCode(CARD_CURE_ZUKYOON) or rc:IsCode(CARD_CURE_KISS))
end
function s.thfilter(c)
    return c:IsType(TYPE_FIELD) and c:IsSetCard(0xb54) and c:IsAbleToHand() -- Assumes Field Spell has Precure archetype
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end

function s.atkfilter(c)
    return c:IsFaceup() and (c:IsSetCard(0xb54) or c:IsRace(RACE_WARRIOR))
end
function s.atkval(e, c)
    return Duel.GetMatchingGroupCount(s.atkfilter, e:GetHandlerPlayer(), LOCATION_GRAVE, 0, nil) * 500
end

function s.damcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local target = Duel.GetAttackTarget()
    return c == Duel.GetAttacker() and target and target:IsDefensePos() and target:IsControler(1 - tp)
end
function s.damop(e, tp, eg, ep, ev, re, r, rp)
    Duel.ChangeBattleDamage(1 - tp, ev * 2)
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
