-- Cure Finale
local s, id = GetID()

function s.initial_effect(c)
    
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.hspcon)
    e1:SetTarget(s.hsptg)
    e1:SetOperation(s.hspop)
    c:RegisterEffect(e1)
    
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    e2:SetCountLimit (1)
    c:RegisterEffect(e2)
    
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetCondition(s.thcon)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

function s.hspcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, c)
end
function s.hsptg(e, tp, eg, ep, ev, re, r, rp, chk, c)
    local g = Duel.GetMatchingGroup(Card.IsDiscardable, tp, LOCATION_HAND, 0, c)
    if #g > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISCARD)
        local sg = g:Select(tp, 1, 1, nil)
        if #sg > 0 then
            sg:KeepAlive()
            e:SetLabelObject(sg)
            return true
        end
    end
    return false
end
function s.hspop(e, tp, eg, ep, ev, re, r, rp, c)
    local sg = e:GetLabelObject()
    if not sg then return end
    Duel.SendtoGrave(sg, REASON_COST + REASON_DISCARD)
    sg:DeleteGroup()
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    return re:IsActiveType(TYPE_MONSTER)
end
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
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end

function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return c:IsReason(REASON_DESTROY) and c:IsPreviousControler(tp)
end
function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsAbleToHand()
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end
    Duel.SendtoGrave(sg, REASON_COST + REASON_DISCARD)
    sg:DeleteGroup()
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    return re:IsActiveType(TYPE_MONSTER)
end
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
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end

function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return c:IsReason(REASON_DESTROY) and c:IsPreviousControler(tp)
end
function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsAbleToHand()
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end
