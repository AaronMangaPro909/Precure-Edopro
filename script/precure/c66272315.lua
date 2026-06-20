-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

function s.initial_effect(c)
    -- 1. Trigger Effect on Normal/Special Summon: Gain 1800 ATK/DEF, then search up to 2 "Precure" monsters
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_ATKCHANGE + CATEGORY_DEFCHANGE + CATEGORY_TOHAND + CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F) -- Mandatory trigger
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetTarget(s.statstg)
    e1:SetOperation(s.statsop)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)
    
    -- 2. Trigger Effect when sent to GY: Level 4 or higher "Precure" monsters gain 1500 ATK
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F) -- Mandatory trigger
    e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetTarget(s.atkvaltg)
    e3:SetOperation(s.atkvalop)
    c:RegisterEffect(e3)
    
    -- 3. Trigger Effect when destroyed by opponent's attack: Target 1 opponent monster, place this card in S/T zone, negate and freeze target
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O) -- Optional trigger
    e4:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e4:SetCode(EVENT_BATTLE_DESTROYED)
    e4:SetCondition(s.stcon)
    e4:SetTarget(s.sttg)
    e4:SetOperation(s.stop)
    c:RegisterEffect(e4)
end

-------------------------------------------------------------------------
-- 1. SUMMON STAT BOOST + SEARCH ENGINE
-------------------------------------------------------------------------
function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.statstg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetPossibleOperationInfo(0, CATEGORY_TOHAND, nil, 2, tp, LOCATION_DECK)
end
function s.statsop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    -- Apply 1800 ATK/DEF boost if the card is still valid on the field
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
    
    -- "Then" search up to 2 "Precure" monsters from Deck to hand
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

-------------------------------------------------------------------------
-- 2. GRAVEYARD MONSTER ATK BUFF ENGINE
-------------------------------------------------------------------------
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

-------------------------------------------------------------------------
-- 3. PLACEMENT SPELL/TRAP ZONE + NEGATION ENGINE (FIXED)
-------------------------------------------------------------------------
function s.stcon(e, tp, eg, ep, ev, re, r, rp)
    -- Verifies it was destroyed by an opponent's attacking monster and sent to your GY
    return e:GetHandler():IsPreviousControler(tp) and e:GetHandler():IsLocation(LOCATION_GRAVE)
end
function s.sttg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then 
        return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0 
            and Duel.IsExistingTarget(Card.IsType, tp, 0, LOCATION_MZONE, 1, nil, TYPE_MONSTER) 
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    local g = Duel.SelectTarget(tp, Card.IsType, tp, 0, LOCATION_MZONE, 1, 1, nil, TYPE_MONSTER)
    
    -- Structural state assignment to verify moving from GY to S/T Zone
    Duel.SetOperationInfo(0, CATEGORY_LEAVE_GRAVE, e:GetHandler(), 1, 0, 0)
end
function s.stop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    
    -- Check if S/T Zone has space and card is still in the GY
    if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 or not c:IsRelateToEffect(e) then return end
    
    -- Place this card face-up in your Spell & Trap Zone as a Continuous Spell
    if Duel.MoveToField(c, tp, tp, LOCATION_SZONE, POS_FACEUP, true) then
        -- Modify Card Type properties dynamically so the engine handles it as a Continuous Spell
        local e1 = Effect.CreateEffect(c)
        e1:SetCode(EFFECT_CHANGE_TYPE)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TOFIELD)
        c:RegisterEffect(e1)
        
        -- Apply attack restriction and dynamic negation effects to the targeted opponent monster
        if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
            -- 1. Cannot Attack
            local e2 = Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_CANNOT_ATTACK)
            e2:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e2)
            
            -- 2. Effects are Negated
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
