-- Odd-Eyes Éclair Pendulum Dragon
local s, id = GetID()

local CARD_CURE_ECLAIR          = 12176213
local CARD_ODD_EYES_PENDULUM    = 16178681

function s.initial_effect(c)
    Pendulum.AddProcedure(c)
    c:EnableReviveLimit()
    Fusion.AddProcMix(c, true, true, CARD_CURE_ECLAIR, CARD_ODD_EYES_PENDULUM)
    
    local pe1 = Effect.CreateEffect(c)
    pe1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    pe1:SetCode(EVENT_SPSUMMON_SUCCESS)
    pe1:SetRange(LOCATION_PZONE)
    pe1:SetCondition(s.pencon)
    pe1:SetOperation(s.penop)
    c:RegisterEffect(pe1)
    
    local pe2 = Effect.CreateEffect(c)
    pe2:SetDescription(aux.Stringid(id, 0))
    pe2:SetCategory(CATEGORY_RECOVER)
    pe2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    pe2:SetCode(EVENT_PHASE + PHASE_STANDBY)
    pe2:SetRange(LOCATION_PZONE)
    pe2:SetCountLimit(1)
    pe2:SetCondition(function(e, tp) return Duel.GetTurnPlayer() == tp end)
    pe2:SetTarget(s.rectg)
    pe2:SetOperation(s.recop)
    c:RegisterEffect(pe2)
    
    local pe3 = Effect.CreateEffect(c)
    pe3:SetDescription(aux.Stringid(id, 1))
    pe3:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    pe3:SetType(EFFECT_TYPE_QUICK_O)
    pe3:SetCode(EVENT_CHAINING)
    pe3:SetRange(LOCATION_PZONE)
    pe3:SetCountLimit(1)
    pe3:SetCondition(function(e, tp, eg, ep, ev, re, r, rp) return rp ~= tp and Duel.IsChainNegatable(ev) end)
    pe3:SetTarget(s.pentg)
    pe3:SetOperation(s.penop_negate)
    c:RegisterEffect(pe3)

    local me1 = Effect.CreateEffect(c)
    me1:SetDescription(aux.Stringid(id, 2))
    me1:SetCategory(CATEGORY_REMOVE)
    me1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    me1:SetProperty(EFFECT_FLAG_DELAY)
    me1:SetCode(EVENT_SPSUMMON_SUCCESS)
    me1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) end)
    me1:SetTarget(s.banishtg)
    me1:SetOperation(s.banishop)
    c:RegisterEffect(me1)
    
    local me2 = Effect.CreateEffect(c)
    me2:SetDescription(aux.Stringid(id, 3))
    me2:SetCategory(CATEGORY_ATKCHANGE)
    me2:SetType(EFFECT_TYPE_IGNITION)
    me2:SetRange(LOCATION_MZONE)
    me2:SetCountLimit(1)
    me2:SetCondition(function() return Duel.IsMainPhase() end)
    me2:SetOperation(s.atkop)
    c:RegisterEffect(me2)
    
    local me3 = Effect.CreateEffect(c)
    me3:SetType(EFFECT_TYPE_SINGLE)
    me3:SetCode(EFFECT_PIERCE)
    c:RegisterEffect(me3)
    local me4 = Effect.CreateEffect(c)
    me4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    me4:SetCode(EVENT_PRE_BATTLE_DAMAGE)
    me4:SetCondition(s.damcon)
    me4:SetOperation(s.damop)
    c:RegisterEffect(me4)
    
    local me5 = Effect.CreateEffect(c)
    me5:SetDescription(aux.Stringid(id, 4))
    me5:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    me5:SetType(EFFECT_TYPE_QUICK_O)
    me5:SetCode(EVENT_CHAINING)
    me5:SetRange(LOCATION_MZONE)
    me5:SetCountLimit(1)
    me5:SetCondition(s.stnegcon)
    me5:SetCost(s.stnegcost)
    me5:SetTarget(s.stnegtg)
    me5:SetOperation(s.stnegop)
    c:RegisterEffect(me5)
    
    local me6 = Effect.CreateEffect(c)
    me6:SetDescription(aux.Stringid(id, 5))
    me6:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    me6:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
    me6:SetCode(EVENT_DESTROYED)
    me6:SetCondition(s.penplacecon)
    me6:SetTarget(s.penplacetg)
    me6:SetOperation(s.penplaceop)
    c:RegisterEffect(me6)
