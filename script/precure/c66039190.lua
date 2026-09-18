---Lovely Kiss
local s, id =GetID ()

function s.initial_effect(c)
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_ATKCHANGE + CATEGORY_RECOVER)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
    e1:SetCode(EVENT_TO_GRAVE)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

function s.filter(c, e, tp)
    return c:IsCode(60519833)
        and c:IsReason(REASON_DESTROY)
        and c:IsPreviousControler(tp)
        and c:IsPreviousLocation(LOCATION_MZONE)
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return eg:IsContains(chkc) and s.filter(chkc, e, tp) end
    if chk == 0 then
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
            and eg:IsExists(s.filter, 1, nil, e, tp)
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = eg:FilterSelect(tp, s.filter, 1, 1, nil, e, tp)
    Duel.SetTargetCard(g)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_RECOVER, nil, 0, tp, 1000)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
    if Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP) > 0 then
      local e1 = Effect.CreateEffect(e:GetHandler())
      e1:SetType(EFFECT_TYPE_SINGLE)
      e1:SetCode(EFFECT_UPDATE_ATTACK)
      e1:SetValue(2000)
      e1:SetReset(RESET_EVENT + RESETS_STANDARD)
      tc:RegisterEffect(e1)
            Duel.BreakEffect()
            Duel.Recover(tp, 1000, REASON_EFFECT)
        end
    end
end