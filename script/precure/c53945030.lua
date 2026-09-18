-- Cure Change
local s, id = GetID()

function s.initial_effect(c)
  
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0, TIMING_END_PHASE)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

local ARCH_PRECURE = 0xb54

function s.costfilter(c, e, tp)
    if not (c:IsFaceup() and c:IsSetCard(ARCH_PRECURE) and c:IsAbleToGraveAsCost()) then return false end
    
    if Duel.GetLocationCountFromEx(tp, tp, c) <= 0 then return false end
    
    local code = c:GetCode()

    return Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp, code)
end

function s.spfilter(c, e, tp, code)
    return c:IsSetCard(ARCH_PRECURE) and c:IsCode(code) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_MZONE, 0, 1, nil, e, tp) end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_MZONE, 0, 1, 1, nil, e, tp)
    e:SetLabel(g:GetFirst():GetCode())
    Duel.SendtoGrave(g, REASON_COST)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
 
   if Duel.GetLocationCountFromEx(tp) <= 0 then return end
    
    local code = e:GetLabel()
    
 Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp, code)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end
