local s, id = GetID()
function s.initial_effect(c)
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_REMOVE + CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end
function s.cfilter(c, tp)
    return c:IsRace(RACE_WARRIOR) and Duel.GetMZoneCount(tp, c) > 0
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then 
        return Duel.CheckLPCost(tp, 1000) 
            and Duel.CheckReleaseGroupCost(tp, s.cfilter, 1, false, nil, nil, tp) 
    end
    Duel.PayLPCost(tp, 1000)
    local sg = Duel.SelectReleaseGroupCost(tp, s.cfilter, 1, 1, false, nil, nil, tp)
    Duel.Release(sg, REASON_COST)
end
function s.rmfilter(c)
    return c:IsCode(65935871)
        and (c:IsLocation(LOCATION_HAND) or c:IsFaceup()) 
        and c:IsAbleToRemove()
end
function s.spfilter(c, e, tp)
    return c:IsCode(84351103)
        and c:IsMonster() 
        and c:IsCanBeSpecialSummoned(e, 0, tp, true, true)
end
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > -1
            and Duel.IsExistingMatchingCard(s.rmfilter, tp, LOCATION_HAND | LOCATION_GRAVE, 0, 1, nil)
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND | LOCATION_GRAVE | LOCATION_DECK, 0, 1, nil, e, tp)
    end  
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, tp, LOCATION_HAND | LOCATION_GRAVE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND | LOCATION_GRAVE | LOCATION_DECK)
end
function s.activate(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
    local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.rmfilter), tp, LOCATION_HAND | LOCATION_GRAVE, 0, 1, 1, nil)
    if #g > 0 and Duel.Remove(g, POS_FACEUP, REASON_EFFECT) > 0 then
        if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
        
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sg = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spfilter), tp, LOCATION_HAND | LOCATION_GRAVE | LOCATION_DECK, 0, 1, 1, nil, e, tp)
        if #sg > 0 then
            local tc = sg:GetFirst()
            if tc then
                Duel.SpecialSummonStep(tc, 0, tp, tp, true, true, POS_FACEUP)
                tc:CompleteProcedure()
                Duel.SpecialSummonComplete()
            end
        end
    end
end
