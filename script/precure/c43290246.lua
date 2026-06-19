--Precure of Princess: Cure Mermaid

local s, id = GetID()

function s.initial_effect(c)
    
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_ATKCHANGE)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F) 
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1, id)
    e1:SetTarget(s.atktg)
    e1:SetOperation(s.atkop)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)

    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_DRAW)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O) 
    e3:SetCode(EVENT_SUMMON_SUCCESS)
    e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_PLAYER_TARGET)
    e3:SetCountLimit(1, id + 100) 
    e3:SetTarget(s.drwtg)
    e3:SetOperation(s.drwop)
    c:RegisterEffect(e3)
end

function s.filter(c)
    return c:IsFaceup() and c:IsSetCard(0xb54)
end

function s.atktg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
end

function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetMatchingGroup(s.filter, tp, LOCATION_MZONE, LOCATION_MZONE, nil)
    
    local tc = g:GetFirst()
    while tc do
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(1200)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
        tc = g:GetNext()
    end
end

function s.drwtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        local count = Duel.GetMatchingGroupCount(s.filter, tp, LOCATION_MZONE, LOCATION_MZONE, nil)
        return count > 0 and Duel.IsPlayerCanDraw(tp, count)
    end
    Duel.SetTargetPlayer(tp)
    local count = Duel.GetMatchingGroupCount(s.filter, tp, LOCATION_MZONE, LOCATION_MZONE, nil)
    Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, count)
end

function s.drwop(e, tp, eg, ep, ev, re, r, rp)
    local p = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER)
    local count = Duel.GetMatchingGroupCount(s.filter, tp, LOCATION_MZONE, LOCATION_MZONE, nil)
    if count > 0 then
        Duel.Draw(p, count, REASON_EFFECT)
    end
end
