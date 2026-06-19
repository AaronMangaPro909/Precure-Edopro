local s, id = GetID()

function s.initial_effect(c)
    -- Effect 1: This card can attack directly
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_DIRECT_ATTACK)
    c:RegisterEffect(e1)
    
    -- Effect 2: Inflict battle damage via direct attack -> Search 1 "Precure" card or text mention
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O) -- Optional Trigger ("You can")
    e2:SetCode(EVENT_BATTLE_DAMAGE)
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
end

-- Archetype ID setup (0xb54)
local ARCH_PRECURE = 0xb54

-- =========================================================
-- EFFECT 2: Direct Damage Condition & Search Logic
-- =========================================================
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    -- Checks if the damage was dealt to the opponent (ep ~= tp) and via a direct attack
    return ep ~= tp and Duel.GetAttacker() == e:GetHandler() and Duel.GetAttackTarget() == nil
end

function s.thfilter(c)
    -- Matches cards belonging to the archetype OR cards listing the archetype code in their database text data
    return (c:IsSetCard(ARCH_PRECURE) or c:ListsArchetype(ARCH_PRECURE)) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
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
