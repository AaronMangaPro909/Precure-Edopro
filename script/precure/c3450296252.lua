local s, id = GetID()

function s.initial_effect(c)
    -- Link Materials: 1 "Cure Flora" + 2 Effect Monsters
    c:EnableReviveLimit()
    Link.AddProcedure(c, s.matfilter, 3, 3)
    
    -- Name handling: This card is always treated as "Cure Flora"
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_CHANGE_CODE)
    e0:SetValue(65935871) -- !!! REPLACE XXXXXXXX with the 8-digit ID of your original "Cure Flora"
    c:RegisterEffect(e0)
    
    -- Summon Restriction: Cannot be Normal Summoned/Set. 
    -- Must be Special Summoned by Link Summon or by a "Cure" Spell effect.
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    e1:SetValue(s.splimit)
    c:RegisterEffect(e1)
    
    -- Core Core Trigger: Gains effects if Summoned from the Extra Deck
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetCondition(s.gaincon)
    e2:SetOperation(s.gainop)
    c:RegisterEffect(e2)
end

-- Link Marker definitions (Top = 0x8, Right = 0x2, Bottom-Right = 0x4)
-- Combined Link Marker Hex value in DB should be: 0xe (14 decimal)

-- Material filters
function s.matfilter(c, lc, sumtype, tp)
    if not c:IsType(TYPE_EFFECT, lc, sumtype, tp) then return false end
    -- The first material must check out to be "Cure Flora"
    return c:IsCode(65935871) or c:IsHasEffect(EFFECT_CHANGE_CODE) -- !!! REPLACE XXXXXXXX with original "Cure Flora" ID
end

-- Summoning Condition validator
function s.splimit(e, se, sp, st)
    -- Allows Link Summoning
    if (st & SUMMON_TYPE_LINK) == SUMMON_TYPE_LINK then return true end
    -- Allows Special Summoning by a "Cure" Spell card effect (Archetype 0x5f1)
    return se and se:GetHandler():IsSetCard(0xb54) and se:GetHandler():IsType(TYPE_SPELL)
end

-- Condition: Check if summoned from the Extra Deck
function s.gaincon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsPreviousLocation(LOCATION_EXTRA)
end

-- Apply the bonus effects dynamically upon successful Extra Deck Summon
function s.gainop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    
    -- Effect A: Add 1 "Cure" Spell from Deck to hand
    local ea = Effect.CreateEffect(c)
    ea:SetDescription(aux.Stringid(id, 0))
    ea:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    ea:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F) -- Mandatory trigger
    ea:SetCode(EVENT_SPSUMMON_SUCCESS)
    ea:SetTarget(s.thtg)
    ea:SetOperation(s.thop)
    ea:SetReset(RESET_EVENT + RESETS_STANDARD)
    c:RegisterEffect(ea)
    
    -- Effect B: Quick Effect -> Activate 1 "Cure" Spell from hand during Battle Phase
    local eb = Effect.CreateEffect(c)
    eb:SetDescription(aux.Stringid(id, 1))
    eb:SetType(EFFECT_TYPE_QUICK_O)
    eb:SetCode(EVENT_FREE_CHAIN)
    eb:SetRange(LOCATION_MZONE)
    eb:SetCountLimit(1)
    eb:SetCondition(s.actcon)
    eb:SetTarget(s.acttg)
    eb:SetOperation(s.actop)
    eb:SetReset(RESET_EVENT + RESETS_STANDARD)
    c:RegisterEffect(eb)
end

-- =========================================================
-- EFFECT A: Search "Cure" Spell Logic
-- =========================================================
function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end -- Mandatory trigger skips 0 check for safety
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

-- =========================================================
-- EFFECT B: Hand Spell Activation Logic
-- =========================================================
function s.actfilter(c, tp)
    return c:IsSetCard(0x5f1) and c:IsType(TYPE_SPELL) and c:CheckActivateEffect(true, true, false) ~= nil
end

function s.actcon(e, tp, eg, ep, ev, re, r, rp)
    -- Only usable during the Battle Phase of either player
    local ph = Duel.GetCurrentPhase()
    return ph >= PHASE_BATTLE_START and ph <= PHASE_BATTLE
end

function s.acttg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
        and Duel.IsExistingMatchingCard(s.actfilter, tp, LOCATION_HAND, 0, 1, nil, tp) end
end

function s.actop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
    local g = Duel.SelectMatchingCard(tp, s.actfilter, tp, LOCATION_HAND, 0, 1, 1, nil, tp)
    if #g > 0 then
        local tc = g:GetFirst()
        local tpe = tc:GetType()
        local te = tc:GetActivateEffect()
        local tg = te:GetTarget()
        local op = te:GetOperation()
        
        -- Move the spell to field and execute activation chains safely
        Duel.MoveToField(tc, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
        Duel.Hint(HINT_CARD, 0, tc:GetCode())
        tc:CreateEffectRelation(te)
        
        if (tpe & TYPE_EQUIP + TYPE_CONTINUOUS + TYPE_FIELD) == 0 and not tc:IsType(TYPE_FIELD) then
            tc:CancelToGrave(false)
        end
        
        if tg then tg(te, tp, eg, ep, ev, re, r, rp, 1) end
        local marg = Duel.GetChainInfo(0, CHAININFO_TARGET_CARDS)
        if marg then
            local mgc = marg:GetFirst()
            while mgc do
                mgc:CreateEffectRelation(te)
                mgc = marg:GetNext()
            end
        end
        if op then op(te, tp, eg, ep, ev, re, r, rp) end
        tc:ReleaseEffectRelation(te)
        if marg then
            local mgc = marg:GetFirst()
            while mgc do
                mgc:ReleaseEffectRelation(te)
                mgc = marg:GetNext()
            end
        end
    end
end
