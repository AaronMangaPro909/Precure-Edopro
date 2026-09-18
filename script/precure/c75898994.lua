-- Ultimate Leader Cures
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    Fusion.AddProcMix(c, true, true, s.matfilter1, aux.FilterBoolFunction(Card.IsType, TYPE_EFFECT), aux.FilterBoolFunction(Card.IsType, TYPE_EFFECT))

    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_TODECK + CATEGORY_TOHAND + CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.shufcon)
    e1:SetTarget(s.shuftg)
    e1:SetOperation(s.shufop)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetTarget(s.extg)
    e2:SetOperation(s.exop)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_PIERCE)
    c:RegisterEffect(e3)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 3))
    e5:SetCategory(CATEGORY_REMOVE + CATEGORY_SPECIAL_SUMMON)
    e5:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e5:SetCode(EVENT_BATTLE_DESTROYING)
    e5:SetCondition(aux.bdogcon)
    e5:SetTarget(s.banrstg)
    e5:SetOperation(s.banrsop)
    c:RegisterEffect(e5)
end

s.darkness_archetype = 0xb54 -- Precure Archetype
function s.matfilter1(c, fc, st, tp)
    return c:IsSetCard(0xb54) and c:IsType(TYPE_MONSTER, fc, st, tp)
end

function s.shufcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.shuffilter(c)
    return c:IsSetCard(0xb54) and c:IsAbleToDeck()
end

function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsAbleToHand()
end

function s.shuftg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsExistingMatchingCard(s.shuffilter, tp, LOCATION_REMOVED, 0, 1, nil)
            and Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil)
    end
    local g = Duel.GetMatchingGroup(s.shuffilter, tp, LOCATION_REMOVED, 0, nil)
    Duel.SetOperationInfo(0, CATEGORY_TODECK, g, #g, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.shufop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(s.shuffilter, tp, LOCATION_REMOVED, 0, nil)
    if #g > 0 and Duel.SendToDeck(g, nil, SEQ_DECKSHUFFLE, REASON_EFFECT) > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
        local sg = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
        if #sg > 0 then
            Duel.SendtoHand(sg, nil, REASON_EFFECT)
            Duel.ConfirmCards(1-tp, sg)
        end
    end
end


function s.extg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetFieldGroupCount(tp, LOCATION_DECK, 0) >= 5 end
end

function s.exop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetFieldGroupCount(tp, LOCATION_DECK, 0) < 5 then return end
    Duel.ConfirmDecktop(tp, 5)
    local g = Duel.GetDecktopGroup(tp, 5)
    local ct = g:FilterCount(Card.IsSetCard, nil, 0xb54)
    
    Duel.SortDecktop(tp, tp, 5)
    
    if ct > 0 then
        local c = e:GetHandler()
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_EXTRA_ATTACK)
        e1:SetValue(ct - 1)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        c:RegisterEffect(e1)
    end
end

-- Special Summon Fusion Monster
function s.spfilter(c, e, tp)
    return c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCountFromEx(tp) > 0
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end


function s.banrstg(e, tp, eg, ep, ev, re, r, rp, chk)
    local tc = e:GetHandler():GetBattleTarget()
    if chk == 0 then return tc and tc:IsRelateToBattle() and tc:IsAbleToRemove()
        and Duel.IsExistingMatchingCard(s.recfilter, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, tc, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE)
end

function s.recfilter(c, e, tp)
    return (c:IsType(TYPE_NORMAL) or c:IsType(TYPE_FUSION) or c:IsType(TYPE_EFFECT)) 
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.banrsop(e, tp, eg, ep, ev, re, r, rp)
    local tc = e:GetHandler():GetBattleTarget()
    if tc and tc:IsRelateToBattle() and Duel.Remove(tc, POS_FACEUP, REASON_EFFECT) > 0 then
        if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g = Duel.SelectMatchingCard(tp, s.recfilter, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
        if #g > 0 then
            Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
        end
    end
end
