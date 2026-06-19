-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card IDs
local CARD_CURE_FLORA       = 65935871 -- !! CHANGE THIS !! Replace with Cure Flora's ID
local CARD_BLACK_ROSE_DRG   = 73580471 -- Official Konami Black Rose Dragon ID

function s.initial_effect(c)
    c:EnableReviveLimit()
    
    -- Fusion Material Setup: "Cure Flora" + "Black Rose Dragon"
    Fusion.AddProcMix(c, true, true, CARD_CURE_FLORA, CARD_BLACK_ROSE_DRG)
    
    -- 1. If Fusion Summoned: Pay LP until 100 left to gain ATK equal to LP paid
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_ATKCHANGE)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCondition(s.atkcon)
    e1:SetCost(s.atkcost)
    e1:SetOperation(s.atkop)
    c:RegisterEffect(e1)
    
    -- 2. Quick Effect: Negate and destroy any card or effect activation
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1) -- Once per turn
    e2:SetCondition(s.negcon)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)
end

-- 1. ATK Gain & LP Payment Engine Math
function s.atkcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.atkcost(e, tp, eg, ep, ev, re, r, rp, chk)
    -- Must have strictly more than 100 LP to initiate the activation payment
    if chk == 0 then return Duel.GetLP(tp) > 100 end
    local lp = Duel.GetLP(tp)
    local pay = lp - 100
    Duel.PayLPCost(tp, pay)
    e:SetLabel(pay) -- Store the paid amount to read during resolution
end
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local val = e:GetLabel()
    if c:IsRelateToEffect(e) and c:IsFaceup() and val > 0 then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(val)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE)
        c:RegisterEffect(e1)
    end
end

-- 2. Omninegation Quick Effect Logic
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
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
