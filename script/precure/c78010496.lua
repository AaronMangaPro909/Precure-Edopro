local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833

function s.initial_effect(c)
    -- Activate: Send from Hand/Field -> Special Summon corresponding monster(s)
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    
    -- Continuous: If sent to GY by card effect, Set itself
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 3))
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCondition(s.setcon)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)
end

-- Special Summon Filters
function s.spfilter1(c, e, tp)
    return c:IsCode(CARD_CURE_ZUKYOON) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false)
end
function s.spfilter2(c, e, tp)
    return c:IsCode(CARD_CURE_KISS) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false)
end

-- Condition Checks for Menu Options
function s.chk1(e, tp) -- Purirun alone
    return Duel.IsExistingMatchingCard(Card.IsCode, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
        and Duel.IsExistingMatchingCard(s.spfilter1, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp)
        and Duel.GetMZoneCount(tp, Duel.GetMatchingGroup(Card.IsCode, tp, LOCATION_MZONE, 0, nil, CARD_PURIRUN)) > 0
end

function s.chk2(e, tp) -- Meroron alone
    return Duel.IsExistingMatchingCard(Card.IsCode, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
        and Duel.IsExistingMatchingCard(s.spfilter2, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp)
        and Duel.GetMZoneCount(tp, Duel.GetMatchingGroup(Card.IsCode, tp, LOCATION_MZONE, 0, nil, CARD_MERORON)) > 0
end

function s.chk3(e, tp) -- Both together
    local matg = Duel.GetMatchingGroup(Card.IsCode, tp, LOCATION_MZONE, 0, nil, CARD_PURIRUN, CARD_MERORON)
    return Duel.IsExistingMatchingCard(Card.IsCode, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
        and Duel.IsExistingMatchingCard(Card.IsCode, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
        and Duel.IsExistingMatchingCard(s.spfilter1, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp)
        and Duel.IsExistingMatchingCard(s.spfilter2, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp)
        and Duel.GetMZoneCount(tp, matg) > 1
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return s.chk1(e, tp) or s.chk2(e, tp) or s.chk3(e, tp) end
    
    -- Determine which options are playable to dynamically build the menu
    local b1 = s.chk1(e, tp)
    local b2 = s.chk2(e, tp)
    local b3 = s.chk3(e, tp)
    
    local op = 0
    if b1 and b2 and b3 then
        op = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 1), aux.Stringid(id, 2))
    elseif b1 and b2 then
        op = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 1))
    elseif b1 and b3 then
        op = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 2))
        if op == 1 then op = 2 end
    elseif b2 and b3 then
        op = Duel.SelectOption(tp, aux.Stringid(id, 1), aux.Stringid(id, 2)) + 1
    elseif b1 then op = 0
    elseif b2 then op = 1
    elseif b3 then op = 2 end
    
    e:SetLabel(op)
    
    if op == 0 then
        Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_HAND + LOCATION_MZONE)
        Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
    elseif op == 1 then
        Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_HAND + LOCATION_MZONE)
        Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
    local g = Duel.GetMatchingGroup(Card.IsCode, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil, CARD_PURIRUN, CARD_MERORON)
    elseif op == 2 then
        Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 2, tp, LOCATION_HAND + LOCATION_MZONE)
        Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 2, tp, LOCATION_HAND + LOCATION_DECK)
    end
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local op = e:GetLabel()
    
    -- OPTION 0: Purirun -> Cure Zukyoon
    if op == 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_PURIRUN)
        if #g > 0 and Duel.SendtoGrave(g, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc = Duel.SelectMatchingCard(tp, s.spfilter1, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp):GetFirst()
            if sc then
                Duel.SpecialSummon(sc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
        end
        
    -- OPTION 1: Meroron -> Cure Kiss
    elseif op == 1 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_MERORON)
        if #g > 0 and Duel.SendtoGrave(g, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc = Duel.SelectMatchingCard(tp, s.spfilter2, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp):GetFirst()
            if sc then
                Duel.SpecialSummon(sc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
        end
        
    -- OPTION 2: Purirun + Meroron -> Both
    elseif op == 2 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g1 = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_PURIRUN)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g2 = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, g1:GetFirst(), CARD_MERORON)
        g1:Merge(g2)
        
        if #g1 == 2 and Duel.SendtoGrave(g1, REASON_EFFECT) == 2 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc1 = Duel.SelectMatchingCard(tp, s.spfilter1, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp):GetFirst()
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc2 = Duel.SelectMatchingCard(tp, s.spfilter2, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, sc1, e, tp):GetFirst()
            
            if sc1 and sc2 then
                Duel.SpecialSummonStep(sc1, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonStep(sc2, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonComplete()
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
