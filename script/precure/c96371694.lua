-- Cure Yum-Yum - Party Up Style
local s, id = GetID()

local CARD_CURE_YUM_YUM = 47228333

function s.initial_effect(c)
    c:EnableReviveLimit()
    Synchro.AddProcedure(c, nil, 1, 1, Synchro.NonTuner(Card.IsCode, CARD_CURE_YUM_YUM), 1, 1)
    
     local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_RECOVER)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetTarget(s.rectg)
    e1:SetOperation(s.recop)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)
    
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_DESTROY + CATEGORY_DAMAGE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetCode(EVENT_CHAINING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.descon)
    e3:SetCountLimit (3)
    e3:SetTarget(s.destg)
    e3:SetOperation(s.desop)
    c:RegisterEffect(e3)
    
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_DESTROYED)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
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

function s.rectg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(2000)
    Duel.SetOperationInfo(0, CATEGORY_RECOVER, nil, 0, tp, 2000)
end
function s.recop(e, tp, eg, ep, ev, re, r, rp)
    local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
    Duel.Recover(p, d, REASON_EFFECT)
end

function s.descon(e, tp, eg, ep, ev, re, r, rp)
    return re:IsActiveType(TYPE_MONSTER)
end
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.IsExistingTarget(nil, tp, 0, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectTarget(tp, nil, tp, 0, LOCATION_MZONE, 1, 2, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, #g, tp, 0)
    Duel.SetOperationInfo(0, CATEGORY_DAMAGE, nil, 0, 1 - tp, 0)
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetTargetCards(e)
    if #g == 0 then return end
 
    local combined_atk = 0
    local dg = Group.CreateGroup()
    
    for tc in aux.Next(g) do
        if tc:IsRelateToEffect(e) then
            local atk = tc:GetTextAttack()
            if atk < 0 then atk = 0 end
            combined_atk = combined_atk + atk
            dg:AddCard(tc)
        end
    end
    
    if #dg > 0 then
        local destroyed_count = Duel.Destroy(dg, REASON_EFFECT)
        if destroyed_count > 0 and combined_atk > 0 then
            Duel.BreakEffect()
            Duel.Damage(1 - tp, combined_atk, REASON_EFFECT)
        end
    end
end

function s.spfilter(c, e, tp)
    return c:IsCode(CARD_CURE_YUM_YUM) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:IsAbleToBanish() 
        and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, c, 1, tp, LOCATION_GRAVE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.Remove(c, POS_FACEUP, REASON_EFFECT) > 0 then
        if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g = Duel.SelectMatchingGroup(tp, aux.NecroValleyFilter(s.spfilter), tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
        if #g > 0 then
            Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
        end
    end
end

function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and re:IsHasType(EFFECT_TYPE_ACTIVATE) and Duel.IsChainNegatable(ev)
end
function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsDestructable() then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end
function s.negop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end
