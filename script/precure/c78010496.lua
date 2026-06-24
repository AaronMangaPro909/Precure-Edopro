local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833

function s.initial_effect(c)
    -- Activate: Send from Hand/Field -> Special Summon corresponding Cure monster(s)
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

-- Filters to verify cards can be sent to GY from Hand or Field
function s.tgfilter(c)
    return (c:IsCode(CARD_PURIRUN) or c:IsCode(CARD_MERORON)) 
        and c:IsAbleToGrave() and (c:IsLocation(LOCATION_HAND) or c:IsFaceup())
end

-- Filters to check if the specific Cure monsters can be summoned
function s.spfilter_zukyoon(e, tp)
    return Duel.IsExistingMatchingCard(Card.IsCanBeSpecialSummoned, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, SUMMON_TYPE_SPECIAL, tp, true, false, POS_FACEUP)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        -- Must have at least 1 valid monster to send and room to summon
        if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return false end
        return Duel.IsExistingMatchingCard(s.tgfilter, tp, LOCATION_HAND + LOCATION_FIELD, 0, 1, nil)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_HAND + LOCATION_FIELD)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(s.tgfilter, tp, LOCATION_HAND + LOCATION_FIELD, 0, nil)
    if #g == 0 then return end
    
    -- Let player select the combination from hand or field
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local sg = g:SelectCancel(tp, 1, 2, nil)
    if #sg == 0 then return end
    
    -- Determine what was selected based on card codes
    local has_purirun = sg:IsExists(Card.IsCode, 1, nil, CARD_PURIRUN)
    local has_meroron = sg:IsExists(Card.IsCode, 1, nil, CARD_MERORON)
    
    -- Send selected cards to GY
    if Duel.SendtoGrave(sg, REASON_EFFECT) > 0 then
        local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
        if ft <= 0 then return end
        
        -- Case 1: Both Purirun and Meroron selected
        if has_purirun and has_meroron and ft >= 2 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local zc = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, CARD_CURE_ZUKYOON):GetFirst()
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local kc = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, zc, CARD_CURE_KISS):GetFirst()
            
            if zc and kc then
                Duel.SpecialSummonStep(zc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonStep(kc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonComplete()
            end
            
        -- Case 2: Purirun alone selected -> Summon Cure Zukyoon
        elseif has_purirun and not has_meroron then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local zc = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, CARD_CURE_ZUKYOON):GetFirst()
            if zc then
                Duel.SpecialSummon(zc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
            
        -- Case 3: Meroron alone selected -> Summon Cure Kiss
        elseif has_meroron and not has_purirun then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local kc = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, CARD_CURE_KISS):GetFirst()
            if kc then
                Duel.SpecialSummon(kc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
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
