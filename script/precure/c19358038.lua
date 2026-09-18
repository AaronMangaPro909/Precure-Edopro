-- Toon Cure Idol.
local s, id = GetID()
local CARD_TOON_WORLD  = 15259703 -- Toon World ID
local COUNTER_SPELL = 0x1 -- Standard Spell Counter

function s.initial_effect(c)
    c:EnableCounterPermit(COUNTER_SPELL)
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e0:SetCode(EFFECT_CHANGE_CODE)
    e0:SetRange(LOCATION_MZONE)
    e0:SetValue(39517403)
    c:RegisterEffect(e0)
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_COUNTER)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetTarget(s.sumtg)
    e1:SetOperation(s.sumop)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_COUNTER)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetTarget(s.spsumtg)
    e2:SetOperation(s.spsumop)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetValue(s.atkval)
    c:RegisterEffect(e3)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 1))
    e4:SetCategory(CATEGORY_CONTROL)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCost(s.ctrlcost)
    e4:SetTarget(s.ctrltg)
    e4:SetCountLimit (1)
    e4:SetOperation(s.ctrlop)
    c:RegisterEffect(e4)
    local e5 = Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e5:SetRange(LOCATION_MZONE)
    e5:SetOperation(s.ctrop)
    c:RegisterEffect(e5)
end

s.listed_names = {CARD_CURE_IDOL, CARD_TOON_WORLD}
function s.sumtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_COUNTER, nil, 1, 0, COUNTER_SPELL)
end

function s.sumop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        c:AddCounter(COUNTER_SPELL, 1)
    end
end

function s.spsumtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    local ct = 1
    if Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, CARD_TOON_WORLD), tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) then
        ct = 2
    end
    Duel.SetOperationInfo(0, CATEGORY_COUNTER, nil, ct, 0, COUNTER_SPELL)
end

function s.spsumop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        local ct = 1
        if Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, CARD_TOON_WORLD), tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) then
            ct = 2
        end
        c:AddCounter(COUNTER_SPELL, ct)
    end
end
function s.atkval(e, c)
    return c:GetCounter(COUNTER_SPELL) * 500
end
function s.ctrlcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsCanRemoveCounter(tp, COUNTER_SPELL, 1, REASON_COST) end
    e:GetHandler():RemoveCounter(tp, COUNTER_SPELL, 1, REASON_COST)
end

function s.ctrltg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsControler(1 - tp) and chkc:IsLocation(LOCATION_MZONE) and chkc:IsControlerCanBeChanged() end
    if chk == 0 then return Duel.IsExistingTarget(Card.IsControlerCanBeChanged, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONTROL)
    local g = Duel.SelectTarget(tp, Card.IsControlerCanBeChanged, tp, 0, LOCATION_MZONE, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_CONTROL, g, 1, 0, 0)
end

function s.ctrlop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.GetControl(tc, tp, PHASE_END, 1)
    end
end
function s.ctrop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if rp ~= tp and re:IsActiveType(TYPE_TRAP) and c:GetCounter(COUNTER_SPELL) < 5 then
        c:AddCounter(COUNTER_SPELL, 1)
    end
end