end

function s.cfilter(c, tp)
    return c:IsSummonType(SUMMON_TYPE_PENDULUM) and c:IsControler(tp) and (c:IsRace(RACE_DRAGON) or c:IsSetCard(0xb54))
end
function s.pencon(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(s.cfilter, 1, nil, tp)
end
function s.penop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, LOCATION_MZONE, 0, nil)
    for tc in aux.Next(g) do
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(2000)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2 = e1:Clone()
        e2:SetCode(EFFECT_UPDATE_DEFENSE)
        tc:RegisterEffect(e2)
    end
end

function s.rectg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(1000)
    Duel.SetOperationInfo(0, CATEGORY_RECOVER, nil, 0, tp, 1000)
end
function s.recop(e, tp, eg, ep, ev, re, r, rp)
    local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
    Duel.Recover(p, d, REASON_EFFECT)
end

function s.pentg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end
function s.penop_negate(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end

function s.banishtg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    local mg = c:GetMaterial()
    local used_from_gy_ed = mg and mg:IsExists(function(tc)
        return tc:IsCode(CARD_ODD_EYES_PENDULUM) and (tc:IsLocation(LOCATION_GRAVE) or tc:IsLocation(LOCATION_EXTRA))
    end, 1, nil)
    
    if chk == 0 then
        if used_from_gy_ed then
            return Duel.GetFieldGroupCount(tp, 0, LOCATION_DECK) >= 5
        else
            return Duel.IsExistingMatchingCard(Card.IsAbleToRemove, tp, 0, LOCATION_ONFIELD, 1, nil, POS_FACEDOWN)
        end
    end
    
    if used_from_gy_ed then
        Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 5, 1 - tp, LOCATION_DECK)
    else
        local g = Duel.GetMatchingGroup(Card.IsAbleToRemove, tp, 0, LOCATION_ONFIELD, nil, POS_FACEDOWN)
        Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, 5, 0, 0)
    end
end

function s.banishop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local mg = c:GetMaterial()
    local used_from_gy_ed = mg and mg:IsExists(function(tc)
        return tc:IsCode(CARD_ODD_EYES_PENDULUM) and (tc:IsLocation(LOCATION_GRAVE) or tc:IsLocation(LOCATION_EXTRA))
    end, 1, nil)
    
    if used_from_gy_ed then
        local g = Duel.GetDecktopGroup(1 - tp, 5)
        if #g >= 5 then
            Duel.Remove(g, POS_FACEDOWN, REASON_EFFECT)
        end
    else
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
        local g = Duel.SelectMatchingCard(tp, Card.IsAbleToRemove, tp, 0, LOCATION_ONFIELD, 1, 5, nil, POS_FACEDOWN)
        if #g > 0 then
            Duel.Remove(g, POS_FACEDOWN, REASON_EFFECT)
        end
    end
end

function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(1000)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        c:RegisterEffect(e1)
    end
end

function s.damcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetAttackTarget()
    return c == Duel.GetAttacker() and tc and tc:IsDefensePos() and tc:IsControler(1 - tp)
end
function s.damop(e, tp, eg, ep, ev, re, r, rp)
    Duel.ChangeBattleDamage(1 - tp, ev * 2)
end

function s.stnegcon(e, tp, eg, ep, ev, re, r, rp)
    return re:IsActiveType(TYPE_SPELL + TYPE_TRAP) and rp ~= tp and Duel.IsChainNegatable(ev)
end
function s.stnegcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, e:GetHandler()) end
    Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST + REASON_DISCARD)
end
function s.stnegtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end
function s.stnegop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end

function s.penplacecon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return c:IsPreviousLocation(LOCATION_MZONE) and c:IsSummonType(SUMMON_TYPE_FUSION)
        and rp ~= tp and c:IsReason(REASON_BATTLE + REASON_EFFECT)
end
function s.penplacetg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.CheckLocation(tp, LOCATION_PZONE, 0) or Duel.CheckLocation(tp, LOCATION_PZONE, 1) end
end
function s.penplaceop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if (Duel.CheckLocation(tp, LOCATION_PZONE, 0) or Duel.CheckLocation(tp, LOCATION_PZONE, 1)) and c:IsRelateToEffect(e) then
        Duel.MoveToField(c, tp, tp, LOCATION_PZONE, POS_FACEUP, true)
    end
end
