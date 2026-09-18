-- Wonderful Pact
--ワンダフルパクト
-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card IDs
local CARD_CURE_FRIENDY   = 11111111 -- !! CHANGE THIS !! Replace with Cure Friendy's ID
local CARD_KOMUGI         = 36955586 -- !! CHANGE THIS !! Replace with Komugi's ID
local CARD_CURE_WONDERFUL  = 62718084 -- !! CHANGE THIS !! Replace with Cure Wonderful's ID

function s.initial_effect(c)
    -- Quick-Play Spell Activation
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0, TIMING_MAIN_END + TIMING_BATTLE_START)
    e1:SetCountLimit(1, id, EFFECT_COUNT_LIMIT_OATH)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-------------------------------------------------------------------------
-- ACTIVATION COST & ELIGIBILITY CHECKS
-------------------------------------------------------------------------
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.CheckLPCost(tp, 500) end
    Duel.PayLPCost(tp, 500)
end

-- Filter check for Option 1: Special Summon Cure Friendy from Hand, Deck, or GY
function s.spfilter1(c, e, tp)
    return c:IsCode(CARD_CURE_FRIENDY) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

-- Filter check for Option 2: Send 1 "Komugi" as Tribute to Summon Cure Wonderful
function s.tgfilter2(c)
    return c:IsCode(CARD_KOMUGI) and c:IsReleasable()
end
function s.spfilter2(c, e, tp)
    return c:IsCode(CARD_CURE_WONDERFUL) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    -- Check execution branches assuming an unselected check state
    local b1 = Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 
        and Duel.IsExistingMatchingCard(s.spfilter1, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil, e, tp)
        
    local b2 = Duel.IsExistingMatchingCard(s.tgfilter2, tp, LOCATION_MZONE + LOCATION_HAND, 0, 1, nil)
        and Duel.IsExistingMatchingCard(s.spfilter2, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp)
        
    if chk == 0 then return b1 or b2 end
    
    -- Dynamically prompt choices based on current board legalities
    local opt = 0
    if b1 and b2 then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 1))
    elseif b1 then
        opt = Duel.SelectOption(tp, aux.Stringid(id, 0))
    else
        opt = Duel.SelectOption(tp, aux.Stringid(id, 1)) + 1
    end
    
    e:SetLabel(opt)
    if opt == 0 then
        e:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_ATKCHANGE)
        Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE)
    else
        e:SetCategory(CATEGORY_RELEASE + CATEGORY_SPECIAL_SUMMON)
        local rg = Duel.GetMatchingGroup(s.tgfilter2, tp, LOCATION_MZONE + LOCATION_HAND, 0, nil)
        Duel.SetOperationInfo(0, CATEGORY_RELEASE, rg, 1, 0, 0)
        Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
    end
end

-------------------------------------------------------------------------
-- RESOLUTION EXECUTION ENGINE
-------------------------------------------------------------------------
function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local opt = e:GetLabel()
    
    -- ● OPTION 1: Special Summon Cure Friendy, then add 500 ATK
    if opt == 0 then
        if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spfilter1), tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
        local tc = g:GetFirst()
        if tc and Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP) ~= 0 then
            -- Apply continuous/permanent +500 ATK modification
            local e1 = Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(500)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e1)
        end
        
    -- ● OPTION 2: Tribute 1 "Komugi" to Special Summon 1 "Cure Wonderful"
    elseif opt == 1 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RELEASE)
        local rg = Duel.SelectMatchingCard(tp, s.tgfilter2, tp, LOCATION_MZONE + LOCATION_HAND, 0, 1, 1, nil)
        if #rg > 0 and Duel.Release(rg, REASON_EFFECT) ~= 0 then
            -- Zone validation step handled post-tribute context
            if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sg = Duel.SelectMatchingCard(tp, s.spfilter2, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp)
            if #sg > 0 then
                Duel.SpecialSummon(sg, 0, tp, tp, false, false, POS_FACEUP)
            end
        end
    end
end
