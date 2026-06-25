-- Cure Idol - Idol Heart Ribbon Style
local s, id = GetID()

local CARD_CURE_IDOL = 39517403

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
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_CHANGE_CODE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(CARD_CURE_IDOL)
    c:RegisterEffect(e2)
    
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e3:SetValue(aux.tgoval)
    c:RegisterEffect(e3)
    local e4 = e3:Clone()
    e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e4:SetValue(aux.indoval)
    c:RegisterEffect(e4)
    
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 0))
    e5:SetCategory(CATEGORY_POSITION + CATEGORY_ATKCHANGE + CATEGORY_DEFCHANGE)
    e5:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e5:SetCode(EVENT_ATTACK_ANNOUNCE)
    e5:SetTarget(s.postg)
    e5:SetOperation(s.posop)
    c:RegisterEffect(e5)
    
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetCode(EFFECT_PIERCE)
    c:RegisterEffect(e6)
    
    local e7 = Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id, 1))
    e7:SetCategory(CATEGORY_TOHAND)
    e7:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e7:SetCode(EVENT_DESTROYED)
    e7:SetCondition(s.thcon)
    e7:SetTarget(s.thtg)
    e7:SetOperation(s.thop)
    c:RegisterEffect(e7)
end

function s.revfilter(c)
    return c:IsCode(CARD_CURE_IDOL) and c:IsAbleToGraveAsCost() and not c:IsPublic()
end
function s.spcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.revfilter, tp, LOCATION_HAND, 0, 1, c)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, c)
    local g = Duel.GetMatchingGroup(s.revfilter, tp, LOCATION_HAND, 0, c)
    if #g > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONFIRM)
        local sg = g:Select(tp, 1, 1, nil)
        if #sg > 0 then
            sg:KeepAlive()
            e:SetLabelObject(sg)
            return true
        end
    end
    return false
end
function s.spop(e, tp, eg, ep, ev, re, r, rp, c)
    local sg = e:GetLabelObject()
    if not sg then return end
    Duel.ConfirmCards(1 - tp, sg)
    Duel.SendtoGrave(sg, REASON_COST)
    sg:DeleteGroup()
end

function s.postg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsCanChangePosition, tp, 0, LOCATION_MZONE, 1, nil) end
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_MZONE, nil)
    Duel.SetOperationInfo(0, CATEGORY_POSITION, g, #g, 0, 0)
end
function s.posop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_MZONE, nil)
    if #g > 0 and Duel.ChangePosition(g, POS_FACEUP_DEFENSE, POS_FACEDOWN_DEFENSE, POS_FACEUP_ATTACK, POS_FACEUP_ATTACK) ~= 0 then
        local og = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_MZONE, nil)
        for tc in aux.Next(og) do
            local e1 = Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_SET_ATTACK_FINAL)
            e1:SetValue(0)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
            tc:RegisterEffect(e1)
            local e2 = e1:Clone()
            e2:SetCode(EFFECT_SET_DEFENSE_FINAL)
            tc:RegisterEffect(e2)
        end
    end
end

function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return c:IsPreviousLocation(LOCATION_MZONE) and c:IsReason(REASON_EFFECT)
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    local g = Duel.GetMatchingGroup(Card.IsType, tp, 0, LOCATION_MZONE, nil, TYPE_MONSTER)
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, g, #g, 0, 0)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(Card.IsType, tp, 0, LOCATION_MZONE, nil, TYPE_MONSTER)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
    end
end
