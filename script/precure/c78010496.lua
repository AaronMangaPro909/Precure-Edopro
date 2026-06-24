local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833


function s.initial_effect(c)
    -- Activate: Choose from Hand or Field -> Special Summon from Hand/Deck
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

-- Filters valid targets (Strictly Purirun or Meroron, ignoring Cure Kiss/Zukyoon if in hand)
function s.tgfilter(c)
    return (c:IsCode(CARD_PURIRUN) or c:IsCode(CARD_MERORON)) and c:IsAbleToGrave()
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        -- Check if there is at least one valid Purirun or Meroron in Hand or Field
        return Duel.IsExistingMatchingCard(s.tgfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_HAND + LOCATION_MZONE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(s.tgfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
    if #g == 0 then return end
    
    -- Prompt player to select up to 2 materials from hand/field combined
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local sg = g:Select(tp, 1, 2, nil)
    if #sg == 0 then return end
    
    -- Send selected cards to GY
    if Duel.SendtoGrave(sg, REASON_EFFECT) > 0 then
        -- Determine what was sent
        local has_purirun = sg:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN)
        local has_meroron = sg:IsExists(Card.IsCode, 1, nil, CARD_MERORON)
        
        -- Case 1: Both Purirun and Meroron were sent
        if has_purirun and has_meroron then
            if Duel.GetLocationCount(tp, LOCATION_MZONE) < 2 then return end
            local zyk = Duel.GetFirstMatchingCard(Card.IsCode, tp, LOCATION_HAND + LOCATION_DECK, 0, nil, CARD_CURE_ZUKYOON)
            local kiss = Duel.GetFirstMatchingCard(Card.IsCode, tp, LOCATION_HAND + LOCATION_DECK, 0, nil, CARD_CURE_KISS)
            if zyk and kiss and zyk:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false) 
               and kiss:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false) then
                Duel.SpecialSummonStep(zyk, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonStep(kiss, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonComplete()
            end
            
        -- Case 2: Only Purirun was sent
        elseif has_purirun then
            if Duel.GetLocationCount(tp, LOCATION_MZONE) < 1 then return end
            local zyk = Duel.GetFirstMatchingCard(Card.IsCode, tp, LOCATION_HAND + LOCATION_DECK, 0, nil, CARD_CURE_ZUKYOON)
            if zyk and zyk:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false) then
                Duel.SpecialSummon(zyk, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
            
        -- Case 3: Only Meroron was sent
        elseif has_meroron then
            if Duel.GetLocationCount(tp, LOCATION_MZONE) < 1 then return end
            local kiss = Duel.GetFirstMatchingCard(Card.IsCode, tp, LOCATION_HAND + LOCATION_DECK, 0, nil, CARD_CURE_KISS)
            if kiss and kiss:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false) then
                Duel.SpecialSummon(kiss, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
        end
    end
end

-- GY Auto-Set Logic
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
