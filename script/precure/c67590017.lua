-- Dark Cure Sky
local s, id = GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()
    Fusion.AddProcMix(c, true, true, 14757249, aux.FilterBoolFunction(Card.IsAttribute, ATTRIBUTE_DARK))

    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_DESTROY + CATEGORY_DAMAGE)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) end)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)

    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_REMOVE + CATEGORY_DAMAGE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetTarget(s.remtg)
    e2:SetOperation(s.remop)
    c:RegisterEffect(e2)

    -- 3. Double battle damage to opponent when attacking a monster
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_PRE_BATTLE_DAMAGE)
    e3:SetCondition(s.damcon)
    e3:SetOperation(s.damop)
    c:RegisterEffect(e3)

    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_EQUIP)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetRange(LOCATION_MZONE)
    e4:SetHintTiming(0, TIMING_BATTLE_PHASE)
    e4:SetCondition(function() return Duel.GetCurrentPhase() >= PHASE_BATTLE_START and Duel.GetCurrentPhase() <= PHASE_BATTLE end)
    e4:SetTarget(s.eqtg)
    e4:SetCountLimit (1)
    e4:SetOperation(s.eqop)
    c:RegisterEffect(e4)
    
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 3))
    e5:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_CHAINING)
    e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1)
    e5:SetCondition(function(e, tp, eg, ep, ev, re, r, rp) return rp ~= tp and Duel.IsChainNegatable(ev) end)
    e5:SetCost(function(e, tp, eg, ep, ev, re, r, rp, chk)
        if chk == 0 then return Duel.CheckLPCost(tp, 500) end
        Duel.PayLPCost(tp, 500)
    end)
    e5:SetTarget(function(e, tp, eg, ep, ev, re, r, rp, chk)
        if chk == 0 then return true end
        Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
        if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
            Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
        end
    end)
    e5:SetOperation(function(e, tp, eg, ep, ev, re, r, rp)
        if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
            Duel.Destroy(eg, REASON_EFFECT)
        end
    end)
    c:RegisterEffect(e5)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1 - tp) end
    if chk == 0 then return Duel.IsExistingTarget(Card.IsDestructable, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectTarget(tp, Card.IsDestructable, tp, 0, LOCATION_MZONE, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_DAMAGE, nil, 0, 1 - tp, g:GetFirst():GetBaseAttack())
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) then
        local atk = tc:GetBaseAttack()
        if atk < 0 then atk = 0 end
        if Duel.Destroy(tc, REASON_EFFECT) ~= 0 then
            Duel.Damage(1 - tp, atk, REASON_EFFECT)
        end
    end
end
function s.remtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetFieldGroupCount(tp, 0, LOCATION_DECK) >= 3 end
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 3, 1 - tp, LOCATION_DECK)
    Duel.SetOperationInfo(0, CATEGORY_DAMAGE, nil, 0, 1 - tp, 500)
end
function s.remop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetDecktopGroup(1 - tp, 3)
    if #g > 0 and Duel.Remove(g, POS_FACEDOWN, REASON_EFFECT) ~= 0 then
        Duel.Damage(1 - tp, 500, REASON_EFFECT)
    end
end
function s.damcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetAttackTarget()
    return c == Duel.GetAttacker() and tc and tc:IsControler(1 - tp)
end
function s.damop(e, tp, eg, ep, ev, re, r, rp)
    Duel.ChangeBattleDamage(1 - tp, ev * 2)
end
function s.eqtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and chkc:IsAttribute(ATTRIBUTE_DARK) end
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0 
        and Duel.IsExistingTarget(Card.IsAttribute, tp, LOCATION_GRAVE, 0, 1, nil, ATTRIBUTE_DARK) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_EQUIP)
    local g = Duel.SelectTarget(tp, Card.IsAttribute, tp, LOCATION_GRAVE, 0, 1, 1, nil, ATTRIBUTE_DARK)
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, g, 1, 0, 0)
end
function s.eqop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) and c:IsRelateToEffect(e) and c:IsFaceup() then
        if Duel.Equip(tp, tc, c, true) then
            local e1 = Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_EQUIP_LIMIT)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetValue(function(e, c) return e:GetOwner() == c end)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e1)
            local e2 = Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_EQUIP)
            e2:SetCode(EFFECT_UPDATE_ATTACK)
            e2:SetValue(1000)
            e2:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e2)
        end
    end
end
