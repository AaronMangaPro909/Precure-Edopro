-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

-- Card ID Constants & Archetypes
local CARD_LAURA = 29241544 -- !! CHANGE TO "Laura Apollodoros Hyginus La Mer"'S ID IF NEEDED !!
local CARD_MERMAID_AQUA_PACT = 16586117 -- !! CHANGE TO "Mermaid Aqua Pact"'S ID IF NEEDED !!
local ARCHETYPE_PRECURE = 0xb54

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- 1. Always treated as "Laura Apollodoros Hyginus La Mer"
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e0:SetCode(EFFECT_CHANGE_CODE)
    e0:SetRange(LOCATION_MZONE + LOCATION_GRAVE + LOCATION_HAND + LOCATION_DECK + LOCATION_REMOVED)
    e0:SetValue(CARD_LAURA)
    c:RegisterEffect(e0)
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_SPSUMMON_PROC)
    e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e2:SetRange(LOCATION_HAND)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    -- Alternative Special Summon via "Mermaid Aqua Pact" handled on the spell itself or generic check if needed

    -- 3. Hand Trap Quick Effect: Send this card + 1 "Precure" card from hand/field to negate activation & destroy
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e3:SetRange(LOCATION_HAND)
    e3:SetCondition(s.negcon)
    e3:SetCost(s.negcost)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)

    -- 4. If banished: Add to hand (Hard Once Per Turn)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 1))
    e4:SetCategory(CATEGORY_TOHAND)
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_REMOVE)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCountLimit(1, id)
    e4:SetTarget(s.thtg)
    e4:SetOperation(s.thop)
    c:RegisterEffect(e4)
end

s.listed_names = {CARD_LAURA, CARD_MERMAID_AQUA_PACT}

-------------------------------------------------------------------------
-- SPECIAL SUMMON PROCEDURE LOGIC
-------------------------------------------------------------------------
function s.spfilter(c, tp)
    return (c:IsCode(CARD_LAURA) or c:IsSetCard(ARCHETYPE_PRECURE)) and (c:IsControler(tp) or c:IsFaceup()) and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_MZONE))
end

function s.spcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    local rg = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, c, tp)
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and #rg > 0
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, c)
    local rg = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, c, tp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RELEASE)
    local g = rg:Select(tp, 1, 1, nil)
    if #g > 0 then
        g:KeepAlive()
        e:SetLabelObject(g)
        return true
    end
    return false
end

function s.spop(e, tp, eg, ep, ev, re, r, rp, c)
    local g = e:GetLabelObject()
    if not g then return end
    Duel.Release(g, REASON_COST)
    g:DeleteGroup()
end

-------------------------------------------------------------------------
-- HAND TRAP NEGATE LOGIC
-------------------------------------------------------------------------
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
end

function s.costfilter(c, tp)
    return c:IsSetCard(ARCHETYPE_PRECURE) and (c:IsLocation(LOCATION_HAND) or (c:IsFaceup() and c:IsLocation(LOCATION_MZONE)))
        and (c:IsAbleToGraveAsCost() or c:IsAbleToGrave())
end

function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:IsAbleToGraveAsCost() 
        and Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, c, tp) end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, c, tp)
    g:AddCard(c)
    Duel.SendtoGrave(g, REASON_COST)
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

-------------------------------------------------------------------------
-- BANISH RECOVERY LOGIC
-------------------------------------------------------------------------
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:IsAbleToHand() end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, c, 1, 0, 0)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoHand(c, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, c)
    end
end
