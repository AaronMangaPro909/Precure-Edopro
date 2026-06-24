local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833


function s.initial_effect(c)
    -- Activate: Send from Hand/Field to GY -> Special Summon from Hand/Deck
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

-- Material Filters (Hand or Field)
function s.matfilter(c, code)
    return c:IsCode(code) and c:IsAbleToGrave() and (c:IsLocation(LOCATION_HAND) or c:IsFaceup())
end

-- Special Summon Filters (Hand or Deck)
function s.spfilter(c, e, tp, code)
    return c:IsCode(code) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
        if ft <= 0 then return false end
        
        -- Check Option 1: Purirun -> Cure Zukyoon
        local b1 = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
            
        -- Check Option 2: Meroron -> Cure Kiss
        local b2 = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
            
        -- Check Option 3: Both -> Both (Requires 2 open zones if materials are sent from hand)
        local b3 = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
            and Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
            
        return b1 or b2 or b3
    end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_HAND + LOCATION_MZONE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if ft <= 0 then return end

    -- Evaluate legal options at resolution
    local b1 = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
        
    local b2 = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
        
    local b3 = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
        and Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)

    -- Dynamic Selection Menu
    local opt = 0
    if b1 and b2 and b3 then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 1), aux.Stringid(id, 2))
    elseif b1 and b2 then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 1))
    elseif b1 and b3 then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 2))
        if opt == 1 then opt = 2 end
    elseif b2 and b3 then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 1), aux.Stringid(id, 2)) + 1
    elseif b1 then
        opt = 0
    elseif b2 then
        opt = 1
    elseif b3 then
        opt = 2
    else
        return
    end

    -- Execution Option 1: Purirun -> Cure Zukyoon
    if opt == 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local mat = Duel.SelectMatchingCard(tp, s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_PURIRUN)
        if #mat > 0 and Duel.SendtoGrave(mat, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local spc = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, CARD_CURE_ZUKYOON):GetFirst()
            if spc then
                Duel.SpecialSummon(spc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
        end

    -- Execution Option 2: Meroron -> Cure Kiss
    elseif opt == 1 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local mat = Duel.SelectMatchingCard(tp, s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_MERORON)
        if #mat > 0 and Duel.SendtoGrave(mat, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local spc = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, CARD_CURE_KISS):GetFirst()
            if spc then
                Duel.SpecialSummon(spc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
        end

    -- Execution Option 3: Both -> Both
    elseif opt == 2 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local m1 = Duel.SelectMatchingCard(tp, s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_PURIRUN)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local m2 = Duel.SelectMatchingCard(tp, s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, m1:GetFirst(), CARD_MERORON)
        m1:Merge(m2)
        
        if #m1 == 2 and Duel.SendtoGrave(m1, REASON_EFFECT) == 2 then
            if Duel.GetLocationCount(tp, LOCATION_MZONE) < 2 then return end
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc1 = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, CARD_CURE_ZUKYOON):GetFirst()
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc2 = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, sc1, e, tp, CARD_CURE_KISS):GetFirst()
            
            if sc1 and sc2 then
                Duel.SpecialSummonStep(sc1, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonStep(sc2, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonComplete()
            end
        end
    end
end

-- E2 Auto-Set Logic
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
