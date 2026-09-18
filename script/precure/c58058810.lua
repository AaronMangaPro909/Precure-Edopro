-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card ID Constants (Replace placeholders with actual IDs)
local CARD_CURE_ANSWER  = 45616636 -- !! CHANGE THIS !!
local CARD_CURE_MYSTIQUE = 61903779 -- !! CHANGE THIS !!

function s.initial_effect(c)
    -- Activate: Continuous Spell
    c:EnableCounterPermit(0x1) -- Enables Spell Counters (0x1)
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)

    -- 1. Place 1 Spell Counter each time opponent activates a Spell/Trap Card or effect (Max 10)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_SZONE)
    e2:SetOperation(s.ctrop)
    c:RegisterEffect(e2)

    -- 2. Replacement / Trigger effect when "Cure Answer" or "Cure Mystique" is destroyed by battle
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_DESTROYED)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DELAY)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCondition(s.spcon)
    e3:SetCost(s.spcost)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)
end

-------------------------------------------------------------------------
-- SPELL COUNTER ENGINE
-------------------------------------------------------------------------
function s.ctrop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if rp ~= tp and (re:IsActiveType(TYPE_SPELL + TYPE_TRAP)) then
        if c:GetCounter(0x1) < 10 then
            c:AddCounter(0x1, 1)
        end
    end
end

-------------------------------------------------------------------------
-- SPECIAL SUMMON ENGINE
-------------------------------------------------------------------------
function s.filter(c, e, tp)
    return (c:IsCode(CARD_CURE_ANSWER) or c:IsCode(CARD_CURE_MYSTIQUE))
        and c:IsReason(REASON_BATTLE)
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
        and (c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup()))
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(s.filter, 1, nil, e, tp)
end

function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():GetCounter(0x1) >= 1 end
    e:GetHandler():RemoveCounter(tp, 0x1, 1, REASON_COST)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsControler(tp) and s.filter(chkc, e, tp) end
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and eg:IsExists(s.filter, 1, nil, e, tp) end
    
    local g = eg:Filter(s.filter, nil, e, tp)
    if #g == 1 then
        Duel.SetTargetCard(g)
        Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, 1, tp, g:GetFirst():GetLocation())
    else
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sg = g:Select(tp, 1, 1, nil)
        Duel.SetTargetCard(sg)
        Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, sg, 1, tp, sg:GetFirst():GetLocation())
    end
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP)
    end
end
