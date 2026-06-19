-- Cure Answer

local s, id = GetID()

function s.initial_effect(c)
   
    Pendulum.AddProcedure(c)
    
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetRange(LOCATION_PZONE)
    e1:SetCondition(s.pstatcon)
    e1:SetOperation(s.pstatop)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_ATKCHANGE + CATEGORY_DEFCHANGE)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetOperation(s.statop)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_DESTROY)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_MOVE)
    e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.descon)
    e3:SetTarget(s.destg)
    e3:SetOperation(s.desop)
    c:RegisterEffect(e3)
end

local ARCH_PRECURE = 0xb54

function s.pfilter(c)
    return c:IsFaceup() and c:IsSetCard(ARCH_PRECURE) and (c:GetSummonType() & SUMMON_TYPE_PENDULUM) == SUMMON_TYPE_PENDULUM
end

function s.pstatcon(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(s.pfilter, 1, nil)
end

function s.pstatop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = eg:Filter(s.pfilter, nil)
    
    for tc in aux.Next(g) do
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(1000)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
        local e2 = e1:Clone()
        e2:SetCode(EFFECT_UPDATE_DEFENSE)
        tc:RegisterEffect(e2)
    end
end

function s.statop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(900)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE)
        c:RegisterEffect(e1)
        local e2 = e1:Clone()
        e2:SetCode(EFFECT_UPDATE_DEFENSE)
        c:RegisterEffect(e2)
    end
end

function s.movefilter(c, tp)
    if c:GetPreviousControler() ~= tp then return false end 
    local loc = c:GetLocation()
    local ploc = c:GetPreviousLocation()
    local was_in_gy_or_ex = (ploc == LOCATION_GRAVE) or (ploc == LOCATION_EXTRA and c:IsPreviousPosition(POS_FACEUP))
    local went_to_deck_or_hand = (loc == LOCATION_DECK) or (loc == LOCATION_HAND)
    return was_in_gy_or_ex and went_to_deck_or_hand and (c:GetReason() & REASON_EFFECT) ~= 0
end

function s.descon(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(s.movefilter, 1, nil, tp)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.IsExistingTarget(Card.IsType, tp, 0, LOCATION_MZONE, 1, nil, TYPE_MONSTER) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectTarget(tp, Card.IsType, tp, 0, LOCATION_MZONE, 1, 1, nil, TYPE_MONSTER)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Destroy(tc, REASON_EFFECT)
    end
end
