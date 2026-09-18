-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card ID Constants & Archetypes
local CARD_LAURA = 29241544 -- "Laura Apollodoros Hyginus La Mer" ID
local CARD_CURE_LA_MER = 46935258 -- !! CHANGE TO "Cure La Mer"'S ID IF NEEDED !!

function s.initial_effect(c)
    -- Activate: Pay 1000 LP, Tribute 1 "Laura...", Special Summon 1 "Cure La Mer" from hand, Deck, or GY
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH) -- You can only activate 1 "Mermaid Aqua Pact" per turn
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

s.listed_names = {CARD_LAURA, CARD_CURE_LA_MER}

-------------------------------------------------------------------------
-- COST: Pay 1000 LP and Tribute 1 "Laura Apollodoros Hyginus La Mer" from hand/field
-------------------------------------------------------------------------
function s.costfilter(c, tp)
    return c:IsCode(CARD_LAURA) and (c:IsControler(tp) or c:IsFaceup()) 
        and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_MZONE)) 
        and (c:IsReleasable() or c:IsAbleToGraveAsCost())
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then 
        return Duel.CheckLPCost(tp, 1000) 
            and Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, tp) 
    end
    
    Duel.PayLPCost(tp, 1000)
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RELEASE)
    local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, tp)
    Duel.Release(g, REASON_COST)
end

-------------------------------------------------------------------------
-- TARGET: Special Summon 1 "Cure La Mer" from Hand, Deck, or GY
-------------------------------------------------------------------------
function s.spfilter(c, e, tp)
    return c:IsCode(CARD_CURE_LA_MER) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then 
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil, e, tp) 
    end
    
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE)
end

-------------------------------------------------------------------------
-- OPERATION: Execute Special Summon
-------------------------------------------------------------------------
function s.activate(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end
