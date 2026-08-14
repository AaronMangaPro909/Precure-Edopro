--Flora Future Formation
local s, id = GetID ()
function s.initial_effect (c)

local e1 = Effect.CreateEffect (c)
e1:SetDescription(aux.Stringid(id, 0))
e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
e1:SetType(EFFECT_TYPE_ACTIVATE)
e1:SetCode(EVENT_FREE_CHAIN)
e1:SetHintTiming(TIMING_END_PHASE)
e1:SetCountLimit(1, id)
e1:SetCondition(s.spcon)
e1:SetTarget(s.sptg)
e1:SetOperation(s.spop)
c:RegisterEffect(e1)
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
return Duel.GetTurnPlayer() ~= tp and Duel.GetCurrentPhase() == PHASE_END
end

function s.spfilter(c, e, tp)
    return c:IsCode(65935871) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
if chk == 0 then
local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
if ft <= 0 then return false end
return Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil, e, tp)
end
Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
if ft <= 0 then return end
local ct = math.min(ft, 3)
Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spfilter), tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, ct, nil, e, tp)
if #g > 0 then
Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
end
end