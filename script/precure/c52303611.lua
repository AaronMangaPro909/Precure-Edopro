local s, id = GetID()

function s.initial_effect(c)
    -- Pendulum Effect
    Pendulum.AddProcedure(c)
    c:EnableCounterPermit(0x1, LOCATION_PZONE + LOCATION_MZONE)
  
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_CHAIN_SOLVED)
    e1:SetRange(LOCATION_PZONE)
    e1:SetOperation(s.ctop)
    c:RegisterEffect(e1)
    
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_PZONE)
    e2:SetCost(s.lvcost)
    e2:SetCountLimit (4)   
    e2:SetTarget(s.lvtg)
    e2:SetOperation(s.lvop)
    c:RegisterEffect(e2)
    
    -- Monster Effect
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_SPSUMMON_PROC)
    e3:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e3:SetRange(LOCATION_HAND)
    e3:SetCondition(s.hspcon)
    e3:SetTarget(s.hsptg)
    e3:SetOperation(s.hspop)
    c:RegisterEffect(e3)
    
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_TRIBUTE_LIMIT)
    e4:SetValue(s.tlimit)
    c:RegisterEffect(e4)
    
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 2))
    e5:SetCategory(CATEGORY_ATKCHANGE)
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1)
    e5:SetOperation(s.atkop)
    c:RegisterEffect(e5)
 
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD)
    e6:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetTargetRange(LOCATION_MZONE, 0)
    e6:SetValue(1)
    c:RegisterEffect(e6)
    
    local e7 = e6:Clone()
    e7:SetCode(EFFECT_REFLECT_BATTLE_DAMAGE)
    c:RegisterEffect(e7)
    
    local e8 = Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id, 3))
    e8:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e8:SetType(EFFECT_TYPE_QUICK_O)
    e8:SetCode(EVENT_CHAINING)
    e8:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCountLimit(1)
    e8:SetCondition(s.negcon)
    e8:SetTarget(s.negtg)
    e8:SetOperation(s.negop)
    c:RegisterEffect(e8)
end

function s.ctop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    -- Only add counters if the activated item was a Spell or Trap, and this card has room (< 10)
    if re:IsActiveType(TYPE_SPELL + TYPE_TRAP) and c:GetCounter(0x1) < 10 then
        c:AddCounter(0x1, 1)
    end
end

function s.lvcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsCanRemoveCounter(tp, 0x1, 1, REASON_COST) end
    e:GetHandler():RemoveCounter(tp, 0x1, 1, REASON_COST)
end

function s.lvtg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, LOCATION_MZONE, 0, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    Duel.SelectTarget(tp, Card.IsFaceup, tp, LOCATION_MZONE, 0, 1, 1, nil)
end

function s.lvop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        local op = Duel.SelectOption(tp, aux.Stringid(id, 4), aux.Stringid(id, 5), aux.Stringid(id, 6)) -- Options: 5, 7, 10
        local lv = 5
        if op == 1 then lv = 7 end
        if op == 2 then lv = 10 end
        
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CHANGE_LEVEL)
        e1:SetValue(lv)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
    end
end

--Monster Effect
function s.hspcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, c)
end

function s.hsptg(e, tp, eg, ep, ev, re, r, rp, chk, c)
    local g = Duel.GetMatchingGroup(Card.IsDiscardable, tp, LOCATION_HAND, 0, c)
    if #g > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISCARD)
        local sg = g:Select(tp, 1, 1, nil)
        if #sg > 0 then
            sg:KeepAlive()
            e:SetLabelObject(sg)
            return true
        end
    end
    return false
end

function s.hspop(e, tp, eg, ep, ev, re, r, rp, c)
    local g = e:GetLabelObject()
    if not g then return end
    Duel.SendtoGrave(g, REASON_COST + REASON_DISCARD)
    g:DeleteGroup()
end

function s.tlimit(e, c)
    -- Requires tributed monsters to be Level 7 or higher
    return c:IsLevelAbove(7)
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

function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
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
