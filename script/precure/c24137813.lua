-- Cure Spicy - Party Up Style
local s, id = GetID()

local CARD_CURE_SPICY = 66272315

function s.initial_effect(c)
    c:EnableReviveLimit()
    Synchro.AddProcedure(c, aux.FilterBoolFunction(Card.IsCode, CARD_CURE_SPICY), 1, 1, Synchro.NonTuner(nil), 1, 1)
    
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCondition(s.atkcon)
    e1:SetTarget(s.atktg)
    e1:SetOperation(s.atkop)
    c:RegisterEffect(e1)
  
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_EQUIP + CATEGORY_ATKCHANGE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(TIMING_BATTLE_PHASE)
    e2:SetCondition(s.eqcon)
    e2:SetCountLimit (1)
    e2:SetTarget(s.eqtg)
    e2:SetOperation(s.eqop)
    c:RegisterEffect(e2)
    
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_REMOVE)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_DESTROYED)
    e3:SetTarget(s.remtg)
    e3:SetOperation(s.remop)
    c:RegisterEffect(e3)
end

function s.atkcon(e, tp, eg, ep, ev, re, r, rp)
    return re:IsActiveType(TYPE_MONSTER)
end
function s.atktg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, 2, nil)
end
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetTargetCards(e)
    if #g == 0 or not c:IsRelateToEffect(e) or c:IsFacedown() then return end
    
    for tc in aux.Next(g) do
        if tc:IsFaceup() then
            local e1 = Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_CANNOT_ATTACK)
            e1:SetCondition(s.rcon)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e1)
        end
    end
end
function s.rcon(e)
    return e:GetOwner():IsFaceup() and e:GetOwner():IsLocation(LOCATION_MZONE)
end

function s.eqcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsBattlePhase()
end
function s.eqfilter(c, e)
    return c:IsType(TYPE_MONSTER) and not c:IsType(TYPE_TUNER) 
        and c:IsReason(REASON_SYNCHRO) and c:IsCanBeEffectTarget(e)
end
function s.eqtg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
        and Duel.IsExistingTarget(s.eqfilter, tp, LOCATION_GRAVE, 0, 1, nil, e) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_EQUIP)
    local g = Duel.SelectTarget(tp, s.eqfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e)
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, g, 1, 0, 0)
end
function s.eqop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 or c:IsFacedown() or not c:IsRelateToEffect(e) then return end
    
    if tc and tc:IsRelateToEffect(e) then
        if not Duel.Equip(tp, tc, c) then return end
        
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_EQUIP_LIMIT)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetValue(true)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e1)
        
        local e2 = Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_UPDATE_ATTACK)
        e2:SetValue(1000)
        e2:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE)
        c:RegisterEffect(e2)
    end
end

function s.remtg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.IsExistingTarget(Card.IsAbleToRemove, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
    local g = Duel.SelectTarget(tp, Card.IsAbleToRemove, tp, 0, LOCATION_MZONE, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, 1, 0, 0)
end
function s.remop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    
    local rg = Group.CreateGroup()
    if c:IsRelateToEffect(e) and c:IsAbleToRemove() then rg:AddCard(c) end
    if tc and tc:IsRelateToEffect(e) and tc:IsAbleToRemove() then rg:AddCard(tc) end
    
    if #rg > 0 and Duel.Remove(rg, POS_FACEUP, REASON_EFFECT) > 0 then
        if c:IsLocation(LOCATION_REMOVED) then
            local current_turn = Duel.GetTurnCount()
            local e1 = Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
            e1:SetCode(EVENT_PHASE + PHASE_END)
            e1:SetLabel(current_turn)
            e1:SetCondition(s.retcon)
            e1:SetOperation(s.retop)
            Duel.RegisterEffect(e1, tp)
        end
    end
end
function s.retcon(e, tp, eg, ep, ev, re, r, rp)
    local start_turn = e:GetLabel()
    return Duel.GetTurnCount() == start_turn + 5
end
function s.retop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetOwner()
    if c and c:IsLocation(LOCATION_REMOVED) then
        Duel.SendtoDeck(c, nil, SEQ_DECKTOP, REASON_EFFECT)
    end
    e:Reset()
end
