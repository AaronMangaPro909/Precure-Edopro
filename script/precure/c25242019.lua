-- Cure Idol - God Idol Style
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
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_PIERCE)
    c:RegisterEffect(e5)
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e6:SetCode(EVENT_PRE_BATTLE_DAMAGE)
    e6:SetCondition(s.damcon)
    e6:SetOperation(s.damop)
    c:RegisterEffect(e6)
    
    local e7 = Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_SINGLE)
    e7:SetCode(EFFECT_UPDATE_ATTACK)
    e7:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e7:SetRange(LOCATION_MZONE)
    e7:SetValue(s.atkval)
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

function s.damcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local target = Duel.GetAttackTarget()
    return c == Duel.GetAttacker() and target and target:IsDefensePos() and target:IsControler(1 - tp)
end
function s.damop(e, tp, eg, ep, ev, re, r, rp)
    Duel.ChangeBattleDamage(ep, ev * 2)
end

function s.atkfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xb54)
end
function s.atkval(e, c)
    return Duel.GetMatchingGroupCount(s.atkfilter, e:GetHandlerPlayer(), LOCATION_MZONE, LOCATION_MZONE, nil) * 300
end
