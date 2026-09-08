--Precure of Princess: Cure Scarlet

local s, id = GetID()

function s.initial_effect(c)
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetOperation(s.limop)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)
    
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e3:SetCondition(s.indcon)
    e3:SetValue(1) 
    c:RegisterEffect(e3)
end

function s.cfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xb54)
end

function s.limop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()

    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetTargetRange(0, 1) 
    e1:SetValue(s.aclimit)
    e1:SetReset(RESET_PHASE + PHASE_END)
    Duel.RegisterEffect(e1, tp)
end

function s.aclimit(e, re, tp)
    return re:IsActiveType(TYPE_SPELL + TYPE_TRAP)
end

function s.indcon(e)
    local tp = e:GetHandlerPlayer()
    return Duel.GetMatchingGroupCount(s.cfilter, tp, LOCATION_MZONE, 0, nil) >= 2
end
