-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Custom Card ID Configurations
local CARD_PURIRUN   = 41037083 -- !! CHANGE THIS !!
local CARD_MERORON   = 5826302 -- !! CHANGE THIS !!
local CARD_CURE_ZUKYOON   = 19379373 -- !! CHANGE THIS !!
local CARD_CURE_KISS      = 60519833 -- !! CHANGE THIS !!

function s.initial_effect(c)
    -- 1. Ignition Effect: Tribute Purirun/Meroron to Special Summon Cure Zukyoon/Cure Kiss
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE + LOCATION_HAND + LOCATION_SZONE) -- Adjust location if this is a Spell/Trap or Monster
    e3:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    -- 2. Trigger Effect: If this card is sent to the GY by a card effect
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCondition(s.gycon)
    e2:SetTarget(s.gytg)
    e2:SetOperation(s.gyop)
    c:RegisterEffect(e2)
end

-------------------------------------------------------------------------
-- 1. TRIBUTE & SUMMON ENGINE
-------------------------------------------------------------------------
function s.costfilter(c, tp)
    return (c:IsCode(CARD_PURIRUN) or c:IsCode(CARD_MERORON)) 
        and (c:IsControler(tp) or c:IsFaceup())
end
function s.spfilter(c, e, tp)
    return (c:IsCode(CARD_CURE_ZUKYOON) or c:IsCode(CARD_CURE_KISS))
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
    -- Check for tribute material from Hand or Field
    if chk == 0 then return Duel.CheckReleaseGroupCost(tp, s.costfilter, 1, false, nil, nil, tp) end
    local g = Duel.SelectReleaseGroupCost(tp, s.costfilter, 1, 1, false, nil, nil, tp)
    Duel.Release(g, REASON_COST)
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
-- 2. GY TRIGGERS (SENT BY CARD EFFECT)
-------------------------------------------------------------------------
function s.gycon(e, tp, eg, ep, ev, re, r, rp)
    -- Verifies it was sent to the GY by a card effect (either player's)
    return e:GetHandler():IsReason(REASON_EFFECT)
end
function s.gytg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    -- Insert secondary categories here if you add a specific effect payload later
end
function s.gyop(e, tp, eg, ep, ev, re, r, rp)
    -- Add the code here for what you want this card to do when sent to the GY!
    -- Example placeholder hint:
    Duel.Hint(HINT_CARD, 0, id)
end
