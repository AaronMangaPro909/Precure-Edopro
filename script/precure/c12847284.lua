-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card IDs
local CARD_BEUD                 = 23995346 -- Official Blue-Eyes Ultimate Dragon ID
local CARD_CURE_WINK            = 21287436 -- !! CHANGE THIS !! Replace with Cure Wink's ID
local CARD_CURE_WINK_DRAGOON    = 84970729 -- !! CHANGE THIS !! Replace with Dragoon Armor Style's ID

function s.initial_effect(c)
    -- Fusion Summon Material Setup
    c:EnableReviveLimit()
    -- Material 1: Blue-Eyes Ultimate Dragon
    -- Material 2: Cure Wink OR Cure Wink - Dragoon Armor Style
    Fusion.AddProcMix(c, true, true, CARD_BEUD, {CARD_CURE_WINK, CARD_CURE_WINK_DRAGOON})
    
    -- Must first be Fusion Summoned
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(aux.fuslimit)
    c:RegisterEffect(e0)
    
    -- 1. If Fusion Summoned: Pay 900 LP to gain 500 ATK
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_ATKCHANGE)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O) -- Optional trigger ("You can...")
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCondition(s.atkcon)
    e1:SetCost(s.atkcost)
    e1:SetOperation(s.atkop)
    c:RegisterEffect(e1)
    
    -- 2. Second attack during each Battle Phase
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_EXTRA_ATTACK)
    e2:SetValue(1)
    c:RegisterEffect(e2)
    
    -- 3. Mandatory Maintenance Cost: Standby Phase pay 900 LP or destroy
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F) -- Mandatory field trigger ("You must...")
    e3:SetCode(EVENT_PHASE + PHASE_STANDBY)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.maintcon)
    e3:SetOperation(s.maintop)
    c:RegisterEffect(e3)
end

-- 1. Summon ATK Boost Logic
function s.atkcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.atkcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.CheckLPCost(tp, 900) end
    Duel.PayLPCost(tp, 900)
end
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(500)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE)
        c:RegisterEffect(e1)
    end
end

-- 3. Mandatory Maintenance Logic
function s.maintcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnPlayer() == tp
end
function s.maintop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    -- If the player can afford 900 LP, force them to pay it. Otherwise, destroy the card.
    if Duel.CheckLPCost(tp, 900) then
        Duel.PayLPCost(tp, 900)
    else
        Duel.Destroy(c, REASON_COST)
    end
end
