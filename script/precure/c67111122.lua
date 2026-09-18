-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card ID Constants & Archetypes
local CARD_REDBE = 74677422 -- Red-Eyes Black Dragon
local CARD_ULTIMATE_LEADER_CURES = 75898994 -- !! CHANGE TO ULTIMATE LEADER CURES' ID IF NEEDED !!
local ARCHETYPE_REDEYES = 0x3b
local ARCHETYPE_PRECURE  = 0xb54

function s.initial_effect(c)
    -- Fusion Summon procedure ("Red-Eyes Black Dragon" + "Ultimate Leader Cures")
    c:EnableReviveLimit()
    Fusion.AddProcMix(c, true, true, CARD_REDBE, CARD_ULTIMATE_LEADER_CURES)

    -- 1. On Fusion Summon: Negate opponent's monster effects & make ATK/DEF 3000
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_DISABLE + CATEGORY_ATKCHANGE + CATEGORY_DEFCHANGE)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCondition(s.immcon)
    e1:SetTarget(s.immtg)
    e1:SetOperation(s.immop)
    c:RegisterEffect(e1)

    -- 2. Equip 1 "Red-Eyes" or "Precure" monster from Deck/hand (max 3)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_EQUIP)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetTarget(s.eqtg)
    e2:SetOperation(s.eqop)
    c:RegisterEffect(e2)

    -- 3. ATK boost per equipped card
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetRange(LOCATION_MZONE)
    e3:SetValue(s.atkval)
    c:RegisterEffect(e3)

    -- 4. Excavate top 5 cards and gain multiple attacks based on excavated monsters
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_DECKDES)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetTarget(s.atktg)
    e4:SetOperation(s.atkop)
    c:RegisterEffect(e4)

    -- 5. Piercing battle damage
    local e5 = Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_PIERCE)
    c:RegisterEffect(e5)

    -- 6. Quick Effect: Negate opponent's card/effect activation and destroy
    local e6 = Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id, 3))
    e6:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e6:SetType(EFFECT_TYPE_QUICK_O)
    e6:SetCode(EVENT_CHAINING)
    e6:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCondition(s.negcon)
    e6:SetTarget(s.negtg)
    e6:SetOperation(s.negop)
    c:RegisterEffect(e6)
end

s.listed_names = {CARD_REDBE, CARD_ULTIMATE_LEADER_CURES}

-------------------------------------------------------------------------
-- 1. FUSION SUMMON TRIGGER LOGIC (Negate & Set ATK/DEF to 3000)
-------------------------------------------------------------------------
function s.immcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.immtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, nil) end
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_MZONE, nil)
    Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, #g, 0, 0)
end

function s.immop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_MZONE, nil)
    for tc in aux.Next(g) do
        -- Negate effects
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2 = Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e2)

        -- Change ATK to 3000
        local e3 = Effect.CreateEffect(c)
        e3:SetType(EFFECT_TYPE_SINGLE)
        e3:SetCode(EFFECT_SET_ATTACK_FINAL)
        e3:SetValue(3000)
        e3:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e3)

        -- Change DEF to 3000
        local e4 = Effect.CreateEffect(c)
        e4:SetType(EFFECT_TYPE_SINGLE)
        e4:SetCode(EFFECT_SET_DEFENSE_FINAL)
        e4:SetValue(3000)
        e4:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e4)
    end
end

-------------------------------------------------------------------------
-- 2. EQUIP LOGIC (Max 3)
-------------------------------------------------------------------------
function s.eqfilter(c, tp, sc)
    return (c:IsSetCard(ARCHETYPE_REDEYES) or c:IsSetCard(ARCHETYPE_PRECURE)) 
        and c:IsType(TYPE_MONSTER) 
        and c:CheckUniqueOnField(tp) 
        and not c:IsForbidden()
end

function s.eqtg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then
        local ct = c:GetEquipGroup():FilterCount(s.eqcheck, nil)
        return ct < 3 and Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
            and Duel.IsExistingMatchingCard(s.eqfilter, tp, LOCATION_DECK + LOCATION_HAND, 0, 1, nil, tp, c)
    end
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, nil, 1, tp, LOCATION_DECK + LOCATION_HAND)
end

function s.eqcheck(c)
    -- Verify card was equipped by this effect or matches standard equipped parameters
    return c:GetFlagEffect(id) > 0
end

function s.eqop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 or not c:IsRelateToEffect(e) or c:IsFacedown() then return end
    local ct = c:GetEquipGroup():FilterCount(s.eqcheck, nil)
    if ct >= 3 then return end

    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_EQUIP)
    local g = Duel.SelectMatchingCard(tp, s.eqfilter, tp, LOCATION_DECK + LOCATION_HAND, 0, 1, 1, nil, tp, c)
    local tc = g:GetFirst()
    if tc then
        if not Duel.Equip(tp, tc, c, true) then return end
        tc:RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD, 0, 1)
        
        -- Equip limit setup
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_EQUIP_LIMIT)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetValue(s.eqlimit)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e1)
    end
end

function s.eqlimit(e, c)
    return c == e:GetOwner()
end

-------------------------------------------------------------------------
-- 3. ATK BOOST PER EQUIPPED CARD
-------------------------------------------------------------------------
function s.atkval(e, c)
    local g = c:GetEquipGroup():Filter(s.eqcheck, nil)
    return #g * 500
end

-------------------------------------------------------------------------
-- 4. EXCAVATE & MULTI-ATTACK LOGIC
-------------------------------------------------------------------------
function s.atktg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetFieldGroupCount(tp, LOCATION_DECK, 0) >= 5 end
end

function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetFieldGroupCount(tp, LOCATION_DECK, 0) < 5 then return end
    Duel.ConfirmDecktop(tp, 5)
    local g = Duel.GetDecktopGroup(tp, 5)
    local ct = g:FilterCount(s.excavfilter, nil)
    
    Duel.ShuffleDeck(tp)
    
    if ct > 0 then
        local c = e:GetHandler()
        if c:IsRelateToEffect(e) and c:IsFaceup() then
            local e1 = Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_EXTRA_ATTACK)
            e1:SetValue(ct - 1)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
            c:RegisterEffect(e1)
        end
    end
end

function s.excavfilter(c)
    return (c:IsSetCard(ARCHETYPE_REDEYES) or c:IsSetCard(ARCHETYPE_PRECURE)) and c:IsType(TYPE_MONSTER)
end

-------------------------------------------------------------------------
-- 5. QUICK EFFECT NEGATE (Opponent's Turn Only)
-------------------------------------------------------------------------
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnPlayer() ~= tp and rp ~= tp and Duel.IsChainNegatable(ev)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end
