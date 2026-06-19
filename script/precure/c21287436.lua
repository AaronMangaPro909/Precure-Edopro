-- Cure Wink
local s, id = GetID()

local CARD_WINK_BARRIER = 82220409

function s.initial_effect(c)

    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1, id)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)
    
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_CHAIN_SOLVING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetOperation(s.lpop)
    c:RegisterEffect(e3)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    local c = e:GetHandler()
    if chk == 0 then 
        return Duel.IsExistingTarget(Card.IsFaceUp, tp, LOCATION_MZONE, LOCATION_MZONE, 1, nil) 
    end
    
    local op = Duel.SelectOption(tp, aux.Stringid(id, 1), aux.Stringid(id, 2))
    e:SetLabel(op)
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectTarget(tp, Card.IsFaceUp, tp, LOCATION_MZONE, LOCATION_MZONE, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if not c:IsRelateToEffect(e) or not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
    
    local stat = 0
    local target_stat = 0
    
    if e:GetLabel() == 0 then
        stat = c:GetBaseAttack()
        target_stat = tc:GetAttack()
    else
        stat = c:GetBaseDefense()
        target_stat = tc:GetDefense()
    end
    
    if stat ~= target_stat then
        Duel.Destroy(tc, REASON_EFFECT)
    end
end

function s.lpop(e, tp, eg, ep, ev, re, r, rp)
    if re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:GetHandler():IsCode(82220409) then
        Duel.Hint(HINT_CARD, 0, e:GetHandler():GetCode())
        Duel.Recover(tp, 500, REASON_EFFECT)
    end
end
