-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card IDs
local CARD_CURE_SCARLET     = 3325364110 -- !! CHANGE THIS !! Replace with Cure Scarlet's ID
local CARD_SCARLET_PHOENIX  = 38428472 -- !! CHANGE THIS !! Replace with Cure Scarlet - Immortal Phoenix's ID
local CARD_RA               = 10000010 -- Official The Winged Dragon of Ra ID
local CARD_RA_PHOENIX       = 10000090 -- Official The Winged Dragon of Ra - Immortal Phoenix ID

function s.initial_effect(c)
    -- Activate: Negate, Destroy, and Burn
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY + CATEGORY_DAMAGE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_CHAINING)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e1:SetCondition(s.condition)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-- 1. Control Requirement Condition
function s.cfilter(c)
    if not c:IsFaceup() then return false end
    local code = c:GetCode()
    return code == CARD_CURE_SCARLET 
        or code == CARD_RA 
        or code == CARD_RA_PHOENIX 
        or (code == CARD_SCARLET_PHOENIX and c:IsType(TYPE_FUSION))
end
function s.condition(e, tp, eg, ep, ev, re, r, rp)
    -- Must control at least 1 of the required monsters AND opponent must activate a card/effect
    return rp ~= tp and Duel.IsChainNegatable(ev)
        and Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_MZONE, 0, 1, nil)
end

-- 2. Cost: Pay 500 LP
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.CheckLPCost(tp, 500) end
    Duel.PayLPCost(tp, 500)
end

-- 3. Target setup for engine system signaling
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
    Duel.SetOperationInfo(0, CATEGORY_DAMAGE, nil, 0, 1 - tp, 2000)
end

-- 4. Resolution Chain logic (Negate -> Destroy -> Break -> Burn)
function s.activate(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        if Duel.Destroy(eg, REASON_EFFECT) ~= 0 then
            Duel.BreakEffect()
            Duel.Damage(1 - tp, 2000, REASON_EFFECT)
        end
    end
end
