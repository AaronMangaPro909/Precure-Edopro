local s, id = GetID()
function s.initial_effect (c)
   local e1 = Effect.CreateEffect (c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_HANDES + CATEGORY_TOHAND + CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1, id)
    e1:SetCost(s.thcost)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_FUSION_MAT_RESTRICTION)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetProperty(EFFECT_FLAG_EVENT_PLAYER)
    e3:SetCondition(s.efcon)
    e3:SetOperation(s.efop)
    c:RegisterEffect(e3)
end

function s.costfilter(c)
    return c:IsSetCard(0xb54) and c:IsMonster() and c:IsDiscardable()
end
function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_HAND, 0, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISCARD)
    local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_HAND, 0, 1, 1, nil)
    Duel.SendtoGrave(g, REASON_COST + REASON_DISCARD)
end
function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsSpellTrap() and c:IsAbleToHand()
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




-- Materials
function s.efcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local rc = c:GetReasonCard()
    return r == REASON_FUSION and REASON_XYZ and REASON_LINK and rc and rc:IsSetCard(0xb54) and rc:IsType(TYPE_MONSTER)
end
function s.efop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local rc = c:GetReasonCard()
    local e1 = Effect.CreateEffect(rc)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetValue(s.efval)
    e1:SetOwnerPlayer(tp)
    e1:SetReset(RESET_EVENT + RESETS_STANDARD)
    rc:RegisterEffect(e1, true)
end
function s.efval(e, re)
    return re:GetOwnerPlayer() ~= e:GetOwnerPlayer()
end
