local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833


function s.initial_effect(c)
    -- Activate: Send Purirun and/or Meroron from hand/field -> Spec Summon Zukyoon and/or Kiss
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCost(s.cost)
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

-- Cost Filters
function s.rfilter(c, code)
    return c:IsCode(code) and c:IsAbleToGraveAsCost()
end

-- Checks if a valid combination can be sent and summoned
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    
    -- Condition 1: Purirun alone -> Cure Zukyoon
    local res1 = Duel.IsExistingMatchingCard(s.rfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
        and Duel.IsExistingMatchingCard(Card.IsCanBeSpecialSummoned, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, SUMMON_TYPE_SPECIAL, tp, true, false)
        and (ft > 0 or (ft == 0 and Duel.IsExistingMatchingCard(s.rfilter, tp, LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)))
    
    -- Condition 2: Meroron alone -> Cure Kiss
    local res2 = Duel.IsExistingMatchingCard(s.rfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
        and Duel.IsExistingMatchingCard(Card.IsCanBeSpecialSummoned, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, SUMMON_TYPE_SPECIAL, tp, true, false)
        and (ft > 0 or (ft == 0 and Duel.IsExistingMatchingCard(s.rfilter, tp, LOCATION_MZONE, 0, 1, nil, CARD_MERORON)))
        
    -- Condition 3: Both -> Both Cures
    local res3 = Duel.IsExistingMatchingCard(s.rfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
        and Duel.IsExistingMatchingCard(s.rfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
        and Duel.IsExistingMatchingCard(Card.IsCanBeSpecialSummoned, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, SUMMON_TYPE_SPECIAL, tp, true, false)
    
    -- Zone space check for double summon
    local zone_check = false
    if res3 then
        local m_count = 0
        if Duel.IsExistingMatchingCard(s.rfilter, tp, LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN) then m_count = m_count + 1 end
        if Duel.IsExistingMatchingCard(s.rfilter, tp, LOCATION_MZONE, 0, 1, nil, CARD_MERORON) then m_count = m_count + 1 end
        if ft + m_count >= 2 then zone_check = true end
    end

    if chk == 0 then return res1 or res2 or zone_check end

    -- Prompt player to select what they want to send
    local g = Group.CreateGroup()
    local opt = 0
    
    local can_p = res1
    local can_m = res2
    local can_both = zone_check
    
    -- Menu selection based on availability
    if can_p and can_m and can_both then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 1), aux.Stringid(id, 2)) -- 0: Purirun, 1: Meroron, 2: Both
    elseif can_p and can_m then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 1))
    elseif can_p and can_both then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 2))
        if opt == 1 then opt = 2 end
    elseif can_m and can_both then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 1), aux.Stringid(id, 2))
        opt = opt + 1
    elseif can_p then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 0))
    elseif can_m then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 1))
        opt = 1
    else
        opt = Duel.SelectOption(tp, aux.Stringid(id, 2))
        opt = 2
    end

    -- Perform the send to GY cost operation
    if opt == 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sg = Duel.SelectMatchingCard(tp, s.rfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_PURIRUN)
        Duel.SendtoGrave(sg, REASON_COST)
        e:SetLabel(1) -- Track choice: Purirun
    elseif opt == 1 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sg = Duel.SelectMatchingCard(tp, s.rfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_MERORON)
        Duel.SendtoGrave(sg, REASON_COST)
        e:SetLabel(2) -- Track choice: Meroron
    else
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sg1 = Duel.SelectMatchingCard(tp, s.rfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_PURIRUN)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sg2 = Duel.SelectMatchingCard(tp, s.rfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, sg1:GetFirst(), CARD_MERORON)
        sg1:Merge(sg2)
        Duel.SendtoGrave(sg1, REASON_COST)
        e:SetLabel(3) -- Track choice: Both
    end
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.spfilter(c, code, e, tp)
    return c:IsCode(code) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local label = e:GetLabel()
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if ft <= 0 and label ~= 3 then return end

    if label == 1 then
        -- Summon Cure Zukyoon
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, CARD_CURE_ZUKYOON, e, tp)
        if #g > 0 then
            Duel.SpecialSummon(g, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
        end
    elseif label == 2 then
        -- Summon Cure Kiss
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, CARD_CURE_KISS, e, tp)
        if #g > 0 then
            Duel.SpecialSummon(g, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
        end
    elseif label == 3 then
        -- Summon Both
        if ft < 2 then return end
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sc1 = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, CARD_CURE_ZUKYOON, e, tp):GetFirst()
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sc2 = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, sc1, CARD_CURE_KISS, e, tp):GetFirst()
        
        if sc1 and sc2 then
            Duel.SpecialSummonStep(sc1, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            Duel.SpecialSummonStep(sc2, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            Duel.SpecialSummonComplete()
        end
    end
end

-- GY Recovery Logic
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
