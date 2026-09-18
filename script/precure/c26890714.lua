--Precure of Princess: Cure Twinkle Mode Elegant
local s, id = GetID()
local CARD_TWINKLE = 1336311887 

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
    e1:SetValue(CARD_TWINKLE)
    c:RegisterEffect(e1)
   
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_ATKCHANGE)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_ATTACK_ANNOUNCE)
    e2:SetCondition(s.gaincon)
    e2:SetTarget(s.atktg)
    e2:SetOperation(s.atkop)
    c:RegisterEffect(e2)

    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.gaincon)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

function s.matfilter(c, lc, sumtype, tp)
    if c:IsCode(CARD_TWINKLE) then return true end
    return c:IsAttribute(ATTRIBUTE_LIGHT, lc, sumtype, tp)
end

-- Summon Condition Verification
function s.splimit(e, se, sp, st)
    if not se then return false end
    local sc = se:GetHandler()
    return sc:IsType(TYPE_SPELL) and sc:IsSetCard(0xb54)
end

function s.gaincon(e)
    return e:GetHandler():IsSummonLocation(LOCATION_EXTRA)
end

function s.atktg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    -- Must have an opponent target monster to attack and at least 1000 ATK to lose
    if chk == 0 then return Duel.GetAttackTarget() ~= nil and c:GetAttack() >= 1000 end
    Duel.SetOperationInfo(0, CATEGORY_ATKCHANGE, c, 1, tp, -1000)
end
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() and c:GetAttack() >= 1000 then
        
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(-1000)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE)
        if c:RegisterEffect(e1) then
            Duel.BreakEffect()
    
            local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_MZONE, nil)
            local tc = g:GetFirst()
            while tc do
                local e2 = Effect.CreateEffect(c)
                e2:SetType(EFFECT_TYPE_SINGLE)
                e2:SetCode(EFFECT_SET_ATTACK_FINAL)
                e2:SetValue(math.ceil(tc:GetAttack() / 2))
                e2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
                tc:RegisterEffect(e2)
                tc = g:GetNext()
            end
        end
    end
end


function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end
