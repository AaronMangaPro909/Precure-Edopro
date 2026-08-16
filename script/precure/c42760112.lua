-- Cure Arcana

local s, id = GetID()
function s.initial_effect(c)
    Pendulum.AddProcedure(c)
   ---Pendulum Effect
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_TODECK + CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetRange(LOCATION_PZONE)
    e1:SetCondition(s.pencon)
    e1:SetTarget(s.pentg)
    e1:SetOperation(s.penop)
    c:RegisterEffect(e1)

    --- Monster Effect
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e0:SetCode(EFFECT_CHANGE_CODE)
    e0:SetRange(LOCATION_MZONE + LOCATION_GRAVE)
    e0:SetValue(52303611)
    c:RegisterEffect(e0)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_SPSUMMON_PROC)
    e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e2:SetRange(LOCATION_HAND)
    e2:SetCondition(s.hspcon)
    e2:SetTarget(s.hsptg)
    e2:SetOperation(s.hspop)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetOperation(s.atkop)
    c:RegisterEffect(e3)
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e4:SetRange(LOCATION_MZONE)
    e4:SetValue(aux.tgoval)
    c:RegisterEffect(e4)
    local e5 = Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e5:SetRange(LOCATION_MZONE)
    e5:SetValue(s.indval)
    c:RegisterEffect(e5)
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e6:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetValue(1)
    c:RegisterEffect(e6)
    local e7 = Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id, 2))
    e7:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e7:SetType(EFFECT_TYPE_QUICK_O)
    e7:SetCode(EVENT_CHAINING)
    e7:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCountLimit(1)
    e7:SetCondition(s.negcon)
    e7:SetCost(s.negcost)
    e7:SetTarget(s.negtg)
    e7:SetOperation(s.negop)
    c:RegisterEffect(e7)
end

s.listed_names = {52303611}

---Pendulum Code
function s.pencon(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(Card.IsSummonType, 1, nil, SUMMON_TYPE_PENDULUM)
end

function s.penfilter(c)
    return c:IsSetCard(0xb54)
        and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_GRAVE))
        and (c:IsAbleToDeck() or c:IsAbleToExtra())
end

function s.pentg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.penfilter, tp, LOCATION_HAND + LOCATION_GRAVE, 0, 1, nil)
        and Duel.IsPlayerCanDraw(tp, 5) end
    Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 1, tp, LOCATION_HAND + LOCATION_GRAVE)
    Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 5)
end

function s.penop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
    local g = Duel.SelectMatchingCard(tp, s.penfilter, tp, LOCATION_HAND + LOCATION_GRAVE, 0, 1, 99, nil)
    if #g > 0 then
        local ct = 0
        for tc in aux.Next(g) do
            if tc:IsType(TYPE_PENDULUM) then
                if Duel.SendtoDeck(tc, tp, SEQ_DECKTOP, REASON_EFFECT) > 0 then ct = ct + 1 end
            else
                if Duel.SendtoDeck(tc, tp, SEQ_DECKSHUFFLE, REASON_EFFECT) > 0 then ct = ct + 1 end
            end
        end
        
        if ct > 0 then
            Duel.ShuffleDeck(tp)
            Duel.BreakEffect()
            Duel.Draw(tp, 5, REASON_EFFECT)
        end
    end
end
--- Monster Effect code

function s.hspcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, c)
end

function s.hsptg(e, tp, eg, ep, ev, re, r, rp, chk, c)
    local g = Duel.GetMatchingGroup(Card.IsDiscardable, tp, LOCATION_HAND, 0, c)
    if #g > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISCARD)
        local sg = g:Select(tp, 1, 1, nil)
        if #sg > 0 then
            sg:KeepAlive()
            e:SetLabelObject(sg)
            return true
        end
    end
    return false
end

function s.hspop(e, tp, eg, ep, ev, re, r, rp, c)
    local g = e:GetLabelObject()
    if not g then return end
    Duel.SendtoGrave(g, REASON_COST + REASON_DISCARD)
    g:DeleteGroup()
end


function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(500)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        c:RegisterEffect(e1)
    end
end

function s.indval(e, re, rp)
    return rp ~= e:GetHandler():GetControler()
end

function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
end

function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, nil) end
    Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST + REASON_DISCARD)
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
