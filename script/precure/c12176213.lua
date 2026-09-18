-- Cure Éclair

local s, id = GetID()

function s.initial_effect(c)
    Pendulum.AddProcedure(c)
    
    c:EnableCounterPermit(0x1, LOCATION_PZONE + LOCATION_MZONE)
   
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_RECOVER)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_PHASE + PHASE_STANDBY)
    e1:SetRange(LOCATION_PZONE)
    e1:SetCountLimit(1)
    e1:SetCondition(s.lpcon)
    e1:SetTarget(s.lptg)
    e1:SetOperation(s.lpop)
    c:RegisterEffect(e1)
    
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_CHAIN_SOLVED)
    e2:SetRange(LOCATION_PZONE)
    e2:SetOperation(s.ctop)
    c:RegisterEffect(e2)
    
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_PZONE)
    e3:SetCost(s.typecost)
    e3:SetTarget(s.typetg)
    e3:SetOperation(s.typeop)
    c:RegisterEffect(e3)
    
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_COUNTER)
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e4:SetCode(EVENT_SUMMON_SUCCESS)
    e4:SetTarget(s.addcttg)
    e4:SetOperation(s.addctop)
    c:RegisterEffect(e4)
    
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 3))
    e5:SetCategory(CATEGORY_COUNTER + CATEGORY_HANDES)
    e5:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O) 
    e5:SetCode(EVENT_SPSUMMON_SUCCESS)
    e5:SetProperty(EFFECT_FLAG_DELAY)
    e5:SetTarget(s.spcttg)
    e5:SetOperation(s.spctop)
    c:RegisterEffect(e5)
    
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCode(EFFECT_UPDATE_ATTACK)
    e6:SetValue(s.atkval)
    c:RegisterEffect(e6)
    
    local e7 = Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id, 4))
    e7:SetCategory(CATEGORY_DESTROY + CATEGORY_ATKCHANGE)
    e7:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    e7:SetCode(EVENT_PHASE + PHASE_END)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCountLimit(1)
    e7:SetTarget(s.descttg)
    e7:SetOperation(s.desctop)
    c:RegisterEffect(e7)
end

function s.lpcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnPlayer() == tp
end

function s.lptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_RECOVER, nil, 0, tp, 500)
end

function s.lpop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Recover(tp, 500, REASON_EFFECT)
end

function s.ctop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if re:IsActiveType(TYPE_SPELL) and c:GetCounter(0x1) < 6 then
        c:AddCounter(0x1, 1)
    end
end

function s.typecost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsCanRemoveCounter(tp, 0x1, 1, REASON_COST) end
    e:GetHandler():RemoveCounter(tp, 0x1, 1, REASON_COST)
end

function s.typetg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsFaceup, tp, LOCATION_MZONE, LOCATION_MZONE, 1, nil) end
    local rc = Duel.AnnounceRace(tp, 1, RACE_DRAGON + RACE_SPELLCASTER + RACE_MACHINE)
    e:SetLabel(rc)
end

function s.typeop(e, tp, eg, ep, ev, re, r, rp)
    local rc = e:GetLabel()
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, LOCATION_MZONE, LOCATION_MZONE, nil)
    
    for tc in aux.Next(g) do
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CHANGE_RACE)
        e1:SetValue(rc)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
    end
end

function s.addcttg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_COUNTER, nil, 1, 0, 0x1)
end

function s.addctop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        c:AddCounter(0x1, 1)
    end
end

function s.dcfilter(c)
    return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsDiscardable()
end

function s.spcttg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.dcfilter, tp, LOCATION_HAND, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_HANDES, nil, 0, tp, 1)
end

function s.spctop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    
    local g = Duel.GetMatchingGroup(s.dcfilter, tp, LOCATION_HAND, 0, nil)
    if #g == 0 then return end
    
    local ct = #g
    if ct > 3 then ct = 3 end
    
    local max_add = 6 - c:GetCounter(0x1)
    if ct > max_add then ct = max_add end
    if ct <= 0 then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISCARD)
    local sg = g:Select(tp, 1, ct, nil)
    if #sg > 0 then
        local discarded_count = Duel.SendtoGrave(sg, REASON_EFFECT + REASON_DISCARD)
        if discarded_count > 0 then
            c:AddCounter(0x1, discarded_count)
        end
    end
end

function s.atkval(e, c)
    return c:GetCounter(0x1) * 500
end

function s.descttg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    local g = Duel.GetMatchingGroup(Card.IsType, tp, 0, LOCATION_SZONE, nil, TYPE_SPELL + TYPE_TRAP)
    if #g > 0 then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
    end
end

function s.desctop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) or not c:IsCanRemoveCounter(tp, 0x1, 1, REASON_EFFECT) then return end
    
    c:RemoveCounter(tp, 0x1, 1, REASON_EFFECT)
    local g = Duel.GetMatchingGroup(Card.IsType, tp, 0, LOCATION_SZONE, nil, TYPE_SPELL + TYPE_TRAP)
    if #g > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 5)) then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
        local sg = g:Select(tp, 1, 1, nil)
        if #sg > 0 then
            Duel.HintSelection(sg)
            if Duel.Destroy(sg, REASON_EFFECT) > 0 and c:IsFaceup() then
                Duel.BreakEffect()
                local e1 = Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_UPDATE_ATTACK)
                e1:SetValue(100)
                e1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE)
                c:RegisterEffect(e1)
            end
        end
    end
end
