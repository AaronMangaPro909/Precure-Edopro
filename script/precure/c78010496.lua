local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833

function s.initial_effect(c)
    -- Activate: Send Purirun and/or Meroron from Hand/Field -> Special Summon respective Cure monsters
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

-- Filters for identifying usable materials
function s.matfilter(c)
    return (c:IsCode(CARD_PURIRUN) or c:IsCode(CARD_MERORON)) and c:IsAbleToGrave()
end

-- Checks specific targets to see if their matching Cure counterpart is available to summon
function s.spcheck(g, e, tp)
    local has_purirun = g:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN)
    local has_meroron = g:IsExists(Card.IsCode, 1, nil, CARD_MERORON)
    
    -- Calculate required Monster Zone space based on field adjustments
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    local field_count = g:FilterCount(Card.IsLocation, nil, LOCATION_MZONE)
    ft = ft + field_count
    
    local req_space = 0
    if has_purirun then req_space = req_space + 1 end
    if has_meroron then req_space = req_space + 1 end
    if ft < req_space then return false end
    
    -- Verify target validity inside Hand/Deck pools
    if has_purirun and not Duel.IsExistingMatchingCard(Card.IsCanBeSpecialSummoned, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, SUMMON_TYPE_SPECIAL, tp, true, false, CARD_CURE_ZUKYOON) then return false end
    if has_meroron and not Duel.IsExistingMatchingCard(Card.IsCanBeSpecialSummoned, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, SUMMON_TYPE_SPECIAL, tp, true, false, CARD_CURE_KISS) then return false end
    
    return true
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    local g = Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
    if chk == 0 then
        return aux.SelectUnselectGroup(g, e, tp, 1, 2, s.spcheck, 0)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_HAND + LOCATION_MZONE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
    local sg = aux.SelectUnselectGroup(g, e, tp, 1, 2, s.spcheck, 1, tp, HINTMSG_TOGRAVE, s.spcheck)
    
    if #sg > 0 and Duel.SendtoGrave(sg, REASON_EFFECT) > 0 then
        local has_purirun = sg:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN)
        local has_meroron = sg:IsExists(Card.IsCode, 1, nil, CARD_MERORON)
        
        -- Execute Cure Zukyoon Summon sequence
        if has_purirun and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local zyk = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, CARD_CURE_ZUKYOON):GetFirst()
            if zyk then
                Duel.SpecialSummonStep(zyk, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
        end
        
        -- Execute Cure Kiss Summon sequence
        if has_meroron and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local kiss = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, CARD_CURE_KISS):GetFirst()
            if kiss then
                Duel.SpecialSummonStep(kiss, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
        end
        
        Duel.SpecialSummonComplete()
    end
end

-- E2 Logic (Self-setting cycle)
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
