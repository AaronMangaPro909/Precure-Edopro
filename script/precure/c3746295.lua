-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card ID Constants
local CARD_CURE_IDOL            = 39517403 -- !! CHANGE THIS TO CURE IDOL'S ID !!
local CARD_IDOL_HEART_RIBBON    = 4626483 -- !! CHANGE THIS TO IDOL HEART RIBBON STYLE'S ID !!
local CARD_GOD_IDOL_STYLE       = 25242020 -- !! CHANGE THIS TO GOD IDOL STYLE'S ID !!

function s.initial_effect(c)
    -- Activate: Pay 900 LP, Tribute 1 "Cure Idol" monster, then Special Summon 1 specific form
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

s.listed_names = {CARD_CURE_IDOL, CARD_IDOL_HEART_RIBBON, CARD_GOD_IDOL_STYLE}

-------------------------------------------------------------------------
-- COST: Pay 900 LP & Tribute 1 "Cure Idol" from hand or field
-------------------------------------------------------------------------
function s.costfilter(c, tp)
    return c:IsCode(CARD_CURE_IDOL) and (c:IsControler(tp) and c:IsLocation(LOCATION_MZONE) or c:IsLocation(LOCATION_HAND))
        and (c:IsFaceup() or c:IsLocation(LOCATION_HAND))
        and (c:IsReleasable() or (c:IsLocation(LOCATION_MZONE) and Duel.IsPlayerCanRelease(tp, c)))
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.CheckLPCost(tp, 900)
            and Duel.CheckReleaseGroup(tp, s.costfilter, 1, nil, tp)
    end
    
    Duel.PayLPCost(tp, 900)
    
    local g = Duel.SelectReleaseGroup(tp, s.costfilter, 1, 1, nil, tp)
    Duel.Release(g, REASON_COST)
end

-------------------------------------------------------------------------
-- TARGET & SPECIAL SUMMON ENGINE
-------------------------------------------------------------------------
function s.spfilter(c, e, tp)
    return c:IsCode(CARD_IDOL_HEART_RIBBON, CARD_GOD_IDOL_STYLE) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > -1 -- Accounts for the tributed monster leaving the field freeing up a zone
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end