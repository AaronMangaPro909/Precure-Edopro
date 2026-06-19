local s, id = GetID()

function s.initial_effect(c)
    -- Continuous Trap basic activation link
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    
    -- Effect 1: End of Battle Phase -> Shuffle battled "Precure" monsters to Special Summon replacements
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_TODECK + CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_PHASE + PHASE_BATTLE) -- Triggers at the end of the Battle Phase
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1, id) -- HOPT
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
    
    -- Engine Tracking: Keep track of which "Precure" monsters battled this turn
    if not s.global_check then
        s.global_check = true
        local ge1 = Effect.CreateEffect(c)
        ge1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
        ge1:SetCode(EVENT_BATTLE_START)
        ge1:SetOperation(s.checkop)
        Duel.RegisterEffect(ge1, 0)
    end
end

local ARCH_PRECURE = 0xb54
local FLAG_BATTLED = id + 100

-- =========================================================
-- ENGINE: Flag monsters that engaged in battle
-- =========================================================
function s.checkop(e, tp, eg, ep, ev, re, r, rp)
    local a = Duel.GetAttacker()
    local d = Duel.GetAttackTarget()
    
    -- If attacker is a Precure, mark it
    if a and a:IsFaceup() and a:IsSetCard(ARCH_PRECURE) then
        a:RegisterFlagEffect(FLAG_BATTLED, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_BATTLE, 0, 1)
    end
    -- If defender is a Precure, mark it
    if d and d:IsFaceup() and d:IsSetCard(ARCH_PRECURE) then
        d:RegisterFlagEffect(FLAG_BATTLED, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_BATTLE, 0, 1)
    end
end

-- =========================================================
-- EFFECT 1: Shuffle & Special Summon Logic
-- =========================================================
function s.shfilter(c)
    -- Must be a face-up Precure monster on your field that has the battle flag tracking label and can go back to Deck
    return c:IsFaceup() and c:IsSetCard(ARCH_PRECURE) and c:GetFlagEffect(FLAG_BATTLED) > 0 and c:IsAbleToDeck()
end

function s.spfilter(c, e, tp)
    return c:IsSetCard(ARCH_PRECURE) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then 
        return Duel.IsExistingMatchingCard(s.shfilter, tp, LOCATION_MZONE, 0, 1, nil)
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp)
    end
    Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 1, tp, LOCATION_MZONE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    -- Find all available targets currently on the field
    local g = Duel.GetMatchingGroup(s.shfilter, tp, LOCATION_MZONE, 0, nil)
    if #g == 0 then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
    -- Let the player select any number (1 to maximum available)
    local sg = g:Select(tp, 1, #g, nil)
    if #sg == 0 then return end
    
    Duel.HintSelection(sg)
    local shuffle_count = Duel.SendtoDeck(sg, nil, SEQ_DECKTOP, REASON_EFFECT)
    
    -- Check if card numbers matches up and spaces are open to execute Special Summons
    if shuffle_count > 0 then
        -- Recalculate available Main Monster Zones
        local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
        if ft <= 0 then return end
        if ft < shuffle_count then shuffle_count = ft end -- Cap summons to remaining zone slots
        
        -- Pull eligible recruits from Deck
        local spg = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_DECK, 0, nil, e, tp)
        if #spg == 0 then return end
        
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local choice = spg:Select(tp, shuffle_count, shuffle_count, nil)
        if #choice > 0 then
            Duel.BreakEffect()
            Duel.SpecialSummon(choice, 0, tp, tp, false, false, POS_FACEUP)
        end
    end
end
