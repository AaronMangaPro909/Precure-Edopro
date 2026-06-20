-- Cure Spicy
local s, id = GetID()

function s.initial_effect(c)
    
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_ATKCHANGE + CATEGORY_DEFCHANGE + CATEGORY_TOHAND + CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetTarget(s.statstg)
    e1:SetOperation(s.statsop)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)

    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetTarget(s.atkvaltg)
    e3:SetOperation(s.atkvalop)
    c:RegisterEffect(e3)
    
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e4:SetCode(EVENT_BATTLE_DESTROYED)
    e4:SetCondition(s.stcon)
    e4:SetTarget(s.sttg)
    e4:SetOperation(s.stop)
    c:RegisterEffect(e4)
end

function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.statstg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetPossibleOperationInfo(0, CATEGORY_TOHAND, nil, 2, tp, LOCATION_DECK)
end
function s.statsop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(1800)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE + RESET_PHASE + PHASE_END)
        c:RegisterEffect(e1)
        local e2 = e1:Clone()
        e2:SetCode(EFFECT_UPDATE_DEFENSE)
        c:RegisterEffect(e2)
    end
    
    local g = Duel.GetMatchingGroup(s.thfilter, tp, LOCATION_DECK, 0, nil)
    if #g > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
        local sg = g:Select(tp, 1, 2, nil) -- Allows selecting up to 2
        if #sg > 0 then
            Duel.SendtoHand(sg, nil, REASON_EFFECT)
            Duel.ConfirmCards(1 - tp, sg)
        end
    end
end

function s.atkfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xb54) and c:IsLevelAbove(4)
end
function s.atkvaltg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    local g = Duel.GetMatchingGroup(s.atkfilter, tp, LOCATION_MZONE, 0, nil)
    Duel.SetOperationInfo(0, CATEGORY_ATKCHANGE, g, #g, tp, 1500)
end
function s.atkvalop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(s.atkfilter, tp, LOCATION_MZONE, 0, nil)
    for tc in aux.Next(g) do
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(1500)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e1)
    end
end

function s.stcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsPreviousControler(tp) and e:GetHandler():IsLocation(LOCATION_GRAVE)
end
function s.sttg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then 
        return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0 
            and Duel.IsExistingTarget(Card.IsType, tp, 0, LOCATION_MZONE, 1, nil, TYPE_MONSTER) 
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    local g = Duel.SelectTarget(tp, Card.IsType, tp, 0, LOCATION_MZONE, 1, 1, nil, TYPE_MONSTER)
    Duel.SetOperationInfo(0, CATEGORY_LEAVE_GRAVE, e:GetHandler(), 1, 0, 0)
end
function s.stop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    
    if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 or not c:IsRelateToEffect(e) then return end
       if Duel.MoveToField(c, tp, tp, LOCATION_SZONE, POS_FACEUP, true) then
        local e1 = Effect.CreateEffect(c)
        e1:SetCode(EFFECT_CHANGE_TYPE)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetValue(TYPE_TRAP + TYPE_CONTINUOUS)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TOFIELD)
        c:RegisterEffect(e1)
        
        if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
            local e2 = Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_CANNOT_ATTACK)
            e2:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e2)
            
            local e3 = Effect.CreateEffect(c)
            e3:SetType(EFFECT_TYPE_SINGLE)
            e3:SetCode(EFFECT_DISABLE)
            e3:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e3)
            
            local e4 = Effect.CreateEffect(c)
            e4:SetType(EFFECT_TYPE_SINGLE)
            e4:SetCode(EFFECT_DISABLE_EFFECT)
            e4:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e4)
        end
    end
end
