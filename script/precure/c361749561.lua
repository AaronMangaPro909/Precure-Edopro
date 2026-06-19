--nope

-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card IDs
local CARD_FLORA        = 65935871 -- Replace with Cure Flora's ID
local CARD_MODE_ELEGANT = 22222222 -- Replace with Mode Elegant's ID

function s.initial_effect(c)
    -- 1. Activation Condition Check
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCondition(s.actcon)
    e1:SetOperation(s.actop)
    c:RegisterEffect(e1)
    
    -- 2. Lock down opponent's Spell/Trap actions
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_ACTIVATE)
    e2:SetRange(LOCATION_SZONE)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetTargetRange(0, 1) 
    e2:SetCondition(s.lockcon)
    e2:SetValue(s.aclimit)
    c:RegisterEffect(e2)
    local e3 = e2:Clone()
    e3:SetCode(EFFECT_CANNOT_SSET)
    e3:SetValue(s.setlimit)
    c:RegisterEffect(e3)
    
    -- 3. Negate opponent's face-up Spell/Trap Cards
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_DISABLE)
    e4:SetRange(LOCATION_SZONE)
    e4:SetTargetRange(0, LOCATION_SZONE)
    e4:SetCondition(s.lockcon)
    e4:SetTarget(s.negfilter)
    c:RegisterEffect(e4)
    
    -- 4. Mandatory Maintenance Cost: Standby Phase pay 900 LP or destroy
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 0))
    e5:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    e5:SetCode(EVENT_PHASE + PHASE_STANDBY)
    e5:SetRange(LOCATION_SZONE)
    e5:SetCountLimit(1)
    e5:SetCondition(s.maintcon)
    e5:SetOperation(s.maintop)
    c:RegisterEffect(e5)
end

-- 1. Activation Condition
function s.cfilter(c)
    return c:IsFaceup() and (c:IsCode(CARD_FLORA) or (c:IsCode(CARD_MODE_ELEGANT) and c:IsType(TYPE_LINK)))
end
function s.actcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_MZONE, 0, 1, nil)
end

-- Turn tracker initialization
function s.actop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        c:SetTurnCounter(0)
        -- FIXED: Hook to EVENT_TURN_END so it ticks exactly 1 time per global turn change
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
        e1:SetCode(EVENT_TURN_END)
        e1:SetCountLimit(1)
        e1:SetLabelObject(c)
        e1:SetOperation(s.turnop)
        Duel.RegisterEffect(e1, tp)
    end
end

-- 2 & 3. Validation rule filters
function s.lockcon(e)
    local tp = e:GetHandlerPlayer()
    return Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_MZONE, 0, 1, nil)
end
function s.aclimit(e, re, tp)
    return re:IsActiveType(TYPE_SPELL + TYPE_TRAP)
end
function s.setlimit(e, c, tp)
    return c:IsType(TYPE_SPELL + TYPE_TRAP)
end
function s.negfilter(e, c)
    return c:IsType(TYPE_SPELL + TYPE_TRAP)
end

-- 4. Maintenance Prompt logic
function s.maintcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnPlayer() == tp
end
function s.maintop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if Duel.CheckLPCost(tp, 900) then
        Duel.PayLPCost(tp, 900)
    else
        Duel.Destroy(c, REASON_COST)
    end
end

-- 5. FIXED: Increments 1 counter per turn structure safely
function s.florafilter(c)
    return c:IsFaceup() and c:IsCode(CARD_FLORA)
end
function s.turnop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetLabelObject()
    -- If this card is no longer active on the field, kill the background engine script
    if not c or not c:IsLocation(LOCATION_SZONE) then 
        e:Reset()
        return 
    end
    
    local ct = c:GetTurnCounter() + 1
    c:SetTurnCounter(ct)
    
    if ct == 10 then
        Duel.Hint(HINT_CARD, 0, id)
        if Duel.Destroy(c, REASON_EFFECT) ~= 0 then
            local dg = Duel.GetMatchingGroup(s.florafilter, tp, LOCATION_MZONE, 0, nil)
            if #dg > 0 then
                Duel.Destroy(dg, REASON_EFFECT)
            end
        end
        e:Reset()
    end
end
