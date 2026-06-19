-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- !! CHANGE THESE !! 
local CARD_WINK_EYES_DRAGON = 10586964 -- Replace with Wink-Eyes Blue Dragon's ID
local CARD_CURE_WINK = 21287436 -- Replace with Cure Wink's ID

function s.initial_effect(c)
    -- Fusion Material Setup
    c:EnableReviveLimit()
    Fusion.AddProcMix(c, true, true, CARD_WINK_EYES_DRAGON, CARD_CURE_WINK)
    
    -- 1. ATK becomes equal to cards in hand x 1000
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SET_ATTACK)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetValue(s.atkval)
    c:RegisterEffect(e1)
    
    -- 2. While equipped with "Cure Wink": Gains 300 ATK
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.eqcon)
    e2:SetValue(300)
    c:RegisterEffect(e2)
    
    -- 3. While equipped with "Cure Wink": Second Attack
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_EXTRA_ATTACK)
    e3:SetCondition(s.eqcon)
    e3:SetValue(1)
    c:RegisterEffect(e3)
    
    -- 4. Quick Effect: Negate and destroy Trap Card
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 0))
    e4:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetCondition(s.negcon)
    e4:SetTarget(s.negtg)
    e4:SetOperation(s.negop)
    c:RegisterEffect(e4)
end

-- 1. Hand tracking ATK Calculation
function s.atkval(e, c)
    local tp = c:GetControler()
    return Duel.GetFieldGroupCount(tp, LOCATION_HAND, 0) * 1000
end

-- 2 & 3. Condition check: Is it equipped with "Cure Wink"?
function s.eqfilter(c)
    return c:IsCode(CARD_CURE_WINK)
end
function s.eqcon(e)
    local c = e:GetHandler()
    return c:GetEquipGroup():IsExists(s.eqfilter, 1, nil)
end

-- 4. Trap Negation Logic
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev) and re:IsActiveType(TYPE_TRAP)
end
function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end
function s.negop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end
