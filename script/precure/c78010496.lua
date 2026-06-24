local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833


function s.initial_effect(c)
    -- Activate: Send combination of Purirun/Meroron -> Special Summon matching Cures
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

-- Filter to find either Purirun or Meroron on Hand or Field
function s.matfilter(c)
    return (c:IsCode(CARD_PURIRUN) or c:IsCode(CARD_MERORON)) and c:IsAbleToGrave()
end

-- Filter to check if the specific Cure can be Special Summoned safely bypassing its summon condition
function s.spfilter(c, e, tp, code)
    return c:IsCode(code) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        local mg = Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
        return mg:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN) and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
            or mg:IsExists(Card.IsCode, 1, nil, CARD_MERORON) and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_HAND + LOCATION_MZONE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local mg = Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
    
    -- Dynamically check which combinations are valid based on your current hand/deck targets
    local can_p = mg:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN) and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
    local can_m = mg:IsExists(Card.IsCode, 1, nil, CARD_MERORON) and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
    local can_both = mg:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN) and mg:IsExists(Card.IsCode, 1, nil, CARD_MERORON) 
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
        and Duel.GetLocationCount(tp, LOCATION_MZONE) > 1

    if not (can_p or can_m) then return end

    -- Present selection menus to the player based on what materials they actually have
    local opt = 0
    if can_both then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 2), aux.Stringid(id, 3), aux.Stringid(id, 4)) -- 0: Purirun Only, 1: Meroron Only, 2: Both
    elseif can_p and not can_m then
        opt = 0
    elseif can_m and not can_p then
        opt = 1
    else
        opt = Duel.SelectOption(tp, aux.Stringid(id, 2), aux.Stringid(id, 3)) -- Choice between either singular option
    end

    local sg = Group.CreateGroup()
    local sp_zukyoon = false
    local sp_kiss = false

    -- Option Processing Execution
    if opt == 0 or opt == 2 then -- Needs Purirun
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g = mg:FilterSelect(tp, Card.IsCode, 1, 1, nil, CARD_PURIRUN)
        sg:Merge(g)
        sp_zukyoon = true
    end
    if opt == 1 or opt == 2 then -- Needs Meroron
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g = mg:FilterSelect(tp, Card.IsCode, 1, 1, sg:GetFirst(), CARD_MERORON) -- Don't re-select same card if handling multi-identity rule properties
        sg:Merge(g)
        sp_kiss = true
    end

    if #sg > 0 and Duel.SendtoGrave(sg, REASON_EFFECT) > 0 then
        if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
        
        -- Handle Special Summoning from Hand or Deck safely bypassing conditions
        if sp_zukyoon then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local tc1 = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, CARD_CURE_ZUKYOON):GetFirst()
            if tc1 then Duel.SpecialSummonStep(tc1, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE) end
        end
        
        if sp_kiss and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local tc2 = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, CARD_CURE_KISS):GetFirst()
            if tc2 then Duel.SpecialSummonStep(tc2, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE) end
        end
        
        Duel.SpecialSummonComplete()
    end
end

-- E2 Set Logic
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
