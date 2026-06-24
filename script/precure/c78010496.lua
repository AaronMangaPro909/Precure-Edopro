local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833


function s.initial_effect(c)
    -- Activate: Send from hand/field -> Special Summon from Hand/Deck
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
    return c:IsCode(code) and c:IsAbleToGrave()
end

-- Summon Filters (Hand or Deck only, NO GY)
function s.spfilter(c, e, tp, code)
    return c:IsCode(code) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false, POS_FACEUP, tp, LOCATION_HAND + LOCATION_DECK)
end

-- Condition Checks for each option
function s.checkZukyoon(e, tp)
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
end

function s.checkKiss(e, tp)
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
end

function s.checkBoth(e, tp)
    -- If using from hand, needs 2 zones. If using from field, zone counts dynamically adapt.
    if Duel.IsPlayerAffectedByEffect(tp, CARD_AURA_WHIRLWIND) then return false end -- Safety check for zone locking
    
    local hand_purirun = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND, 0, 1, nil, CARD_PURIRUN)
    local field_purirun = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN)
    local hand_meroron = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_HAND, 0, 1, nil, CARD_MERORON)
    local field_meroron = Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_MZONE, 0, 1, nil, CARD_MERORON)
    
    -- Needs at least 1 of each material
    local has_mats = (hand_purirun or field_purirun) and (hand_meroron or field_meroron)
    if not has_mats then return false end
    
    -- Standard verification for 2 open zones
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if field_purirun then ft = ft + 1 end
    if field_meroron then ft = ft + 1 end
    if Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_MZONE, 0, 1, nil, CARD_PURIRUN) 
       and Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_MZONE, 0, 1, nil, CARD_MERORON) then
       ft = Duel.GetLocationCount(tp, LOCATION_MZONE) + 2
    end

    return ft >= 2 
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return s.checkZukyoon(e, tp) or s.checkKiss(e, tp) or s.checkBoth(e, tp)
    end
    
    -- Multi-option menu determination
    local b1 = s.checkZukyoon(e, tp)
    local b2 = s.checkKiss(e, tp)
    local b3 = s.checkBoth(e, tp)
    
    local op = Duel.SelectEffect(tp,
        {b1, aux.Stringid(id, 0)}, -- "Summon Cure Zukyoon"
        {b2, aux.Stringid(id, 1)}, -- "Summon Cure Kiss"
        {b3, aux.Stringid(id, 2)}) -- "Summon Both"
        
    e:SetLabel(op)
    
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, (op == 3 and 2 or 1), tp, LOCATION_HAND + LOCATION_MZONE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, (op == 3 and 2 or 1), tp, LOCATION_HAND + LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local op = e:GetLabel()
    
    if op == 1 then -- Summon Cure Zukyoon alone
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g = Duel.SelectMatchingCard(tp, s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_PURIRUN)
        if #g > 0 and Duel.SendtoGrave(g, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, CARD_CURE_ZUKYOON):GetFirst()
            if sc then
                Duel.SpecialSummon(sc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, POS_FACEUP)
            end
        end
        
    elseif op == 2 then -- Summon Cure Kiss alone
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g = Duel.SelectMatchingCard(tp, s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_MERORON)
        if #g > 0 and Duel.SendtoGrave(g, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, CARD_CURE_KISS):GetFirst()
            if sc then
                Duel.SpecialSummon(sc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, POS_FACEUP)
            end
        end
        
    elseif op == 3 then -- Summon Both
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g1 = Duel.SelectMatchingCard(tp, s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, CARD_PURIRUN)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local g2 = Duel.SelectMatchingCard(tp, s.matfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, g1:GetFirst(), CARD_MERORON)
        g1:Merge(g2)
        
        if #g1 == 2 and Duel.SendtoGrave(g1, REASON_EFFECT) == 2 then
            if Duel.GetLocationCount(tp, LOCATION_MZONE) < 2 then return end
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

-- Recycling Loop Logic
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
