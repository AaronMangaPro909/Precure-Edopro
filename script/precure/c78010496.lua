local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833


function s.initial_effect(c)
    -- Activate: Send Purirun and/or Meroron to GY -> Special Summon from Deck
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

-- Filter checks for materials in Hand/Field
function s.matfilter(c, code)
    return c:IsCode(code) and c:IsAbleToGraveAsCost()
end

-- Filter checks for Summons strictly inside the DECK
function s.spfilter(c, e, tp, code)
    return c:IsCode(code) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false, POS_FACEUP, tp, LOCATION_DECK)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    local loc = LOCATION_HAND + LOCATION_MZONE
    
    -- Check individual valid combinations based on what is in Hand/Field vs what is in Deck
    local can_zukyoon = Duel.IsExistingMatchingCard(s.matfilter, tp, loc, 0, 1, nil, CARD_PURIRUN)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
        and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        
    local can_kiss = Duel.IsExistingMatchingCard(s.matfilter, tp, loc, 0, 1, nil, CARD_MERORON)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
        and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        
    local can_both = Duel.IsExistingMatchingCard(s.matfilter, tp, loc, 0, 1, nil, CARD_PURIRUN)
        and Duel.IsExistingMatchingCard(s.matfilter, tp, loc, 0, 1, nil, CARD_MERORON)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_ZUKYOON)
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp, CARD_CURE_KISS)
        and Duel.GetLocationCount(tp, LOCATION_MZONE) > 1

    if chk == 0 then return can_zukyoon or can_kiss or can_both end

    -- Prompt the player to select which mode they are activating
    local op = 0
    local options = {}
    if can_zukyoon then table.insert(options, aux.Stringid(id, 0)) end -- "Send Purirun -> Summon Zukyoon"
    if can_kiss then table.insert(options, aux.Stringid(id, 1)) end    -- "Send Meroron -> Summon Kiss"
    if can_both then table.insert(options, aux.Stringid(id, 2)) end    -- "Send Both -> Summon Both"
    
    local choice = Duel.SelectOption(tp, table.unpack(options))
    local selected_text = options[choice + 1]
    
    local tg_g = Group.CreateGroup()
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    
    if selected_text == aux.Stringid(id, 0) then
        op = 1
        local g = Duel.SelectMatchingCard(tp, s.matfilter, tp, loc, 0, 1, 1, nil, CARD_PURIRUN)
        tg_g:Merge(g)
    elseif selected_text == aux.Stringid(id, 1) then
        op = 2
        local g = Duel.SelectMatchingCard(tp, s.matfilter, tp, loc, 0, 1, 1, nil, CARD_MERORON)
        tg_g:Merge(g)
    local e1 = Effect.CreateEffect(e:GetHandler())
    else
        op = 3
        local g1 = Duel.SelectMatchingCard(tp, s.matfilter, tp, loc, 0, 1, 1, nil, CARD_PURIRUN)
        local g2 = Duel.SelectMatchingCard(tp, s.matfilter, tp, loc, 0, 1, 1, nil, CARD_MERORON)
        tg_g:Merge(g1)
        tg_g:Merge(g2)
    end
    
    -- Send materials to GY as Cost
    Duel.SendtoGrave(tg_g, REASON_COST)
    e:SetLabel(op)
    
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, (op == 3 and 2 or 1), tp, LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local op = e:GetLabel()
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if ft <= 0 then return end

    if op == 1 then
        -- Summon Cure Zukyoon
        local tc = Duel.GetFirstMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, nil, e, tp, CARD_CURE_ZUKYOON)
        if tc then
            Duel.SpecialSummon(tc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, POS_FACEUP)
        end
    elseif op == 2 then
        -- Summon Cure Kiss
        local tc = Duel.GetFirstMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, nil, e, tp, CARD_CURE_KISS)
        if tc then
            Duel.SpecialSummon(tc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, POS_FACEUP)
        end
    elseif op == 3 then
        -- Summon Both (Requires 2 open spaces)
        if ft < 2 then return end
        local tc1 = Duel.GetFirstMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, nil, e, tp, CARD_CURE_ZUKYOON)
        local tc2 = Duel.GetFirstMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, nil, e, tp, CARD_CURE_KISS)
        if tc1 and tc2 then
            Duel.SpecialSummonStep(tc1, SUMMON_TYPE_SPECIAL, tp, tp, true, false, POS_FACEUP)
            Duel.SpecialSummonStep(tc2, SUMMON_TYPE_SPECIAL, tp, tp, true, false, POS_FACEUP)
            Duel.SpecialSummonComplete()
        end
    end
end

-- E2 Logic: Auto Set from GY
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
