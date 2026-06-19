-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- ID Configuration
local CARD_TOON_WORLD = 15259703 -- Official Konami ID for Toon World

function s.initial_effect(c)
    -- Spell Counter Permit (Max 5)
    c:EnableCounterPermit(0x1)
    c:SetCounterLimit(0x1, 5)
    
    -- 1. Name becomes "Cure Idol" while on the field
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_CHANGE_CODE)
    e1:SetRange(LOCATION_MZONE)
    -- Replace 12345678 with the actual 8-digit ID of "Cure Idol" if it exists as its own card
    e1:SetValue(39517403) 
    c:RegisterEffect(e1)
    
    -- 2. Normal Summoned -> Place 1 Spell Counter
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_COUNTER)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetTarget(s.cntg1)
    e2:SetOperation(s.cnop1)
    c:RegisterEffect(e2)
    
    -- 3. Special Summoned + Toon World -> Place 2 Spell Counters
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_COUNTER)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCondition(s.cncon2)
    e3:SetTarget(s.cntg2)
    e3:SetOperation(s.cnop2)
    c:RegisterEffect(e3)
    
    -- 4. Gains 500 ATK for each Spell Counter
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_UPDATE_ATTACK)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetValue(s.atkval)
    c:RegisterEffect(e4)
    
    -- 5. Remove 1 Counter -> Destroy 1 opponent's monster (Baseline)
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 2))
    e5:SetCategory(CATEGORY_DESTROY)
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCost(s.descost)
    e5:SetTarget(s.destg)
    e5:SetOperation(s.desop)
    c:RegisterEffect(e5)
    
    -- 6. Place Counter on opponent Trap resolution
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e6:SetCode(EVENT_CHAIN_SOLVED)
    e6:SetRange(LOCATION_MZONE)
    e6:SetOperation(s.recsop)
    c:RegisterEffect(e6)
end

-- E2: Normal Summon counter logic
function s.cntg1(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_COUNTER, nil, 1, 0, 0x1)
end
function s.cnop1(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        c:AddCounter(0x1, 1)
    end
end

-- E3: Special Summon counter logic
function s.cncon2(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, CARD_TOON_WORLD), tp, LOCATION_ONFIELD, 0, 1, nil)
end
function s.cntg2(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_COUNTER, nil, 2, 0, 0x1)
end
function s.cnop2(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        c:AddCounter(0x1, 2)
    end
end

-- E4: ATK Calculation
function s.atkval(e, c)
    return c:GetCounter(0x1) * 500
end

-- E5: Monster Removal Logic (Destruction baseline)
function s.descost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsCanRemoveCounter(tp, 0x1, 1, REASON_COST) end
    e:GetHandler():RemoveCounter(tp, 0x1, 1, REASON_COST)
end
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.IsExistingTarget(nil, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectTarget(tp, nil, tp, 0, LOCATION_MZONE, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Destroy(tc, REASON_EFFECT)
    end
end

-- E6: Opponent Trap placement logic
function s.recsop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    -- Checks if the resolved chain item belongs to the opponent, is a Trap, and this card hasn't hit its counter ceiling
    if rp ~= tp and re:IsActiveType(TYPE_TRAP) and c:GetCounter(0x1) < 5 then
        c:AddCounter(0x1, 1)
    end
end
