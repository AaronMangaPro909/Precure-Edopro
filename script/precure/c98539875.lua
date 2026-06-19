-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card IDs
local CARD_ARCANA_SHADOW = 52303611 -- !! CHANGE THIS !! Replace with Cure Arcana Shadow's ID
local CARD_SUNSHINE      = 38489887 -- !! CHANGE THIS !! Replace with Cure Sunshine's ID

function s.initial_effect(c)
    -- Enable Pendulum Mechanics
    Pendulum.AddProcedure(c)
    c:EnableReviveLimit()
    
    -- Fusion Materials: "Cure Arcana Shadow" + "Cure Sunshine"
    Fusion.AddProcMix(c, true, true, CARD_ARCANA_SHADOW, CARD_SUNSHINE)
    
    -------------------------------------------------------------------------
    -- PENDULUM EFFECTS
    -------------------------------------------------------------------------
    
    -- P1. LIGHT and DARK monsters you control gain 500 ATK/DEF
    local p1 = Effect.CreateEffect(c)
    p1:SetType(EFFECT_TYPE_FIELD)
    p1:SetCode(EFFECT_UPDATE_ATTACK)
    p1:SetRange(LOCATION_PZONE)
    p1:SetTargetRange(LOCATION_MZONE, 0)
    p1:SetTarget(s.pstatfilter)
    p1:SetValue(500)
    c:RegisterEffect(p1)
    local p2 = p1:Clone()
    p2:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(p2)
    
    -- P2. Pendulum Quick Effect: Negate Spell/Trap
    local p3 = Effect.CreateEffect(c)
    p3:SetDescription(aux.Stringid(id, 0))
    p3:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    p3:SetType(EFFECT_TYPE_QUICK_O)
    p3:SetCode(EVENT_CHAINING)
    p3:SetRange(LOCATION_PZONE)
    p3:SetCountLimit(1)
    p3:SetCondition(s.pnegcon)
    p3:SetTarget(s.pnegtg)
    p3:SetOperation(s.pnegop)
    c:RegisterEffect(p3)
    
    -------------------------------------------------------------------------
    -- MONSTER EFFECTS
    -------------------------------------------------------------------------
    
    -- M1. Gains 500 ATK for each LIGHT monster in your GY
    local m1 = Effect.CreateEffect(c)
    m1:SetType(EFFECT_TYPE_SINGLE)
    m1:SetCode(EFFECT_UPDATE_ATTACK)
    m1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    m1:SetRange(LOCATION_MZONE)
    m1:SetValue(s.matkval)
    c:RegisterEffect(m1)
    
    -- M2. Once per turn: Special Summon 1 "Precure" monster from your GY
    local m2 = Effect.CreateEffect(c)
    m2:SetDescription(aux.Stringid(id, 1))
    m2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    m2:SetType(EFFECT_TYPE_IGNITION)
    m2:SetRange(LOCATION_MZONE)
    m2:SetCountLimit(1)
    m2:SetTarget(s.msptg)
    m2:SetOperation(s.mspop)
    c:RegisterEffect(m2)
    
    -- M3. If destroyed by opponent: Place in Pendulum Zone
    local m3 = Effect.CreateEffect(c)
    m3:SetDescription(aux.Stringid(id, 2))
    m3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    m3:SetCode(EVENT_DESTROYED)
    m3:SetProperty(EFFECT_FLAG_DELAY)
    m3:SetCondition(s.pencon)
    m3:SetTarget(s.pentg)
    m3:SetOperation(s.penop)
    c:RegisterEffect(m3)
    
    -- M4. Monster Quick Effect: Negate Trap Card
    local m4 = Effect.CreateEffect(c)
    m4:SetDescription(aux.Stringid(id, 3))
    m4:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    m4:SetType(EFFECT_TYPE_QUICK_O)
    m4:SetCode(EVENT_CHAINING)
    m4:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    m4:SetRange(LOCATION_MZONE)
    m4:SetCountLimit(1)
    m4:SetCondition(s.mnegcon)
    m4:SetTarget(s.mnegtg)
    m4:SetOperation(s.mnegop)
    c:RegisterEffect(m4)
end

-------------------------------------------------------------------------
-- PENDULUM RESOLUTIONS
-------------------------------------------------------------------------
function s.pstatfilter(e, c)
    return c:IsFaceup() and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK))
end
function s.pnegcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev) and re:IsActiveType(TYPE_SPELL + TYPE_TRAP)
end
function s.pnegtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end
function s.pnegop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end

-------------------------------------------------------------------------
-- MONSTER RESOLUTIONS
-------------------------------------------------------------------------
-- M1: ATK scaling tracker
function s.matkfilter(c)
    return c:IsType(TYPE_MONSTER) and c:IsAttribute(ATTRIBUTE_LIGHT)
end
function s.matkval(e, c)
    return Duel.GetMatchingGroupCount(s.matkfilter, e:GetHandlerPlayer(), LOCATION_GRAVE, 0, nil) * 500
end

-- M2: Special Summon "Precure" from GY
function s.mgyfilter(c, e, tp)
    return c:IsSetCard(0xb54) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.msptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.mgyfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE)
end
function s.mspop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.mgyfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, LOCATION_MZONE)
    end
end

-- M3: Place into Pendulum Zone upon destruction
function s.pencon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return c:IsPreviousLocation(LOCATION_MZONE) and c:IsFaceup() and c:IsReason(REASON_EFFECT + REASON_BATTLE) and rp ~= tp
end
function s.pentg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.CheckPendulumZones(tp) end
end
function s.penop(e, tp, eg, ep, ev, re, r, rp)
    if not Duel.CheckPendulumZones(tp) then return end
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.MoveToField(c, tp, tp, LOCATION_PZONE, POS_FACEUP, true)
    end
end

-- M4: Monster-state Trap Card negation
function s.mnegcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev) and re:IsActiveType(TYPE_TRAP)
end
function s.mnegtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end
function s.mnegop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end
