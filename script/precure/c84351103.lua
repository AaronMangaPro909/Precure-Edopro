-- Cure Flora Mode Elegant Lilac
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    e1:SetValue(aux.ritlimit)
    c:RegisterEffect(e1)
    -- 2. Name becomes "Cure Flora" while on the field
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_CHANGE_CODE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(65935871)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1, {id, 1})
    e3:SetTarget(s.efftg)
    e3:SetOperation(s.effop)
    c:RegisterEffect(e3)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 1))
    e4:SetCategory(CATEGORY_EQUIP + CATEGORY_ATKCHANGE)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.eqcon)
    e4:SetTarget(s.eqtg)
    e4:SetCountLimit (1)
    e4:SetOperation(s.eqop)
    c:RegisterEffect(e4)
    local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e5:SetCode(EVENT_CHAINING)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.condition)
	e5:SetTarget(s.target)
	e5:SetOperation(s.operation)
	c:RegisterEffect(e5)
    -- 6. Trigger Effect (GY): Banish this card if destroyed by opponent's card, destroy all cards opponent controls - HOPT
    local e6 = Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id, 3))
    e6:SetCategory(CATEGORY_DESTROY)
    e6:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e6:SetCode(EVENT_DESTROYED)
    e6:SetProperty(EFFECT_FLAG_DELAY)
    e6:SetCountLimit(1, {id, 4})
    e6:SetCondition(s.descon)
    e6:SetCost(s.descost)
    e6:SetTarget(s.destg)
    e6:SetOperation(s.desop)
    c:RegisterEffect(e6)
end

s.listed_names = {65935871, 72646284}

function s.efftg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return false end
    local b1 = Duel.IsExistingTarget(Card.IsDestructable, tp, 0, LOCATION_MZONE, 1, nil)
    local b2 = Duel.IsExistingTarget(Card.IsDestructable, tp, 0, LOCATION_SZONE, 1, nil)
    if chk == 0 then return b1 or b2 end
    
    local op = 0
    if b1 and b2 then
        op = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 1))
    elseif b1 then
        op = Duel.SelectOption(tp, aux.Stringid(id, 0))
    else
        op = Duel.SelectOption(tp, aux.Stringid(id, 1)) + 1
    end
    
    e:SetLabel(op)
    if op == 0 then
        e:SetCategory(CATEGORY_DESTROY + CATEGORY_RECOVER)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
        local g = Duel.SelectTarget(tp, Card.IsDestructable, tp, 0, LOCATION_MZONE, 1, 1, nil)
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
        Duel.SetOperationInfo(0, CATEGORY_RECOVER, nil, 0, tp, g:GetFirst():GetTextAttack())
    else
        e:SetCategory(CATEGORY_DESTROY + CATEGORY_RECOVER)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
        local g = Duel.SelectTarget(tp, Card.IsDestructable, tp, 0, LOCATION_SZONE, 1, 1, nil)
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
        Duel.SetOperationInfo(0, CATEGORY_RECOVER, nil, 0, tp, 500)
    end
end

function s.effop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) then return end
    local op = e:GetLabel()
    if op == 0 then
        local atk = tc:GetTextAttack()
        if Duel.Destroy(tc, REASON_EFFECT) > 0 and atk > 0 then
            Duel.Recover(tp, atk, REASON_EFFECT)
        end
    else
        if Duel.Destroy(tc, REASON_EFFECT) > 0 then
            Duel.Recover(tp, 500, REASON_EFFECT)
        end
    end
end

--- this code not Continuous is Equip it.
function s.cfilter(c)
    return c:IsFaceup() and c:IsCode(43290246, 1336311887, 33253641)
end
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    return re:IsActiveType(TYPE_MONSTER) 
        and Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_MZONE, 0, 1, nil)
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.IsExistingTarget(Card.IsFacedown, tp, 0, LOCATION_SZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RTOHAND)
    local g = Duel.SelectTarget(tp, Card.IsFacedown, tp, 0, LOCATION_SZONE, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, g, 1, 0, 0)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFacedown() then
        Duel.SendtoHand(tc, nil, REASON_EFFECT)
    end
end

function s.eqcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsBattlePhase()
end
function s.eqfilter(c)
    return c:IsCode(43290246, 1336311887, 33253641) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end
function s.eqtg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
        and Duel.IsExistingTarget(s.eqfilter, tp, LOCATION_MZONE + LOCATION_GRAVE, LOCATION_MZONE, 1, e:GetHandler()) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_EQUIP)
    local g = Duel.SelectTarget(tp, s.eqfilter, tp, LOCATION_MZONE + LOCATION_GRAVE, LOCATION_MZONE, 1, 1, e:GetHandler())
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, g, 1, 0, 0)
end
function s.eqop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
    if not tc or not tc:IsRelateToEffect(e) or (tc:IsOnField() and tc:IsFacedown()) then return end
    
    if Duel.Equip(tp, tc, c, true) then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_EQUIP_LIMIT)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetValue(true)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e1)
        
        local e2 = Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_EQUIP)
        e2:SetCode(EFFECT_UPDATE_ATTACK)
        e2:SetValue(500)
        e2:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e2)
    end
end

--- Both players Negate and Destroy it.
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and re:IsHasType(EFFECT_TYPE_ACTIVATE)
		and re:IsSpellEffect() and Duel.IsChainNegatable(ev)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFacedown() or not c:IsRelateToEffect(e) then return end
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-- Banish and Destroy it your opponent it cards.
function s.descon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return c:IsReason(REASON_BATTLE + REASON_EFFECT) and rp ~= tp and c:IsPreviousControler(tp)
end

function s.descost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:IsAbleToRemoveAsCost() end
    Duel.Remove(c, POS_FACEUP, REASON_COST)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(aux.TRUE, tp, 0, LOCATION_ONFIELD, 1, nil) end
    local g = Duel.GetMatchingGroup(aux.TRUE, tp, 0, LOCATION_ONFIELD, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, #g, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(aux.TRUE, tp, 0, LOCATION_ONFIELD, nil)
    if #g > 0 then
        Duel.Destroy(g, REASON_EFFECT)
    end
end
