-- Cure Prism
local s, id = GetID()

function s.initial_effect(c)
   
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_DESTROY + CATEGORY_DAMAGE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)
    
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_DIRECT_ATTACK)
    c:RegisterEffect(e2)
end

function s.desfilter(c)
    return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_DARK)
end
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.desfilter, tp, 0, LOCATION_MZONE, 1, nil) end
    local g = Duel.GetMatchingGroup(s.desfilter, tp, 0, LOCATION_MZONE, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, #g, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_DAMAGE, nil, 0, 1 - tp, 600)
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(s.desfilter, tp, 0, LOCATION_MZONE, nil)
    if #g > 0 and Duel.Destroy(g, REASON_EFFECT) ~= 0 then
        Duel.BreakEffect()
        Duel.Damage(1 - tp, 600, REASON_EFFECT)
    end
end
