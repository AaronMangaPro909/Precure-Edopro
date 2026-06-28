-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Custom Card ID Configurations
local CARD_PURIRUN   = 41037083 -- !! CHANGE THIS !!
local CARD_MERORON   = 5826302 -- !! CHANGE THIS !!
local CARD_CURE_ZUKYOON   = 19379373 -- !! CHANGE THIS !!
local CARD_CURE_KISS      = 60519833 -- !! CHANGE THIS !!

function s.initial_effect(c)
    -- Activate: Send Purirun and Meroron to GY -> Special Summon Zukyoon and Kiss
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    
    -- Continuous: If sent to GY by card effect, Set itself
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCondition(s.setcon)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)
end

-- E1 Logic
function s.tgfilter1(c, tp)
    return c:IsCode(CARD_PURIRUN) and c:IsAbleToGrave()
        and Duel.IsExistingMatchingCard(s.tgfilter2, tp, LOCATION_HAND +  LOCATION_MZONE, 0, 1, c)
end
function s.tgfilter2(c)
    return c:IsCode(CARD_MERORON) and c:IsAbleToGrave()
end
function s.spfilter1(c, e, tp)
    return c:IsCode(CARD_CURE_ZUKYOON) and c:IsCanBeSpecialSummoned(e, 0, tp, true, false)
        and Duel.IsExistingMatchingCard(s.spfilter2, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, c, e, tp)
end
function s.spfilter2(c, e, tp)
    return c:IsCode(CARD_CURE_KISS) and c:IsCanBeSpecialSummoned(e, 0, tp, true, false)
end
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then 
        -- Standard check accounting for sending 2 monsters to clear zone spaces
        local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
        if ft < 0 then return false end
        return Duel.IsExistingMatchingCard(s.tgfilter1, tp, LOCATION_MZONE, 0, 1, nil, tp)
            and Duel.IsExistingMatchingCard(s.spfilter1, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 2, tp, LOCATION_MZONE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 2, tp, LOCATION_HAND + LOCATION_DECK)
end
function s.activate(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local g1 = Duel.SelectMatchingCard(tp, s.tgfilter1, tp, LOCATION_MZONE, 0, 1, 1, nil, tp)
    if #g1 == 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local g2 = Duel.SelectMatchingCard(tp, s.tgfilter2, tp, LOCATION_MZONE, 0, 1, 1, g1:GetFirst())
    g1:Merge(g2)
    
    if Duel.SendtoGrave(g1, REASON_EFFECT) == 2 then
        if Duel.GetLocationCount(tp, LOCATION_MZONE) < 2 then return end
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sc1 = Duel.SelectMatchingCard(tp, s.spfilter1, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp):GetFirst()
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sc2 = Duel.SelectMatchingCard(tp, s.spfilter2, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, sc1, e, tp):GetFirst()
        
        if sc1 and sc2 then
            Duel.SpecialSummonStep(sc1, 0, tp, tp, true, false, LOCATION_MZONE)
            Duel.SpecialSummonStep(sc2, 0, tp, tp, true, false, LOCATION_MZONE)
            Duel.SpecialSummonComplete()
        end
    end
end

-- E2 Logic
function s.setcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsReason(REASON_EFFECT)
end
function s.settg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsSSetable() end
    Duel.SetOperationInfo(0, CATEGORY_LEAVE_GRAVE, e:GetHandler(), 1, 0, 0)
end
function s.setop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsSSetable() then
        Duel.SSet(tp, c)
    end
end
