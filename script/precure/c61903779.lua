local s, id = GetID()

function s.initial_effect(c)
    -- Enable Pendulum mechanics
    Pendulum.AddProcedure(c)
    
    -------------------------------------------------------------------------
    -- PENDULUM EFFECTS
    -------------------------------------------------------------------------
    -- P-Effect 1: Monsters cannot be destroyed by battle
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e1:SetRange(LOCATION_PZONE)
    e1:SetTargetRange(LOCATION_MZONE, 0)
    e1:SetValue(1)
    c:RegisterEffect(e1)
    
    -- P-Effect 2: Battle damage you take is also inflicted to your opponent
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_BATTLE_DAMAGE)
    e2:SetRange(LOCATION_PZONE)
    e2:SetCondition(s.damcon)
    e2:SetOperation(s.damop)
    c:RegisterEffect(e2)
    
    -- P-Effect 3: Quick Effect -> Negate card/effect activation
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e3:SetRange(LOCATION_PZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.negcon)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)
    
    -------------------------------------------------------------------------
    -- MONSTER EFFECTS
    -------------------------------------------------------------------------
    -- M-Effect 1: Attacked while face-down -> Return attacker and clear ATK monsters
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 1))
    e4:SetCategory(CATEGORY_TOHAND + CATEGORY_DESTROY)
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e4:SetCode(EVENT_BATTLE_CONFIRM) -- Safely triggers before damage calculation when face-down
    e4:SetCondition(s.bouncecon)
    e4:SetTarget(s.bouncetg)
    e4:SetOperation(s.bounceop)
    c:RegisterEffect(e4)
    
    -- M-Effect 2: Quick Effect -> Discard 1 to negate card/effect activation
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 0))
    e5:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_CHAINING)
    e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1)
    e5:SetCondition(s.negcon)
    e5:SetCost(s.negcost)
    e5:SetTarget(s.negtg)
    e5:SetOperation(s.negop)
    c:RegisterEffect(e5)
end

-- =========================================================================
-- PENDULUM: Mutual Battle Damage Logic
-- =========================================================================
function s.damcon(e, tp, eg, ep, ev, re, r, rp)
    -- Triggers only if you took battle damage (ep == tp)
    return ep == tp
end

function s.damop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_CARD, 0, id)
    -- Inflict the exact same amount of damage to your opponent
    Duel.Damage(1 - tp, ev, REASON_EFFECT)
end

-- Shared Negation Condition & Targets (Used by e3 and e5)
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
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

-- =========================================================================
-- MONSTER EFFECT 1: Before Damage Calc Bounce & Wipe
-- =========================================================================
function s.bouncecon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    -- Check if it was in face-down Defense Position before this battle exchange step
    return c:IsFaceup() and c:IsPreviousPosition(POS_FACEDOWN_DEFENSE) 
        and Duel.GetAttacker() and Duel.GetAttacker():IsControler(1 - tp)
end

function s.desfilter(c)
    return c:IsPosition(POS_FACEUP_ATTACK)
end

function s.bouncetg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    local ac = Duel.GetAttacker()
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, ac, 1, 0, 0)
    
    local g = Duel.GetMatchingGroup(s.desfilter, tp, 0, LOCATION_MZONE, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, #g, 0, 0)
end

function s.bounceop(e, tp, eg, ep, ev, re, r, rp)
    local ac = Duel.GetAttacker()
    -- Step 1: Return the attacking monster to the hand
    if ac and ac:IsRelateToBattle() and Duel.SendtoHand(ac, nil, REASON_EFFECT) > 0 and ac:IsLocation(LOCATION_HAND) then
        -- Step 2: Clear all opponent's Attack Position monsters
        local g = Duel.GetMatchingGroup(s.desfilter, tp, 0, LOCATION_MZONE, nil)
        if #g > 0 then
            Duel.BreakEffect()
            Duel.Destroy(g, REASON_EFFECT)
        end
    end
end

-- =========================================================================
-- MONSTER EFFECT 2: Negate Cost
-- =========================================================================
function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, nil) end
    Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST + REASON_DISCARD, nil)
end
