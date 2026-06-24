local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833


function s.initial_effect(c)
    -- Activate: Send combination from hand/field -> Special Summon from hand/deck
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

-- Check if a card counts as Purirun (either itself or Cure Zukyoon)
function s.p_filter(c)
    return (c:IsCode(CARD_PURIRUN) or c:IsCode(CARD_CURE_ZUKYOON)) and c:IsAbleToGrave()
end

-- Check if a card counts as Meroron (either itself or Cure Kiss)
function s.m_filter(c)
    return (c:IsCode(CARD_MERORON) or c:IsCode(CARD_CURE_KISS)) and c:IsAbleToGrave()
end

-- Subgroup validation strategy for the selection process
function s.check_group(g, e, tp)
    local p_count = g:FilterCount(s.p_filter, nil)
    local m_count = g:FilterCount(s.m_filter, nil)
    local total = #g
    
    -- Zone counting management (accounts for clearing spaces if materials leave the field)
    local field_count = g:FilterCount(Card.IsLocation, nil, LOCATION_MZONE)
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE) + field_count
    
    if total == 1 and p_count == 1 then
        return ft > 0 and Duel.IsExistingMatchingCard(s.sp_zukyoon, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, g, e, tp)
    elseif total == 1 and m_count == 1 then
        return ft > 0 and Duel.IsExistingMatchingCard(s.sp_kiss, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, g, e, tp)
    elseif total == 2 and p_count == 1 and m_count == 1 then
        return ft > 1 and Duel.IsExistingMatchingCard(s.sp_zukyoon, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, g, e, tp)
           and Duel.IsExistingMatchingCard(s.sp_kiss, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, g, e, tp)
    end
    return false
end

function s.sp_zukyoon(c, e, tp)
    return c:IsCode(CARD_CURE_ZUKYOON) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false)
end

function s.sp_kiss(c, e, tp)
    return c:IsCode(CARD_CURE_KISS) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    local rg = Duel.GetMatchingGroup(function(c) return s.p_filter(c) or s.m_filter(c) end, tp, LOCATION_HAND + LOCATION_MZONE, 0, e:GetHandler())
    if chk == 0 then
        return rg:CheckSubGroup(s.check_group, 1, 2, e, tp)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_HAND + LOCATION_MZONE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local rg = Duel.GetMatchingGroup(function(c) return s.p_filter(c) or s.m_filter(c) end, tp, LOCATION_HAND + LOCATION_MZONE, 0, e:GetHandler())
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local sg = rg:SelectSubGroup(tp, s.check_group, false, 1, 2, e, tp)
    
    if sg and #sg > 0 and Duel.SendtoGrave(sg, REASON_EFFECT) > 0 then
        local p_count = sg:FilterCount(s.p_filter, nil)
        local m_count = sg:FilterCount(s.m_filter, nil)
        
        -- Case 1: Purirun alone -> Summon Cure Zukyoon
        if #sg == 1 and p_count == 1 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local tc = Duel.SelectMatchingCard(tp, s.sp_zukyoon, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp):GetFirst()
            if tc then
                Duel.SpecialSummon(tc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
            
        -- Case 2: Meroron alone -> Summon Cure Kiss
        elseif #sg == 1 and m_count == 1 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local tc = Duel.SelectMatchingCard(tp, s.sp_kiss, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp):GetFirst()
            if tc then
                Duel.SpecialSummon(tc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
            
        -- Case 3: Both -> Summon both Zukyoon and Kiss
        elseif #sg == 2 and p_count == 1 and m_count == 1 then
            if Duel.GetLocationCount(tp, LOCATION_MZONE) < 2 then return end
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc1 = Duel.SelectMatchingCard(tp, s.sp_zukyoon, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp):GetFirst()
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc2 = Duel.SelectMatchingCard(tp, s.sp_kiss, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, sc1, e, tp):GetFirst()
            
            if sc1 and sc2 then
                Duel.SpecialSummonStep(sc1, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonStep(sc2, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonComplete()
            end
        end
    end
end

-- GY Recycle Trigger
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
