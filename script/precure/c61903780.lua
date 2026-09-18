-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

function s.initial_effect(c)
    -- 1. Trigger Effect on Battle Confirmation (Flip/Attack exchange)
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 1))
    e1:SetCategory(CATEGORY_TOHAND + CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_BATTLE_CONFIRM)
    e1:SetCondition(s.bouncecon)
    e1:SetTarget(s.bouncetg)
    e1:SetOperation(s.bounceop)
    c:RegisterEffect(e1)
    
    -- 2. Quick Effect: Negate Activation by discarding 1 card
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetCondition(s.negcon)
    e2:SetCost(s.negcost)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)
end

-------------------------------------------------------------------------
-- EFFECT 1: BATTLE / FLIP-STYLE BOUNCE ENGINE
-------------------------------------------------------------------------
function s.bouncecon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    -- Check if it was flipped face-up from a face-down Defense Position and opponent's monster attacked
    return c:IsFaceup() and c:IsPreviousPosition(POS_FACEDOWN_DEFENSE) 
        and Duel.GetAttacker() and Duel.GetAttacker():IsControler(1 - tp)
end

function s.desfilter(c)
    return c:IsPosition(POS_FACEUP_ATTACK)
end

function s.bouncetg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    local ac = Duel.GetAttacker()
    if ac then
        Duel.SetOperationInfo(0, CATEGORY_TOHAND, ac, 1, 0, 0)
    end
    
    local g = Duel.GetMatchingGroup(s.desfilter, tp, 0, LOCATION_MZONE, nil)
    if #g > 0 then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, #g, 0, 0)
    end
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

-------------------------------------------------------------------------
-- EFFECT 2: QUICK EFFECT NEGATE ENGINE
-------------------------------------------------------------------------
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
end

function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, nil) end
    Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST + REASON_DISCARD, nil)
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
