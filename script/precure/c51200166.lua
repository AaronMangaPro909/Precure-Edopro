-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card ID Constants
local CARD_CURE_IDOL            = 39517403 -- !! CHANGE THIS TO CURE IDOL'S ID !!
local CARD_ALPHA_MAGNET         = 99785935 -- Alpha The Magnet Warrior
local CARD_BETA_MAGNET          = 39256679 -- Beta The Magnet Warrior
local CARD_GAMMA_MAGNET         = 11549357 -- Gamma The Magnet Warrior
local CARD_VALKYRION_MAGNA      = 75347539 -- Valkyrion the Magna Warrior

local COUNTER_IDOL = 0x8fc

function s.initial_effect(c)
    -- Enable Idol Counter
    c:EnableCounterPermit(COUNTER_IDOL)

    -- Must be Fusion Summoned
    c:EnableReviveLimit()
    
    -- Corrected Fusion Material Procedure:
    -- Material 1: "Cure Idol"
    -- Material 2: "Valkyrion the Magna Warrior" OR ("Alpha" + "Beta" + "Gamma")
    Fusion.AddProcMixRep(c, true, true, s.matfilter_cure, 1, 1, s.matfilter_magnets)

    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(aux.fuslimit)
    c:RegisterEffect(e0)

    -- 1. Counter Engine (Max 10)
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_MZONE)
    e1:SetOperation(s.ctrop)
    c:RegisterEffect(e1)

    -- 2. Destroy 1 opponent card (Remove 1 Counter)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCost(s.descost)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)

    -- 3. Quick Effect Negate S/T + 500 damage
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY + CATEGORY_DAMAGE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.negcon)
    e3:SetCost(s.negcost)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)

    -- 4. Floating Effect (Special Summon components on destruction)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_DESTROYED)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
end

s.listed_names = {
    CARD_CURE_IDOL, 
    CARD_ALPHA_MAGNET, 
    CARD_BETA_MAGNET, 
    CARD_GAMMA_MAGNET, 
    CARD_VALKYRION_MAGNA
}

-------------------------------------------------------------------------
-- FUSION MATERIAL FILTERS
-------------------------------------------------------------------------
function s.matfilter_cure(c, fc, sumtype, tp)
    return c:IsCode(CARD_CURE_IDOL)
end

function s.matfilter_magnets(c, fc, sumtype, tp)
    return c:IsCode(CARD_VALKYRION_MAGNA, CARD_ALPHA_MAGNET, CARD_BETA_MAGNET, CARD_GAMMA_MAGNET)
end

-------------------------------------------------------------------------
-- COUNTER ENGINE
-------------------------------------------------------------------------
function s.ctrop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if re:IsActiveType(TYPE_SPELL + TYPE_TRAP) and c:GetCounter(COUNTER_IDOL) < 10 then
        c:AddCounter(COUNTER_IDOL, 1)
    end
end

-------------------------------------------------------------------------
-- DESTROY ENGINE
-------------------------------------------------------------------------
function s.descost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsCanRemoveCounter(tp, COUNTER_IDOL, 1, REASON_COST) end
    e:GetHandler():RemoveCounter(tp, COUNTER_IDOL, 1, REASON_COST)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsControler(1 - tp) and chkc:IsOnField() end
    if chk == 0 then return Duel.IsExistingTarget(nil, tp, 0, LOCATION_ONFIELD, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectTarget(tp, nil, tp, 0, LOCATION_ONFIELD, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Destroy(tc, REASON_EFFECT)
    end
end

-------------------------------------------------------------------------
-- NEGATE ENGINE
-------------------------------------------------------------------------
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and re:IsActiveType(TYPE_SPELL + TYPE_TRAP) and Duel.IsChainNegatable(ev)
end

function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, nil) end
    Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST + REASON_DISCARD, nil)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
        Duel.SetOperationInfo(0, CATEGORY_DAMAGE, nil, 0, 1 - tp, 500)
    end
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        if Duel.Destroy(eg, REASON_EFFECT) > 0 then
            Duel.Damage(1 - tp, 500, REASON_EFFECT)
        end
    end
end

-------------------------------------------------------------------------
-- FLOATING SPECIAL SUMMON ENGINE
-------------------------------------------------------------------------
function s.spfilter(c, e, tp, code)
    return c:IsCode(code) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return false end
    
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if ft <= 0 then return false end

    local can_opt_a = ft >= 2 
        and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp, CARD_CURE_IDOL)
        and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp, CARD_VALKYRION_MAGNA)

    local can_opt_b = ft >= 4
        and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp, CARD_CURE_IDOL)
        and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp, CARD_ALPHA_MAGNET)
        and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp, CARD_BETA_MAGNET)
        and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp, CARD_GAMMA_MAGNET)

    if chk == 0 then return can_opt_a or can_opt_b end

    local op = 0
    if can_opt_a and can_opt_b then
        op = Duel.SelectOption(tp, aux.Stringid(id, 3), aux.Stringid(id, 4))
    elseif can_opt_a then
        op = 0
    else
        op = 1
    end

    e:SetLabel(op)

    local g = Group.CreateGroup()
    if op == 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g1 = Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp, CARD_CURE_IDOL)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g2 = Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp, CARD_VALKYRION_MAGNA)
        g:Merge(g1)
        g:Merge(g2)
    else
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g1 = Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp, CARD_CURE_IDOL)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g2 = Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp, CARD_ALPHA_MAGNET)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g3 = Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp, CARD_BETA_MAGNET)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g4 = Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp, CARD_GAMMA_MAGNET)
        g:Merge(g1)
        g:Merge(g2)
        g:Merge(g3)
        g:Merge(g4)
    end

    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, #g, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local tg = Duel.GetTargetCards(e)
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if #tg > 0 and ft >= #tg then
        Duel.SpecialSummon(tg, 0, tp, tp, false, false, POS_FACEUP)
    end
end
