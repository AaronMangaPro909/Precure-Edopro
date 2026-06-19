--Precure of Princess: Cure Mermaid Mode Elegant

local s, id = GetID()
local CARD_MERMAID = 43290246 

function s.initial_effect(c)
    c:EnableReviveLimit()
    Link.AddProcedure(c, s.matfilter, 3, 3)
    c:EnableUnsummonable()
   
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(s.splimit)
    c:RegisterEffect(e0)
 
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_CHANGE_CODE)
    e1:SetValue(CARD_MERMAID)
    c:RegisterEffect(e1)
   
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_ATKCHANGE)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetTarget(s.atktg)
    e2:SetOperation(s.atkop)
    c:RegisterEffect(e2)
    
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e3:SetCode(EVENT_SUMMON_SUCCESS)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.gycon)
    e3:SetTarget(s.gytg)
    e3:SetOperation(s.gyop)
    c:RegisterEffect(e3)
    local e4 = e3:Clone()
    e4:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e4)
end

function s.matfilter(c, lc, sumtype, tp)
    if c:IsCode(CARD_MERMAID) then return true end
    return c:IsAttribute(ATTRIBUTE_WATER, lc, sumtype, tp)
end

function s.splimit(e, se, sp, st)
    if not se then return false end
    local sc = se:GetHandler()
    
    return sc:IsType(TYPE_SPELL) and sc:IsSetCard(0xb54)
end

function s.atktg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    local c = e:GetHandler()
    if c:IsSummonLocation(LOCATION_EXTRA) then
        Duel.SetOperationInfo(0, CATEGORY_ATKCHANGE, nil, 1, tp, LOCATION_MZONE)
    end
end
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    if not e:GetHandler():IsSummonLocation(LOCATION_EXTRA) then return end
    
    local tg = Duel.GetMatchingGroup(Card.IsFaceup, tp, LOCATION_MZONE, LOCATION_MZONE, nil)
    local tc = tg:GetFirst()
    while tc do
        if tc:IsSetCard(0xb54) then
            local e1 = Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(1000)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
            tc:RegisterEffect(e1)
        end
        tc = tg:GetNext()
    end
end

function s.gycon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsSummonLocation(LOCATION_EXTRA) then return false end
    return eg:IsExists(function(tc) return tc:IsSetCard(0xb54) and c:GetLinkedGroup():IsContains(tc) end, 1, nil)
end
function s.gyfilter(c)
    return c:IsSetCard(0xb54) and c:IsAbleToHand()
end
function s.gytg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.IsExistingTarget(s.gyfilter, tp, LOCATION_GRAVE, 0, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectTarget(tp, s.gyfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, g, 1, 0, 0)
end
function s.gyop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoHand(tc, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, tc)
    end
end
