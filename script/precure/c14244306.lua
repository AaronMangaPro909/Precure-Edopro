-- Precure Stage Ribbon
local s, id = GetID()

function s.initial_effect(c)

    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1, id, EFFECT_COUNT_LIMIT_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetRange(LOCATION_FZONE)
    e2:SetTargetRange(LOCATION_MZONE, 0)
    e2:SetTarget(aux.TargetBoolFunction(Card.IsSetCard, 0xb54))
    e2:SetValue(s.val)
    c:RegisterEffect(e2)
    local e3 = e2:Clone()
    e3:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e3)
    
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 1))
    e4:SetCategory(CATEGORY_ATKCHANGE)
    e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_DAMAGE_CALCULATING)
    e4:SetRange(LOCATION_FZONE)
    e4:SetCountLimit(1, id + 100)
    e4:SetCondition(s.atkcon)
    e4:SetOperation(s.atkop)
    c:RegisterEffect(e4)

    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 2))
    e5:SetCategory(CATEGORY_REMOVE)
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetRange(LOCATION_FZONE)
    e5:SetCountLimit(1, id + 200)
    e5:SetCondition(s.remcon)
    e5:SetTarget(s.remtg)
    e5:SetOperation(s.remop)
    c:RegisterEffect(e5)
end

function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetPossibleOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end
function s.activate(e, tp, eg, ep, ev, re, r, rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local g = Duel.GetMatchingGroup(s.thfilter, tp, LOCATION_DECK, 0, nil)
    if #g > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 0)) then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
        local sg = g:Select(tp, 1, 1, nil)
        Duel.SendtoHand(sg, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, sg)
    end
end

function s.valfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xb54)
end
function s.val(e, c)
    local tp = e:GetHandlerPlayer()
    local g = Duel.GetMatchingGroup(s.valfilter, tp, LOCATION_ONFIELD, 0, nil)
    return g:GetClassCount(Card.GetCode) * 500
end

function s.atkcon(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetBattleMonster(tp)
    return tc and tc:IsFaceup() and tc:IsSetCard(0xb54)
end
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local tc = Duel.GetBattleMonster(tp)
    if tc and tc:IsRelateToBattle() and tc:IsFaceup() then
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_SET_ATTACK_FINAL)
        e1:SetValue(tc:GetCurrentAttack() * 2)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
    end
end

function s.remcon(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, LOCATION_MZONE, 0, nil)
    local precure_g = g:Filter(Card.IsSetCard, nil, 0xb54)
    return precure_g:GetClassCount(Card.GetCode) >= 5
end
function s.remfilter(c)
    return c:IsAbleToRemove()
end
function s.remtg(e, tp, eg, ep, ev, re, r, rp, chk)
    local g = Duel.GetMatchingGroup(s.remfilter, tp, 0, LOCATION_ONFIELD, nil)
    if chk == 0 then return #g > 0 end
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, #g, 0, 0)
end
function s.remop(e, tp, eg, ep, ev, re, r, rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local g = Duel.GetMatchingGroup(s.remfilter, tp, 0, LOCATION_ONFIELD, nil)
    if #g > 0 then
        Duel.Remove(g, POS_FACEUP, REASON_EFFECT)
    end
end
