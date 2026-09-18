local s, id = GetID()

function s.initial_effect(c)
    -- 1. Special Summon from hand by returning 1 "Precure" monster to hand
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1, id)
    e1:SetCondition(s.sprcon)
    e1:SetTarget(s.sprtg)
    e1:SetOperation(s.sprop)
    c:RegisterEffect(e1)
    
    -- 2. On Normal/Special Summon: Special Summon 1 "Precure" from Deck (Effects Negated)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1, id + 100)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
    local e3 = e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)
    
    -- 3. If sent to GY as Link Material: Fusion Summon by banishing materials from Hand/Field/GY
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_FUSION_SUMMON + CATEGORY_REMOVE)
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_BE_MATERIAL)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCountLimit(1, id + 200)
    e4:SetCondition(s.fuscon)
    e4:SetTarget(s.fustg)
    e4:SetOperation(s.fusop)
    c:RegisterEffect(e4)
end

-- 1. Return to hand Special Summon Logic
function s.sprfilter(c, tp)
    return c:IsFaceup() and c:IsSetCard(0xb54) and c:IsAbleToHandAsCost()
        and Duel.GetMZoneCount(tp, c) > 0
end
function s.sprcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.IsExistingMatchingCard(s.sprfilter, tp, LOCATION_MZONE, 0, 1, nil, tp)
end
function s.sprtg(e, tp, eg, ep, ev, re, r, rp, c)
    local g = Duel.GetMatchingGroup(s.sprfilter, tp, LOCATION_MZONE, 0, nil, tp)
    local sg = aux.SelectUnselectGroup(g, e, tp, 1, 1, nil, 1, tp, HINTMSG_RTOHAND, nil, nil, true)
    if #sg > 0 then
        sg:KeepAlive()
        e:SetLabelObject(sg)
        return true
    end
    return false
end
function s.sprop(e, tp, eg, ep, ev, re, r, rp, c)
    local sg = e:GetLabelObject()
    if not sg then return end
    Duel.SendtoHand(sg, nil, REASON_COST)
    -- Fixed: The explicit sg:Delete() call is completely removed here to prevent the crash
end

-- 2. Summon from Deck Logic
function s.spfilter(c, e, tp)
    return c:IsSetCard(0xb54) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_DECK, 0, 1, 1, nil, e, tp)
    local tc = g:GetFirst()
    if tc and Duel.SpecialSummon(tc, 0, tp, tp, false, false, LOCATION_MZONE) > 0 then
        -- Negate its effects
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2 = e1:Clone()
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        tc:RegisterEffect(e2)
    end
end

-- 3. Link Material into Fusion Logic
function s.fuscon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsLocation(LOCATION_GRAVE) and r == REASON_LINK
end
function s.ffilter(c)
    return c:IsSetCard(0xb54) and c:IsType(TYPE_FUSION)
end
function s.fustg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        local params = {helper = nil, ffilter = s.ffilter, stage2 = nil, extracon = nil, extramat = Fusion.IsMonsterFilter(Card.IsAbleToRemove), extrawanted = nil, chkf = FUSPROC_NOTHEATER}
        return Fusion.SummonEffTg(params)(e, tp, eg, ep, ev, re, r, rp, chk)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, tp, LOCATION_HAND + LOCATION_ONFIELD + LOCATION_GRAVE)
end
function s.fusop(e, tp, eg, ep, ev, re, r, rp)
    -- Fusion Summon parameters targeting Precure (0xb54) Fusion pool by banishing materials
    local params = {helper = nil, ffilter = s.ffilter, stage2 = nil, extracon = nil, extramat = Fusion.IsMonsterFilter(Card.IsAbleToRemove), extrawanted = nil, sumpos = SUMMON_TYPE_FUSION, chkf = FUSPROC_NOTHEATER}
    Fusion.SummonEffOp(params)(e, tp, eg, ep, ev, re, r, rp)
end
