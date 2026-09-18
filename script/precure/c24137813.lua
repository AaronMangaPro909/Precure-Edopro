-- Cure Spicy Party Up Style
local s, id = GetID()
local CARD_CURE_SPICY = 66272315 

function s.initial_effect(c)
    c:EnableReviveLimit()
    Synchro.AddProcedure(c, aux.FilterBoolFunction(Card.IsCode, CARD_CURE_SPICY), 1, 1, Synchro.NonTuner(nil), 1, 1)

     local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_MZONE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DELAY)
    e1:SetCondition(function(e, tp, eg, ep, ev, re, r, rp) return re:IsActiveType(TYPE_MONSTER) end)
    e1:SetTarget(s.locktg)
    e1:SetOperation(s.lockop)
    e1:SetCountLimit(1)
    c:RegisterEffect(e1)

    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_EQUIP)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetHintTiming(0, TIMING_BATTLE_PHASE)
    e2:SetCountLimit(1)
    e2:SetCondition(function() return Duel.GetCurrentPhase() >= PHASE_BATTLE_START and Duel.GetCurrentPhase() <= PHASE_BATTLE end)
    e2:SetTarget(s.eqtg)
    e2:SetOperation(s.eqop)
    c:RegisterEffect(e2)

    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_REMOVE)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e3:SetCode(EVENT_DESTROYED)
    e3:SetTarget(s.rmtg)
    e3:SetOperation(s.rmop)
    c:RegisterEffect(e3)
end

function s.locktg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) end
    if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    local g = Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, 2, nil)
end
function s.lockop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetTargetCards(e)
    for tc in aux.Next(g) do
        if tc:IsRelateToEffect(e) and tc:IsFaceup() then
            -- Negate effects
            local e1 = Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_DISABLE)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e1)
            local e2 = Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_DISABLE_EFFECT)
            e2:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e2)
            -- Cannot attack
            local e3 = Effect.CreateEffect(c)
            e3:SetType(EFFECT_TYPE_SINGLE)
            e3:SetCode(EFFECT_CANNOT_ATTACK)
            e3:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e3)
        end
    end
end

function s.eqfilter(c, tp)
    return c:IsType(TYPE_MONSTER) and not c:IsType(TYPE_TUNER)
end
function s.eqtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.eqfilter(chkc) end
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0 
        and Duel.IsExistingTarget(s.eqfilter, tp, LOCATION_GRAVE, 0, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_EQUIP)
    local g = Duel.SelectTarget(tp, s.eqfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, g, 1, 0, 0)
end
function s.eqop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and c:IsFaceup() and tc:IsRelateToEffect(e) then
        if Duel.Equip(tp, tc, c, true) then
            local e1 = Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_EQUIP_LIMIT)
            e1:SetValue(function(e, c) return e:GetOwner() == c end)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e1)
            -- Gain 1000 ATK
            local e2 = Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_EQUIP)
            e2:SetCode(EFFECT_UPDATE_ATTACK)
            e2:SetValue(1000)
            e2:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e2)
        end
    end
end

function s.rmtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) end
    if chk == 0 then return e:GetHandler():IsAbleToRemove() 
        and Duel.IsExistingTarget(Card.IsAbleToRemove, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
    local g = Duel.SelectTarget(tp, Card.IsAbleToRemove, tp, 0, LOCATION_MZONE, 1, 1, nil)
    g:AddCard(e:GetHandler())
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, 2, 0, 0)
end
function s.rmop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    local g = Group.FromCards(c, tc)
    if #g == 2 and Duel.Remove(g, POS_FACEUP, REASON_EFFECT) ~= 0 then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
        e1:SetCode(EVENT_PHASE + PHASE_END)
        e1:SetCountLimit(1)
        e1:SetLabel(Duel.GetTurnCount())
        e1:SetLabelObject(c)
        e1:SetCondition(s.retcon)
        e1:SetOperation(s.retop)
        e1:SetReset(RESET_PHASE + PHASE_END, 10) -- Tracks over 5 turns
        Duel.RegisterEffect(e1, tp)
    end
end
function s.retcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetLabelObject()
    return Duel.GetTurnCount() ~= e:GetLabel() and Duel.GetTurnCount() % 2 == 0
end
function s.retop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetLabelObject()
    Duel.SendtoDeck(c, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
    e:Reset()
end
