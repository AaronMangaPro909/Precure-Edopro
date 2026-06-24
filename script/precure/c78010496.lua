local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833


function s.initial_effect(c)
    -- Activate Spell: Send from Hand/Field to GY -> Special Summon from Hand/Deck
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

-- Filter for materials in Hand or Field
function s.matfilter(c)
    return (c:IsCode(CARD_PURIRUN) or c:IsCode(CARD_MERORON)) and c:IsAbleToGrave()
end

-- Check logic for Special Summons from Hand/Deck
function s.spfilter(c, e, tp, code)
    return c:IsCode(code) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false, POS_FACEUP)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        local mg = Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
        
        local has_purirun = mg:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN)
        local has_meroron = mg:IsExists(Card.IsCode, 1, nil, CARD_MERORON)
        
        local can_zukyoon = Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
        local can_kiss = Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
        
        -- Check if at least one valid individual or double summon path is open
        return (has_purirun and can_zukyoon and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0) or
               (has_meroron and can_kiss and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_HAND + LOCATION_MZONE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local mg = Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
    
    -- Figure out options based on what is dynamically available right now
    local can_zukyoon = Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
    local can_kiss = Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
    
    local has_purirun = mg:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN) and can_zukyoon and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
    local has_meroron = mg:IsExists(Card.IsCode, 1, nil, CARD_MERORON) and can_kiss and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
    local has_both = mg:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN) and mg:IsExists(Card.IsCode, 1, nil, CARD_MERORON) 
                     and can_zukyoon and can_kiss and Duel.GetLocationCount(tp, LOCATION_MZONE) > 1

    if not (has_purirun or has_meroron) then return end

    -- Prompt user to pick which combination they are sending
    local op = 0
    local options = {}
    local menu_map = {}
    
    if has_purirun then
        table.insert(options, aux.Stringid(id, 2)) -- "Send Purirun -> Summon Zukyoon"
        menu_map[#options] = 1
    end
    if has_meroron then
        table.insert(options, aux.Stringid(id, 3)) -- "Send Meroron -> Summon Kiss"
        menu_map[#options] = 2
    end
    if has_both then
        table.insert(options, aux.Stringid(id, 4)) -- "Send Both -> Summon Both"
        menu_map[#options] = 3
    end
    
    if #options == 0 then return end
    local choice = Duel.SelectOption(tp, table.unpack(options)) + 1
    op = menu_map[choice]

    local sg = Group.CreateGroup()
    
    -- Mode 1: Send Purirun -> Summon Zukyoon
    if op == 1 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g = mg:FilterSelect(tp, Card.IsCode, 1, 1, nil, CARD_PURIRUN)
        if #g > 0 and Duel.SendtoGrave(g, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local spg = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, CARD_CURE_ZUKYOON)
            if #spg > 0 then
                Duel.SpecialSummon(spg, SUMMON_TYPE_SPECIAL, tp, tp, true, false, POS_FACEUP)
            end
        end
        
    -- Mode 2: Send Meroron -> Summon Kiss
    elseif op == 2 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g = mg:FilterSelect(tp, Card.IsCode, 1, 1, nil, CARD_MERORON)
        if #g > 0 and Duel.SendtoGrave(g, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local spg = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, CARD_CURE_KISS)
            if #spg > 0 then
                Duel.SpecialSummon(spg, SUMMON_TYPE_SPECIAL, tp, tp, true, false, POS_FACEUP)
            end
        end
        
    -- Mode 3: Send Both -> Summon Both
    elseif op == 3 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g1 = mg:FilterSelect(tp, Card.IsCode, 1, 1, nil, CARD_PURIRUN)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g2 = mg:FilterSelect(tp, Card.IsCode, 1, 1, g1:GetFirst(), CARD_MERORON)
        g1:Merge(g2)
        
        if #g1 == 2 and Duel.SendtoGrave(g1, REASON_EFFECT) == 2 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc1 = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, CARD_CURE_ZUKYOON):GetFirst()
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc2 = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, sc1, e, tp, CARD_CURE_KISS):GetFirst()
            
            if sc1 and sc2 then
                Duel.SpecialSummonStep(sc1, SUMMON_TYPE_SPECIAL, tp, tp, true, false, POS_FACEUP)
                Duel.SpecialSummonStep(sc2, SUMMON_TYPE_SPECIAL, tp, tp, true, false, POS_FACEUP)
                Duel.SpecialSummonComplete()
            end
        end
    end
end

-- E2 Logic: Auto-Set condition
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
