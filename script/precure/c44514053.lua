-- Ultimate Cure Idol
local s, id = GetID()
local CARD_IDOL_HEART_RIBBON    = 4626483
local CARD_GOD_IDOL_STYLE       = 25242019
local CARD_INSERT_NAME          = 74677422 -- this code as Unknown Cure Idol form.
local CARD_STAGE_RIBBON         = 14244306

local CARD_CURE_IDOL            = 39517403
local CARD_CURE_WINK            = 21287436
local CARD_CURE_KYUN            = 26805130
local CARD_CURE_ZUKYOON         = 19379373
local CARD_CURE_KISS            = 60519833


function s.initial_effect(c)
    c:EnableReviveLimit()
    Fusion.AddProcMix(c, true, true, CARD_IDOL_HEART_RIBBON, CARD_GOD_IDOL_STYLE, CARD_INSERT_NAME)
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(aux.fuslimit)
    c:RegisterEffect(e0)
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_ATKCHANGE + CATEGORY_DEFCHANGE)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetTarget(s.atktg)
    e1:SetOperation(s.atkop)
    c:RegisterEffect(e1)
    -- Add 1 "Precure Stage Ribbon"
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1, id)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_PIERCE)
    c:RegisterEffect(e3)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_LEAVE_GRAVE + CATEGORY_EQUIP + CATEGORY_ATKCHANGE)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetCondition(s.eqcon)
    e4:SetTarget(s.eqtg)
    e4:SetOperation(s.eqop)
    c:RegisterEffect(e4)
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 3))
    e5:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_CHAINING)
    e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1)
    e5:SetCondition(s.negcon)
    e5:SetTarget(s.negtg)
    e5:SetOperation(s.negop)
    c:RegisterEffect(e5)
end

s.listed_names = {
    CARD_IDOL_HEART_RIBBON, 
    CARD_GOD_IDOL_STYLE, 
    CARD_INSERT_NAME, 
    CARD_STAGE_RIBBON,
    CARD_CURE_IDOL,
    CARD_CURE_WINK,
    CARD_CURE_KYUN,
    CARD_CURE_ZUKYOON,
    CARD_CURE_KISS
}

function s.atktg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, nil) end
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_MZONE, nil)
    Duel.SetOperationInfo(0, CATEGORY_ATKCHANGE, g, #g, 0, -1000)
    Duel.SetOperationInfo(0, CATEGORY_DEFCHANGE, g, #g, 0, -1000)
end

function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_MZONE, nil)
    if #g > 0 then
        for tc in aux.Next(g) do
            local e1 = Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(-1000)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e1)
            local e2 = e1:Clone()
            e2:SetCode(EFFECT_UPDATE_DEFENSE)
            tc:RegisterEffect(e2)
        end
    end
end

function s.thfilter(c)
    return c:IsCode(CARD_STAGE_RIBBON) and c:IsAbleToHand()
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

function s.eqcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsMainPhase() == false and (Duel.GetCurrentPhase() >= PHASE_BATTLE_START and Duel.GetCurrentPhase() <= PHASE_BATTLE)
end

function s.eqfilter(c, e, tp)
    return c:IsCode(CARD_CURE_IDOL, CARD_CURE_WINK, CARD_CURE_KYUN, CARD_CURE_ZUKYOON, CARD_CURE_KISS)
        and c:CheckUniqueOnField(tp, LOCATION_SZONE)
        and not c:IsForbidden()
end

function s.eqtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.eqfilter(chkc, e, tp) end
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
        and Duel.IsExistingTarget(s.eqfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_EQUIP)
    local g = Duel.SelectTarget(tp, s.eqfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, g, 1, 0, 0)
end

function s.eqop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        if not Duel.Equip(tp, tc, c, true) then return end
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_EQUIP_LIMIT)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        e1:SetValue(function(e, c) return c == e:GetOwner() end)
        tc:RegisterEffect(e1)
        
        -- Gains 1000 ATK
        local e2 = Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_UPDATE_ATTACK)
        e2:SetValue(1000)
        e2:SetReset(RESET_EVENT + RESETS_STANDARD)
        c:RegisterEffect(e2)
    end
end

function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnPlayer() ~= tp and rp ~= tp and Duel.IsChainNegatable(ev)
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
