-- Answer Hanamaru Sword
local s, id = GetID()
function s.initial_effect(c)
    aux.AddEquipProcedure(c, nil, aux.FilterBoolFunction(Card.IsCode, 45616636))
    
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_EQUIP)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(2000)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_EQUIP)
    e2:SetCode(EFFECT_PIERCE)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_PRE_BATTLE_DAMAGE)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCondition(s.damcon)
    e3:SetOperation(s.damop)
    c:RegisterEffect(e3)
end

s.listed_names = {45616636}

function s.damcon(e, tp, eg, ep, ev, re, r, rp)
    local eq = e:GetHandler():GetEquipTarget()
    local target = Duel.GetAttackTarget()
    return eq and Duel.GetAttacker() == eq and target ~= nil and target:IsControler(1 - tp)
end

function s.damop(e, tp, eg, ep, ev, re, r, rp)
    Duel.ChangeBattleDamage(ep, ev * 2)
end