local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833


function s.initial_effect(c)
    -- Activate Spell
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    
    -- If sent to GY by a card effect: Set this card
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

-- Filter check for the cost materials (Hand or Field)
function s.matfilter(c)
    return (c:IsCode(CARD_PURIRUN) or c:IsCode(CARD_MERORON)) and c:IsAbleToGrave()
end

-- Special Summon Filters (Strictly restricted to DECK only)
function s.spfilter1(c, e, tp)
    return c:IsCode(CARD_CURE_ZUKYOON) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false, POS_FACEUP, tp, LOCATION_DECK)
end
function s.spfilter2(c, e, tp)
    return c:IsCode(CARD_CURE_KISS) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false, POS_FACEUP, tp, LOCATION_DECK)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        -- Strict hand restrictions check: Cannot activate if targets are trapped in the hand
        if Duel.IsExistingMatchingCard(Card.IsCode, tp, LOCATION_HAND, 0, 1, nil, CARD_CURE_ZUKYOON, CARD_CURE_KISS) then 
            return false 
        end
        
        return Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_HAND + LOCATION_MZONE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    -- Hand safety fallback check
    if Duel.IsExistingMatchingCard(Card.IsCode, tp, LOCATION_HAND, 0, 1, nil, CARD_CURE_ZUKYOON, CARD_CURE_KISS) then 
        return 
    end

    local g = Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
    if #g == 0 then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    -- Select up to 2 cards max matching either Purirun or Meroron
    local sg = g:Select(tp, 1, 2, nil)
    if #sg == 0 then return end
    
    -- Count exactly what is being sent to process the correct custom mode split
    local has_purirun = sg:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN)
    local has_meroron = sg:IsExists(Card.IsCode, 1, nil, CARD_MERORON)
    
    if Duel.SendtoGrave(sg, REASON_EFFECT) > 0 then
        local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
        if ft <= 0 then return end
        
        -- MODE 1: Purirun and Meroron -> Summon Both Zukyoon and Kiss
        if has_purirun and has_meroron and ft >= 2 then
            local sc1 = Duel.GetFirstMatchingCard(s.spfilter1, tp, LOCATION_DECK, 0, nil, e, tp)
            local sc2 = Duel.GetFirstMatchingCard(s.spfilter2, tp, LOCATION_DECK, 0, nil, e, tp)
            if sc1 and sc2 then
                Duel.SpecialSummonStep(sc1, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonStep(sc2, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonComplete()
            end
            
        -- MODE 2: Purirun Alone -> Summon Cure Zukyoon
        elseif has_purirun and not has_meroron then
            local sc = Duel.GetFirstMatchingCard(s.spfilter1, tp, LOCATION_DECK, 0, nil, e, tp)
            if sc then
                Duel.SpecialSummon(sc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
            
        -- MODE 3: Meroron Alone -> Summon Cure Kiss
        elseif has_meroron and not has_purirun then
            local sc = Duel.GetFirstMatchingCard(s.spfilter2, tp, LOCATION_DECK, 0, nil, e, tp)
            if sc then
                Duel.SpecialSummon(sc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
        end
    end
end

-- Resetting/Recycling Trap Zone placement
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
