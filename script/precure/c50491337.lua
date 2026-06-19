--Precure of Princess: Cure Scarlet Mode Elegant

local s, id = GetID()

-- Card IDs
local CARD_SCARLET = 3325364110

function s.initial_effect(c)

    c:EnableReviveLimit()
    Link.AddProcedure(c, s.matfilter, 3, 3)
    
    c:EnableUnsummonable()
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(s.splimit)
    c:RegisterEffect(e0)

    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_CHANGE_CODE)
    e1:SetValue(CARD_SCARLET)
    c:RegisterEffect(e1)
    
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCondition(s.excon)
    e2:SetTarget(s.sptg1)
    e2:SetOperation(s.spop1)
    c:RegisterEffect(e2)
 
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_DESTROYED)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    local PARAM_LOC = LOCATION_GRAVE
    e3:SetTarget(s.sptg2)
    e3:SetOperation(s.spop2)
    c:RegisterEffect(e3)
end

function s.matfilter(c, lc, sumtype, tp)
    if c:IsCode(CARD_SCARLET) then return true end
    return c:IsAttribute(ATTRIBUTE_FIRE, lc, sumtype, tp)
end

function s.splimit(e, se, sp, st)
    return se ~= nil
end

function s.excon(e)
    return e:GetHandler():IsSummonLocation(LOCATION_EXTRA)
end

function s.spfilter1(c, e, tp)
    return c:IsSetCard(0xb54) and c:IsType(TYPE_LINK) and c:GetLink() == 3
        and c:IsCanBeSpecialSummoned(e, 0, tp, true, false)
end
function s.sptg1(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.spfilter1, tp, LOCATION_GRAVE, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE)
end
function s.spop1(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local tc = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spfilter1), tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp):GetFirst()
    if tc and Duel.SpecialSummonStep(tc, 0, tp, tp, true, false, LOCATION_MZONE) then
        -- Negate its effects
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2 = e1:Clone()
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        tc:RegisterEffect(e2)
        Duel.SpecialSummonComplete()
    end
end

function s.spfilter2(c, e, tp)
    return c:IsCode(CARD_SCARLET) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.sptg2(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.spfilter2, tp, LOCATION_GRAVE, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE)
end
function s.spop2(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spfilter2), tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, LOCATION_MZONE)
    end
end
