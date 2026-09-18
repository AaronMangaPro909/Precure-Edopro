-- Prism Magician Style 
-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card ID Constants
local CARD_CURE_PRISM = 16635445 -- !! CHANGE THIS !!
local CARD_DMG        = 38033121 -- Standard Dark Magician Girl ID
local CARD_CURE_SKY   = 14757249 -- !! CHANGE THIS !!

function s.initial_effect(c)
    -- Fusion Summon requirements
    c:EnableReviveLimit()
    Fusion.AddProcMix(c, true, true, CARD_CURE_PRISM, CARD_DMG)

    -- 1. Search "Precure" card on Fusion Summon
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) end)
    e1:SetTarget(s.thtg)
    e1:SetCountLimit(1)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    -- 2. Gains 500 ATK for each "Cure Sky" in GY
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(s.atkval)
    c:RegisterEffect(e2)

    -- 3. Quick Effect: Pay 500 LP, negate and destroy
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(function(e, tp, eg, ep, ev, re, r, rp) 
        return rp ~= tp and Duel.IsChainNegatable(ev) 
    end)
    e3:SetCost(function(e, tp, eg, ep, ev, re, r, rp, chk)
        if chk == 0 then return Duel.CheckLPCost(tp, 500) end
        Duel.PayLPCost(tp, 500)
    end)
    e3:SetTarget(function(e, tp, eg, ep, ev, re, r, rp, chk)
        if chk == 0 then return true end
        Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
        if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
            Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
        end
    end)
    e3:SetOperation(function(e, tp, eg, ep, ev, re, r, rp)
        if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
            Duel.Destroy(eg, REASON_EFFECT)
        end
    end)
    c:RegisterEffect(e3)
end

-- Helper: Search Filter
function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsAbleToHand() -- Replace 0xb54 with your Precure Archetype ID
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

-- Helper: ATK Calculation
function s.atkval(e, c)
    return Duel.GetMatchingGroupCount(Card.IsCode, e:GetHandlerPlayer(), LOCATION_GRAVE, 0, nil, CARD_CURE_SKY) * 500
end
