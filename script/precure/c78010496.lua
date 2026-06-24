local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833

function s.initial_effect(c)
    -- Activate Effect
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

-- Filter check for materials (Hand and Field allowed)
function s.matfilter(c, code)
    return c:IsCode(code) and c:IsAbleToGrave()
end

-- Checks if a specific target boss can be Special Summoned
function s.spfilter(c, e, tp, code)
    return c:IsCode(code) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
        if ft < 0 then return false end
        
        -- Option 1: Just Purirun -> Cure Zukyoon
        local opt1 = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
            and ft > 0
            
        -- Option 2: Just Meroron -> Cure Kiss
        local opt2 = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
            and ft > 0
            
        -- Option 3: Both Purirun and Meroron -> Both Bosses
        local opt3 = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
            and Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
            and (ft > 1 or (ft > 0 and Duel.GetUseableCountByRule ~= nil)) -- standard zone buffer check
            
        return opt1 or opt2 or opt3
    end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_HAND + LOCATION_MZONE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if ft <= 0 then return end

    -- Determine valid options for execution dynamically
    local opt1 = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
    local opt2 = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
    local opt3 = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
        and Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
        and ft >= 2

    -- Prompt user choices via selection menu
    local ops = {}
    local select_map = {}
    if opt1 then table.insert(ops, aux.Stringid(id, 2)) select_map[#ops] = 1 end -- Send Purirun -> Summon Zukyoon
    if opt2 then table.insert(ops, aux.Stringid(id, 3)) select_map[#ops] = 2 end -- Send Meroron -> Summon Kiss
    if opt3 then table.insert(ops, aux.Stringid(id, 4)) select_map[#ops] = 3 end -- Send Both -> Summon Both
    
    if #ops == 0 then return end
    local sel = select_map[Duel.SelectOption(tp, unpack(ops)) + 1]

    -- Execution of paths based on selection choice
    if sel == 1 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local mat = Duel.SelectMatchingCard(tp, s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_PURIRUN)
        if #mat > 0 and Duel.SendtoGrave(mat, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local spc = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, CARD_CURE_ZUKYOON):GetFirst()
            if spc then Duel.SpecialSummon(spc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE) end
        end
    elseif sel == 2 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local mat = Duel.SelectMatchingCard(tp, s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_MERORON)
        if #mat > 0 and Duel.SendtoGrave(mat, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local spc = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, CARD_CURE_KISS):GetFirst()
            if spc then Duel.SpecialSummon(spc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE) end
        end
    elseif sel == 3 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local mat1 = Duel.SelectMatchingCard(tp, s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_PURIRUN)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local mat2 = Duel.SelectMatchingCard(tp, s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_MERORON)
        mat1:Merge(mat2)
        if #mat1 == 2 and Duel.SendtoGrave(mat1, REASON_EFFECT) == 2 then
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

-- E2 Logic
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
