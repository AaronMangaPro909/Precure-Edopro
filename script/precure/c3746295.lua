-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- !! CHANGE THESE !! 
local CARD_CURE_IDOL            = 39517403 -- Replace with Cure Idol's ID
local CARD_IDOL_HEART_RIBBON    = 4626483 -- Replace with Ribbon Style's ID
local CARD_GOD_IDOL_STYLE       = 25242019 -- Replace with God Idol Style's ID

function s.initial_effect(c)
    -- Activate: Pay 900 LP, send Cure Idol -> Special Summon 1 Style monster
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-- Filter to find "Cure Idol" in Hand or face-up on the Field
function s.tgfilter(c)
    return c:IsCode(CARD_CURE_IDOL) and c:IsAbleToGrave() 
        and (c:IsLocation(LOCATION_HAND) or c:IsFaceup())
end

-- Filter to find valid Special Summon targets in Hand or Deck
function s.spfilter(c, e, tp)
    return (c:IsCode(CARD_IDOL_HEART_RIBBON) or c:IsCode(CARD_GOD_IDOL))
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    -- Check if player can pay 900 LP and send "Cure Idol" to GY
    if chk == 0 then 
        return Duel.CheckLPCost(tp, 900)
            and Duel.IsExistingMatchingCard(s.tgfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil)
    end
    
    -- Pay 900 LP
    Duel.PayLPCost(tp, 900)
    
    -- Select and send "Cure Idol" to GY as cost
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local g = Duel.SelectMatchingCard(tp, s.tgfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil)
    Duel.SendtoGrave(g, REASON_COST)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    -- Ensure there is space on the board and valid targets exist
    if chk == 0 then 
        -- Location count check (handled here since cost clears a monster if it was on field)
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > -1
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    -- Double check zone availability on resolution
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, LOCATION_MZONE)
    end
end
