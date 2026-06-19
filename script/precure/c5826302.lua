local s, id = GetID()

-- ID Configuration
local CARD_PURIRUN = 41037083 -- Replace with Purirun's actual ID

function s.initial_effect(c)
    -- 1. On Summon: Spec Summon 1 "Purirun" from hand or Deck
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1, id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)
    
    -- 2. Attack Declaration: Discard to skip damage calc and battle damage
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_ATTACK_ANNOUNCE)
    e3:SetRange(LOCATION_HAND)
    e3:SetCountLimit(1, id + 100)
    e3:SetCondition(s.atkcon)
    e3:SetCost(s.atkcost)
    e3:SetOperation(s.atkop)
    c:RegisterEffect(e3)
end

-- E1/E2 Logic
function s.spfilter(c, e, tp)
    return c:IsCode(CARD_PURIRUN) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
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
        Duel.SpecialSummon(g, 0, tp, tp, false, false, LOCATION_MZONE)
    end
end

-- E3 Logic
function s.atkcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetAttacker():IsControler(1 - tp)
end
function s.atkcost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:IsDiscardable() end
    Duel.SendtoGrave(c, REASON_COST + REASON_DISCARD)
end
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    -- Skip damage calculation
    local e1 = Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SKIP_DP)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetTargetRange(1, 1)
    e1:SetReset(RESET_PHASE + PHASE_BATTLE)
    Duel.RegisterEffect(e1, tp)
    
    -- No battle damage for the rest of this battle
    local e2 = Effect.CreateEffect(e:GetHandler())
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetTargetRange(1, 0)
    e2:SetReset(RESET_PHASE + PHASE_BATTLE)
    Duel.RegisterEffect(e2, tp)
end
