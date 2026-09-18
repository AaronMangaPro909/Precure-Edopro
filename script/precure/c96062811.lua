--キュアオルタナティブフローラ
-- Cure Alternative Flora
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e0:SetCode(EFFECT_CHANGE_CODE)
    e0:SetRange(LOCATION_MZONE + LOCATION_GRAVE)
    e0:SetValue(65935871)
    c:RegisterEffect(e0)
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_SPSUMMON_PROC)
    e2:SetProperty(EFFECT_FLAG_UNCOPYABLE + EFFECT_FLAG_CANNOT_DISABLE)
    e2:SetRange(LOCATION_HAND)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_CANNOT_ACTIVATE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e4:SetTargetRange(0, 1)
    e4:SetValue(s.aclimit)
    c:RegisterEffect(e4)
    local e5 = Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_DISABLE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetTarget(s.distg)
    c:RegisterEffect(e5)
    local e6 = Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id, 1))
    e6:SetCategory(CATEGORY_EQUIP)
    e6:SetType(EFFECT_TYPE_IGNITION)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCountLimit(1)
    e6:SetCondition(s.eqcon)
    e6:SetTarget(s.eqtg)
    e6:SetOperation(s.eqop)
    c:RegisterEffect(e6)
    local e7 = Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_SINGLE)
    e7:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e7:SetCode(EFFECT_UPDATE_ATTACK)
    e7:SetRange(LOCATION_MZONE)
    e7:SetValue(s.atkval)
    c:RegisterEffect(e7)
    local e8 = Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id, 2))
    e8:SetCategory(CATEGORY_DRAW)
    e8:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    e8:SetCode(EVENT_CHAINING)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCountLimit (1)
    e8:SetCondition(s.drcon)
    e8:SetTarget(s.drtg)
    e8:SetOperation(s.drop)
    c:RegisterEffect(e8)
end

s.listed_names = {65935871}

-- SPECIAL SUMMON PROCEDURE LOGIC (HOPT)
function s.spfilter(c, tp)
    return (c:IsCode(65935871) or (c:IsSetCard(0xb54) and c:IsOriginalCodeRule(65935871))) 
        and (c:IsControler(tp) or c:IsFaceup()) 
        and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_MZONE))
end

function s.spcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    -- Check HOPT restriction for this procedure
    if Duel.HasFlagEffect(tp, id) then return false end
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
    Duel.RegisterFlagEffect(tp, id, RESET_PHASE + PHASE_END, 0, 1)
    Duel.Release(g, REASON_COST)
    g:DeleteGroup()
end


-- ON SPECIAL SUMMON: ADD PRECURE CARDS
function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 2, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end


-- LOCK OPPONENT SPELLS/TRAPS
function s.aclimit(e, re, tp)
    return re:IsActiveType(TYPE_SPELL + TYPE_TRAP)
end

function s.distg(e, c)
    return c:IsControler(1 - e:GetHandlerPlayer()) and c:IsType(TYPE_SPELL + TYPE_TRAP)
end

-- Battle Equip and cannot it.
function s.eqcon(e, tp, eg, ep, ev, re, r, rp)
    local ph = Duel.GetCurrentPhase()
    return ph >= PHASE_BATTLE_START and ph <= PHASE_BATTLE
end

function s.eqfilter(c, tp, sc)
    return (c:IsCode(65935871) or c:IsOriginalCodeRule(65935871)) 
        and c:IsType(TYPE_MONSTER) 
        and c:CheckUniqueOnField(tp) 
        and not c:IsForbidden()
end

function s.eqcheck(c)
    return c:GetFlagEffect(id) > 0
end

function s.eqtg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then
        local ct = c:GetEquipGroup():FilterCount(s.eqcheck, nil)
        return ct < 2 and Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
            and Duel.IsExistingMatchingCard(s.eqfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, tp, c)
    end
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.eqop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 or not c:IsRelateToEffect(e) or c:IsFacedown() then return end
    local ct = c:GetEquipGroup():FilterCount(s.eqcheck, nil)
    if ct >= 2 then return end

    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_EQUIP)
    local g = Duel.SelectMatchingCard(tp, s.eqfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, tp, c)
    local tc = g:GetFirst()
    if tc then
        if not Duel.Equip(tp, tc, c, true) then return end
        tc:RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD, 0, 1)
        
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_EQUIP_LIMIT)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetValue(s.eqlimit)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e1)
    end
end

function s.eqlimit(e, c)
    return c == e:GetOwner()
end

function s.atkval(e, c)
    local g = c:GetEquipGroup():Filter(s.eqcheck, nil)
    return math.min(#g, 2) * 500
end

-------------------------------------------------------------------------
-- AUTO DRAW ON OPPONENT'S TURN WHEN CARD/EFFECT ACTIVATED
-------------------------------------------------------------------------
function s.drcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnPlayer() ~= tp and rp == tp
end

function s.drtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(1)
    Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 1, tp, 1)
end

function s.drop(e, tp, eg, ep, ev, re, r, rp)
    local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
    Duel.Draw(p, d, REASON_EFFECT)
end
