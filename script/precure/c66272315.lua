-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

function s.initial_effect(c)
    -- 1. Trigger Effect on Normal/Special Summon: Gain 1800 ATK/DEF + Add 2 "Precure" monsters from Deck
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_ATKCHANGE + CATEGORY_DEFCHANGE + CATEGORY_TOHAND + CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F) -- Mandatory trigger for the stat gains
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)
    
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F) -- Mandatory trigger
    e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetTarget(s.atktg)
    e3:SetOperation(s.atkop)
    c:RegisterEffect(e3)
    
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_DISABLE)
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O) -- Optional trigger
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_BATTLE_DESTROYED)
    e4:SetCondition(s.tfcon)
    e4:SetTarget(s.tftg)
    e4:SetOperation(s.tfop)
    c:RegisterEffect(e4)
end

-------------------------------------------------------------------------
-- 1. SUMMON STAT GAIN & SEARCH ENGINE
-------------------------------------------------------------------------
function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_ATKCHANGE, e:GetHandler(), 1, tp, 1800)
    Duel.SetOperationInfo(0, CATEGORY_DEFCHANGE, e:GetHandler(), 1, tp, 1800)
    -- We announce the search as a possible operation info since the player must have 2 valid targets to execute it
    Duel.SetPossibleOperationInfo(0, CATEGORY_TOHAND, nil, 2, tp, LOCATION_DECK)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    -- Apply the 1800 ATK/DEF boost first
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
    
    -- Then, you can add 2 "Precure" monsters from Deck to Hand
    local g = Duel.GetMatchingGroup(s.thfilter, tp, LOCATION_DECK, 0, nil)
    if #g >= 2 and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
        Duel.BreakEffect()
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
        local sg = g:Select(tp, 2, 2, nil)
        if #sg == 2 then
            Duel.SendtoHand(sg, nil, REASON_EFFECT)
            Duel.ConfirmCards(1 - tp, sg)
        end
    end
end

-------------------------------------------------------------------------
-- 2. GY FIELD ATK BOOST ENGINE
-------------------------------------------------------------------------
function s.atkfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xb54) and c:IsLevelAbove(4)
end
function s.atktg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    local g = Duel.GetMatchingGroup(s.atkfilter, tp, LOCATION_MZONE, 0, nil)
    Duel.SetOperationInfo(0, CATEGORY_ATKCHANGE, g, #g, tp, 1500)
end
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
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

-------------------------------------------------------------------------
-- 3. CONTINUOUS TRAP PLACE & FREEZE ENGINE
-------------------------------------------------------------------------
function s.tfcon(e, tp, eg, ep, ev, re, r, rp)
    -- Verifies it was destroyed by an opponent's attacking monster
    return e:GetHandler():IsReason(REASON_BATTLE) and ep ~= tp
end
function s.tftg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
        and Duel.IsExistingTarget(Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    local g = Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, 1, 0, 0)
end
function s.tfop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 or not c:IsRelateToEffect(e) then return end
    
    -- Place this card face-up in the Spell & Trap Zone as a Continuous Trap
    if Duel.MoveToField(c, tp, tp, LOCATION_SZONE, POS_FACEUP, true) then
        -- Change its card type to a Continuous Trap card rule modification
        local e1 = Effect.CreateEffect(c)
        e1:SetCode(EFFECT_CHANGE_TYPE)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetValue(TYPE_TRAP + TYPE_CONTINUOUS)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TOFIELD)
        c:RegisterEffect(e1)
        
        -- Resolve the freezing effects on the targeted opponent monster
        local tc = Duel.GetFirstTarget()
        if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
            Duel.BreakEffect()
            
            -- Cannot attack
            local e2 = Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_CANNOT_ATTACK)
            e2:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e2)
            
            -- Effects are negated
            local e3 = Effect.CreateEffect(c)
            e3:SetType(EFFECT_TYPE_SINGLE)
            e3:SetCode(EFFECT_DISABLE)
            e3:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e3)
            local e4 = e3:Clone()
            e4:SetCode(EFFECT_DISABLE_EFFECT)
            tc:RegisterEffect(e4)
        end
    end
end
