local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833



function s.initial_effect(c)
    -- Activate Spell: Send materials from Hand/Field -> Special Summon from Deck
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    
    -- Second Effect: If sent to GY by card effect, Set itself
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

-- Filter conditions for materials on Hand or Field
function s.matfilter(c)
    return (c:IsCode(CARD_PURIRUN) or c:IsCode(CARD_MERORON)) and c:IsAbleToGrave()
end

-- Check if specific monsters are available in the Deck to be Special Summoned
function s.spfilter(c, code, e, tp)
    return c:IsCode(code) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        local g = Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
        
        local has_purirun = g:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN)
        local has_meroron = g:IsExists(Card.IsCode, 1, nil, CARD_MERORON)
        
        local can_zukyoon = Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, CARD_CURE_ZUKYOON, e, tp)
        local can_kiss    = Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, CARD_CURE_KISS, e, tp)
        
        -- Check if at least one valid setup can be executed
        return (has_purirun and can_zukyoon and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0) or
               (has_meroron and can_kiss and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0) or
               (has_purirun and has_meroron and can_zukyoon and can_kiss and Duel.GetLocationCount(tp, LOCATION_MZONE) > 1)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_HAND + LOCATION_MZONE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
    
    local has_purirun = g:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN)
    local has_meroron = g:IsExists(Card.IsCode, 1, nil, CARD_MERORON)
    
    local can_zukyoon = Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, CARD_CURE_ZUKYOON, e, tp)
    local can_kiss    = Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, CARD_CURE_KISS, e, tp)
    
    -- Determine menu choices depending on what is currently valid
    local menu = {}
    local options = {}
    
    if has_purirun and can_zukyoon and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
        table.insert(menu, aux.Stringid(id, 2)) -- Option: Send Purirun -> Summon Cure Zukyoon
        table.insert(options, 1)
    end
    if has_meroron and can_kiss and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
        table.insert(menu, aux.Stringid(id, 3)) -- Option: Send Meroron -> Summon Cure Kiss
        table.insert(options, 2)
    end
    if has_purirun and has_meroron and can_zukyoon and can_kiss and Duel.GetLocationCount(tp, LOCATION_MZONE) > 1 then
        table.insert(menu, aux.Stringid(id, 4)) -- Option: Send Both -> Summon Both
        table.insert(options, 3)
    end
    
    if #options == 0 then return end
    local choice = options[Duel.SelectOption(tp, table.unpack(menu)) + 1]
    
    local mat_g = Group.CreateGroup()
    
    if choice == 1 then
        -- Select 1 Purirun
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sg = g:FilterSelect(tp, Card.IsCode, 1, 1, nil, CARD_PURIRUN)
        mat_g:Merge(sg)
    elseif choice == 2 then
        -- Select 1 Meroron
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sg = g:FilterSelect(tp, Card.IsCode, 1, 1, nil, CARD_MERORON)
        mat_g:Merge(sg)
    elseif choice == 3 then
        -- Select 1 Purirun and 1 Meroron
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sg1 = g:FilterSelect(tp, Card.IsCode, 1, 1, nil, CARD_PURIRUN)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sg2 = g:FilterSelect(tp, Card.IsCode, 1, 1, sg1:GetFirst(), CARD_MERORON)
        mat_g:Merge(sg1)
        mat_g:Merge(sg2)
    end
    
    -- Process sending materials and performing the Deck Summons
    if #mat_g > 0 and Duel.SendtoGrave(mat_g, REASON_EFFECT) > 0 then
        if choice == 1 or choice == 3 then
            local sc1 = Duel.GetFirstMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, nil, CARD_CURE_ZUKYOON, e, tp)
            if sc1 then Duel.SpecialSummonStep(sc1, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE) end
        end
        if choice == 2 or choice == 3 then
            local sc2 = Duel.GetFirstMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, nil, CARD_CURE_KISS, e, tp)
            if sc2 then Duel.SpecialSummonStep(sc2, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE) end
        end
        Duel.SpecialSummonComplete()
    end
end

-- E2: Set itself loop logic
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
