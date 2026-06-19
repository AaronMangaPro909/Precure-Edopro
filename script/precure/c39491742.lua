-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card IDs
local CARD_BLS             = 05405694 -- Official Black Luster Soldier ID
local CARD_CURE_FLORA      = 65935871 -- !! CHANGE THIS !! Replace with Cure Flora's ID
local CARD_CURE_MERMAID    = 43290246 -- !! CHANGE THIS !! Replace with Cure Mermaid's ID
local CARD_CURE_TWINKLE    = 1336311887 -- !! CHANGE THIS !! Replace with Cure Twinkle's ID
local CARD_CURE_SCARLET    = 3325364110 -- !! CHANGE THIS !! Replace with Cure Scarlet's ID


function s.initial_effect(c)
    -- Must be Fusion Summoned
    c:EnableReviveLimit()
    Fusion.AddProcMix(c, true, true, CARD_BLS, CARD_CURE_FLORA, CARD_CURE_MERMAID, CARD_CURE_TWINKLE, CARD_CURE_SCARLET)
    
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(aux.fuslimit)
    c:RegisterEffect(e0)
    
    -- 1. If Special Summoned: Mass Special Summon "Precure of Princess" from GY/Banished
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    -- 2. Battle Phase Quick Effect: Equip up to 4 "Precure of Princess" monsters
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_EQUIP)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(TIMING_BATTLE_PHASE, TIMING_BATTLE_PHASE + TIMINGS_CHECK_MONSTER)
    e2:SetCondition(s.eqcon)
    e2:SetTarget(s.eqtg)
    e2:SetOperation(s.eqop)
    c:RegisterEffect(e2)
    
    -- 3. Quick Effect: Negate Spell/Trap card or effect activation
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.negcon)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)
end

-- 1. Mass Special Summon Logic
function s.spfilter(c, e, tp)
    return (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) 
        and c:IsSetCard(0xb54) -- Using your Precure custom hex archetype identity
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE + LOCATION_REMOVED)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if ft <= 0 then return end
    if Duel.IsPlayerAffectedByEffect(tp, CARD_BLUEEYES_SPIRIT) then ft = 1 end
    
    local g = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, nil, e, tp)
    if #g == 0 then return end
    
    local sg = aux.SelectUnselectGroup(g, e, tp, 1, ft, aux.dncheck, 1, tp, HINTMSG_SPSUMMON)
    if #sg > 0 then
        Duel.SpecialSummon(sg, 0, tp, tp, false, false, LOCATION_MZONE)
    end
end

-- 2. Equip Logic (Up to 4)
function s.eqcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsBattlePhase()
end
function s.eqfilter(c)
    return (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsSetCard(0xb54) and c:IsType(TYPE_MONSTER)
end
function s.eqtg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then 
        local ft = Duel.GetLocationCount(tp, LOCATION_SZONE)
        return ft > 0 and Duel.IsExistingTarget(s.eqfilter, tp, LOCATION_MZONE + LOCATION_GRAVE, 0, 1, nil) 
    end
    
    local ft = Duel.GetLocationCount(tp, LOCATION_SZONE)
    local max_targets = math.min(ft, 4)
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_EQUIP)
    local g = Duel.SelectTarget(tp, s.eqfilter, tp, LOCATION_MZONE + LOCATION_GRAVE, 0, 1, max_targets, nil)
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, g, #g, 0, 0)
end
function s.eqop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
    
    local ft = Duel.GetLocationCount(tp, LOCATION_SZONE)
    if ft <= 0 then return end
    
    local g = Duel.GetTargetCards(e)
    if #g == 0 then return end
    
    local tc = g:GetFirst()
    while tc do
        if ft > 0 and (tc:IsLocation(LOCATION_GRAVE) or tc:IsFaceup()) then
            if Duel.Equip(tp, tc, c, true) then
                -- Add standard Equip card status properties rules safely
                local e1 = Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_EQUIP_LIMIT)
                e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e1:SetLabelObject(c)
                e1:SetValue(s.eqlimit)
                e1:SetReset(RESET_EVENT + RESETS_STANDARD)
                tc:RegisterEffect(e1)
                ft = ft - 1
            end
        end
        tc = g:GetNext()
    end
end
function s.eqlimit(e, c)
    return c == e:GetLabelObject()
end

-- 3. Negate Spell/Trap Logic
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev) and re:IsActiveType(TYPE_SPELL + TYPE_TRAP)
end
function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end
function s.negop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end
