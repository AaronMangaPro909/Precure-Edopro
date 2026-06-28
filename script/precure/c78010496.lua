-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Custom Card ID Configurations
local CARD_PURIRUN   = 41037083 -- !! CHANGE THIS !!
local CARD_MERORON   = 5826302 -- !! CHANGE THIS !!
local CARD_CURE_ZUKYOON   = 19379373 -- !! CHANGE THIS !!
local CARD_CURE_KISS      = 60519833 -- !! CHANGE THIS !!


function s.initial_effect(c)
    -- Ignition Effect (Activated from your field, e.g., on a Monster, Continuous Spell, etc.)
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE) -- Change to LOCATION_SZONE if this is a Continuous Spell/Trap
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
end

-------------------------------------------------------------------------
-- COST FILTER & VALIDATION ENGINE
-------------------------------------------------------------------------
function s.costfilter(c, tp)
    -- Can tribute Purirun or Meroron from hand or field
    return (c:IsCode(CARD_PURIRUN) or c:IsCode(CARD_MERORON)) 
        and (c:IsControler(tp) or c:IsFaceup())
end

function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
    -- Account for the zone being freed if the monster tributed is on the field
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if chk == 0 then 
        return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil, tp) 
    end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RELEASE)
    local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil, tp)
    
    -- Check if the tributed card was on the field to dynamically track zone availability
    if g:GetFirst():IsLocation(LOCATION_MZONE) then 
        e:SetLabel(1) 
    else 
        e:SetLabel(0) 
    end
    
    Duel.Release(g, REASON_COST)
end

-------------------------------------------------------------------------
-- TARGET & SUMMON FILTER ENGINE
-------------------------------------------------------------------------
function s.spfilter(c, e, tp)
    -- Target either Cure Zukyoon or Cure Kiss
    return (c:IsCode(CARD_CURE_ZUKYOON) or c:IsCode(CARD_CURE_KISS))
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    -- Adjust required zone count based on whether a field zone was cleared in the cost step
    local check_field = e:GetLabel()
    local zone_modifier = 0
    if check_field == 1 then zone_modifier = 1 end
    
    if chk == 0 then 
        -- Reset label to avoid safety leaks during nested check iterations
        e:SetLabel(0)
        return (Duel.GetLocationCount(tp, LOCATION_MZONE) + zone_modifier) > 0
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp)
    end
    
    e:SetLabel(0) -- Flush variable
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

-------------------------------------------------------------------------
-- EXECUTION OPERATION BLOCK
-------------------------------------------------------------------------
function s.spop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end
