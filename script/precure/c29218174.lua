-- The Princess of Prince Pharaoh Future Friendship

local s, id = GetID()

local CARD_DARK_MAGICIAN = 46986414
local CARD_CURE_FLORA    = 65935871 
local CARD_CURE_MERMAID  = 43290246 
local CARD_CURE_TWINKLE  = 1336311887 
local CARD_CURE_SCARLET  = 3325364110 

function s.initial_effect(c)
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_RECOVER + CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

function s.costfilter(c, e, tp)
    return c:IsLevel(4) and c:IsSetCard(0xb54)
end
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.CheckReleaseGroupCost(tp, s.costfilter, 1, false, nil, nil) end
    local g = Duel.SelectReleaseGroupCost(tp, s.costfilter, 1, 1, false, nil, nil)
    Duel.Release(g, REASON_COST)
end

function s.spfilter(c, code, e, tp)
    return c:IsCode(code) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        if Duel.GetLocationCount(tp, LOCATION_MZONE) < 5 then return false end
        if Duel.IsPlayerAffectedByEffect(tp, CARD_BLUEEYES_SPIRIT) then return false end 
           local targets = {CARD_DARK_MAGICIAN, CARD_CURE_FLORA, CARD_CURE_MERMAID, CARD_CURE_TWINKLE, CARD_CURE_SCARLET}
        for _, code in ipairs(targets) do
            if not Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, code, e, tp) then
                return false
            end
        end
        return true
    end
    Duel.SetOperationInfo(0, CATEGORY_RECOVER, nil, 0, tp, 4000)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 5, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    -- Gain 4000 LP first
    if Duel.Recover(tp, 4000, REASON_EFFECT) > 0 then
        if Duel.GetLocationCount(tp, LOCATION_MZONE) < 5 or Duel.IsPlayerAffectedByEffect(tp, CARD_BLUEEYES_SPIRIT) then return end
        
        Duel.BreakEffect()
        
        local targets = {CARD_DARK_MAGICIAN, CARD_CURE_FLORA, CARD_CURE_MERMAID, CARD_CURE_TWINKLE, CARD_CURE_SCARLET}
        local summon_group = Group.CreateGroup()
        
        for _, code in ipairs(targets) do
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, code, e, tp)
            if #g > 0 then
                summon_group:Merge(g)
            end
        end
        
        if #summon_group == 5 then
            local c = e:GetHandler()
            local tc = summon_group:GetFirst()
            
            while tc do
                if Duel.SpecialSummonStep(tc, 0, tp, tp, false, false, POS_FACEUP) then
                    local e1 = Effect.CreateEffect(c)
                    e1:SetType(EFFECT_TYPE_SINGLE)
                    e1:SetCode(EFFECT_UPDATE_ATTACK)
                    e1:SetValue(1200)
                    e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
                    tc:RegisterEffect(e1)
                end
                tc = summon_group:GetNext()
            end
            Duel.SpecialSummonComplete()
        end
    end
end
