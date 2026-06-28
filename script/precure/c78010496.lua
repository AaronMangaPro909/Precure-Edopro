-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Custom Card ID Configurations
local CARD_PURIRUN   = 41037083 -- !! CHANGE THIS !!
local CARD_MERORON   = 5826302 -- !! CHANGE THIS !!
local CARD_CURE_ZUKYOON   = 19379373 -- !! CHANGE THIS !!
local CARD_CURE_KISS      = 60519833 -- !! CHANGE THIS !!

function s.initial_effect(c)
    -- Activate effect
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
end

-------------------------------------------------------------------------
-- TRIBUTE COST HANDLING
-------------------------------------------------------------------------
function s.costfilter(c)
    -- Can be "Purirun" or "Meroron", and must be able to be Tributed from Hand or Field
    return (c:IsCode(CARD_PURIRUN) or c:IsCode(CARD_MERORON)) and c:IsReleasable()
end
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
    -- We pass e:GetHandler() to ignore this Spell card itself if it is in the hand
    if chk == 0 then return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, e:GetHandler()) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RELEASE)
    local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, e:GetHandler())
    Duel.Release(g, REASON_COST)
end

-------------------------------------------------------------------------
-- TARGET & SPECIAL SUMMON LOGIC
-------------------------------------------------------------------------
function s.spfilter(c, e, tp)
    -- Can be "Cure Zukyoon" or "Cure Kiss", and must be able to be Special Summoned
    return (c:IsCode(CARD_CURE_ZUKYOON) or c:IsCode(CARD_CURE_KISS)) 
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then 
        -- Standard check ensuring you have a zone open and a legal summon target in Hand or Deck
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp) 
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end
