-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

local CARD_KOMUGI = 36955586

function s.initial_effect(c)
 
    c:EnableUnsummonable()
     
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
 
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_EQUIP + CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.eqcon)
    e3:SetTarget(s.eqtg)
    e3:SetCountLimit (1)
    e3:SetOperation(s.eqop)
    c:RegisterEffect(e3)
end

function s.spfilter(c, tp)
    return c:IsCode(CARD_KOMUGI) and (c:IsControler(tp) or c:IsFaceup())
end
function s.spcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    local rg = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, c, tp)
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and #rg > 0
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, c)
    local rg = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, c, tp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RELEASE)
    local g = rg:Select(tp, 1, 1, nil)
    if #g > 0 then
        g:KeepAlive()
        e:SetLabelObject(g)
        return true
    end
    return false
end
function s.spop(e, tp, eg, ep, ev, re, r, rp, c)
    local g = e:GetLabelObject()
    if not g then return end
    Duel.Release(g, REASON_COST)
    g:DeleteGroup()
end

function s.cfilter(c)
    return c:IsFaceup() and c:IsCode(CARD_KOMUGI) and c:IsRace(RACE_BEAST)
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
    return c:IsCode(CARD_KOMUGI) and c:IsRace(RACE_BEAST) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
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
