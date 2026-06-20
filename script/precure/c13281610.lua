-- Precure! Princess Engage!!!
local s, id = GetID()

local CARD_FLORA   = 65935871
local CARD_MERMAID  = 43290246
local CARD_TWINKLE = 1336311887
local CARD_SCARLET = 3325364110

function s.initial_effect(c)
   
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0, TIMING_END_PHASE)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

function s.precure_filter(c)
    return c:IsFaceup() and c:IsSetCard(0xb54)
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, c) end
    Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST + REASON_DISCARD, c)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
    local g = Duel.SelectMatchingCard(tp, Card.IsAbleToRemoveAsCost, tp, LOCATION_HAND + LOCATION_ONFIELD, 0, 1, 1, c)
    Duel.Remove(g, POS_FACEUP, REASON_COST)
end

function s.spfilter(c, e, tp)
    local code = c:GetCode()
    return (code == CARD_FLORA or code == CARD_MERMAID or code == CARD_TWINKLE or code == CARD_SCARLET)
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then 
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil, e, tp)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local e1 = Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET + EFFECT_FLAG_CLIENT_HINT)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1, 0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE + PHASE_END)
    Duel.RegisterEffect(e1, tp)

    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if ft <= 0 then return end
    if ft > 4 then ft = 4 end 
    local g = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, nil, e, tp)
    
    if #g > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sg = g:Select(tp, 1, ft, nil)
        if #sg > 0 and Duel.SpecialSummon(sg, 0, tp, tp, false, false, POS_FACEUP) > 0 then
            local ct = Duel.GetMatchingGroupCount(s.precure_filter, tp, LOCATION_MZONE, 0, nil)
            if ct >= 4 and Duel.IsPlayerCanDraw(tp, 2) and Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then
                Duel.BreakEffect()
                Duel.Draw(tp, 2, REASON_EFFECT)
            end
        end
    end
end

function s.splimit(e, c)
    return not c:IsSetCard(0xb54)
end