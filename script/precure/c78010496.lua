-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Custom Card ID Configurations
local CARD_PURIRUN   = 41037083 -- !! CHANGE THIS !!
local CARD_MERORON   = 5826302 -- !! CHANGE THIS !!
local CARD_ZUKYOON   = 19379373 -- !! CHANGE THIS !!
local CARD_KISS      = 60519833 -- !! CHANGE THIS !!

function s.initial_effect(c)
    -- 1. Ignition/Spell Effect: Tribute 1 Purirun/Meroron to Special Summon Zukyoon/Kiss from Hand or Deck
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE + LOCATION_SZONE) -- Operates on field as monster or face-up Continuous card
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    -- 2. Trigger Effect: If sent to the GY by card effect, place itself face-up in S/T Zone
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1, id) -- Once per turn
    e2:SetCondition(s.stcon)
    e2:SetTarget(s.sttg)
    e2:SetOperation(s.stop)
    c:RegisterEffect(e2)
end

-------------------------------------------------------------------------
-- 1. SUMMON ENGINE: PURIRUN/MERORON -> ZUKYOON/KISS
-------------------------------------------------------------------------
function s.costfilter(c)
    return (c:IsCode(CARD_PURIRUN) or c:IsCode(CARD_MERORON)) and c:IsReleasable()
end
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    -- Check hand or field for tribute targets
    if chk == 0 then return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, c) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RELEASE)
    local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, c)
    Duel.Release(g, REASON_COST)
end
function s.spfilter(c, e, tp)
    return (c:IsCode(CARD_ZUKYOON) or c:IsCode(CARD_KISS)) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end

-------------------------------------------------------------------------
-- 2. PLACEMENT ENGINE (SENT TO GY BY EFFECT -> S/T ZONE)
-------------------------------------------------------------------------
function s.stcon(e, tp, eg, ep, ev, re, r, rp)
    -- Verifies it was sent to the GY specifically by a card effect execution
    return e:GetHandler():IsReason(REASON_EFFECT)
end
function s.sttg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0 end
    Duel.SetOperationInfo(0, CATEGORY_LEAVE_GRAVE, e:GetHandler(), 1, 0, 0)
end
function s.stop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 or not c:IsRelateToEffect(e) then return end
    
    -- Place face-up into the Spell & Trap Zone
    if Duel.MoveToField(c, tp, tp, LOCATION_SZONE, POS_FACEUP, true) then
        -- Apply continuous type rules properties so it functions properly as a legal card on field
        local e1 = Effect.CreateEffect(c)
        e1:SetCode(EFFECT_CHANGE_TYPE)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TOFIELD)
        c:RegisterEffect(e1)
    end
end
