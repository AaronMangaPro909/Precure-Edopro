local s, id = GetID()

local CARD_ARCANA_SHADOW = 52303611
local CARD_BUSTER_BLADER  = 78193831

function s.initial_effect(c)
    Pendulum.AddProcedure(c)
    c:EnableReviveLimit()
    Fusion.AddProcMix(c, true, true, CARD_ARCANA_SHADOW, CARD_BUSTER_BLADER)
    
    local p1 = Effect.CreateEffect(c)
    p1:SetType(EFFECT_TYPE_FIELD)
    p1:SetCode(EFFECT_UPDATE_ATTACK)
    p1:SetRange(LOCATION_PZONE)
    p1:SetTargetRange(LOCATION_MZONE, 0)
    p1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard, 0xb54))
    p1:SetValue(1000)
    c:RegisterEffect(p1)
    
    local p2 = Effect.CreateEffect(c)
    p2:SetType(EFFECT_TYPE_FIELD)
    p2:SetCode(EFFECT_UPDATE_ATTACK)
    p2:SetRange(LOCATION_PZONE)
    p2:SetTargetRange(0, LOCATION_MZONE)
    p2:SetTarget(s.pdeftg)
    p2:SetValue(-1000)
    c:RegisterEffect(p2)
    local p3 = p2:Clone()
    p3:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(p3)
    
    local p4 = Effect.CreateEffect(c)
    p4:SetDescription(aux.Stringid(id, 0))
    p4:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    p4:SetType(EFFECT_TYPE_QUICK_O)
    p4:SetCode(EVENT_CHAINING)
    p4:SetRange(LOCATION_PZONE)
    p4:SetCountLimit(1)
    p4:SetCondition(s.pnegcon)
    p4:SetTarget(s.pnegtg)
    p4:SetOperation(s.pnegop)
    c:RegisterEffect(p4)
   
    local m1 = Effect.CreateEffect(c)
    m1:SetType(EFFECT_TYPE_SINGLE)
    m1:SetCode(EFFECT_UPDATE_ATTACK)
    m1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    m1:SetRange(LOCATION_MZONE)
    m1:SetValue(s.matkval)
    c:RegisterEffect(m1)
    
    local m2 = Effect.CreateEffect(c)
    m2:SetDescription(aux.Stringid(id, 1))
    m2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    m2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    m2:SetCode(EVENT_SPSUMMON_SUCCESS)
    m2:SetProperty(EFFECT_FLAG_DELAY)
    m2:SetCondition(s.mspcon)
    m2:SetTarget(s.msptg)
    m2:SetOperation(s.mspop)
    c:RegisterEffect(m2)
    
    local m3 = Effect.CreateEffect(c)
    m3:SetDescription(aux.Stringid(id, 2))
    m3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    m3:SetCode(EVENT_DESTROYED)
    m3:SetProperty(EFFECT_FLAG_DELAY)
    m3:SetCondition(s.pencon)
    m3:SetTarget(s.pentg)
    m3:SetOperation(s.penop)
    c:RegisterEffect(m3)
    
    local m4 = Effect.CreateEffect(c)
    m4:SetDescription(aux.Stringid(id, 3))
    m4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    m4:SetCode(EVENT_PHASE + PHASE_STANDBY)
    m4:SetRange(LOCATION_MZONE)
    m4:SetCountLimit(1)
    m4:SetCondition(s.maintcon)
    m4:SetOperation(s.maintop)
    c:RegisterEffect(m4)
end

function s.pdeftg(e, c)
    return c:IsFaceup() and (c:IsRace(RACE_DRAGON) or c:IsRace(RACE_SPELLCASTER))
end
function s.pnegcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
end
function s.pnegtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end
function s.pnegop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end

function s.matkfilter(c)
    return c:IsFaceup() and (c:IsRace(RACE_DRAGON) or c:IsRace(RACE_SPELLCASTER))
end
function s.matkval(e, c)
    return Duel.GetMatchingGroupCount(s.matkfilter, e:GetHandlerPlayer(), 0, LOCATION_MZONE, nil) * 1000
end

function s.mspcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.mgyfilter(c, e, tp)
    return c:IsCode(CARD_ARCANA_SHADOW) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.msptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.mgyfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE)
end
function s.mspop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.mgyfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, LOCATION_MZONE)
    end
end

function s.pencon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return c:IsPreviousLocation(LOCATION_MZONE) and c:IsFaceup() and c:IsReason(REASON_EFFECT + REASON_BATTLE) and rp ~= tp
end
function s.pentg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.CheckPendulumZones(tp) end
end
function s.penop(e, tp, eg, ep, ev, re, r, rp)
    if not Duel.CheckPendulumZones(tp) then return end
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.MoveToField(c, tp, tp, LOCATION_PZONE, POS_FACEUP, true)
    end
end

function s.maintcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnPlayer() == tp
end
function s.maintop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if Duel.CheckLPCost(tp, 900) and Duel.SelectYesNo(tp, aux.Stringid(id, 4)) then
        Duel.PayLPCost(tp, 900)
    else
    
        Duel.Destroy(c, REASON_COST)
    end
end
