--Inheriting the Will of the Precure
local s, id = GetID()

function s.initial_effect(c)
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_TO_GRAVE)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_SZONE + LOCATION_MZONE)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_SZONE + LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetTarget(s.copytg)
    e2:SetOperation(s.copyop)
    c:RegisterEffect(e2)
end

local ARCH_PRECURE = 0xb54

function s.cfilter(c, tp)
    return c:IsSetCard(ARCH_PRECURE) and c:IsPreviousControler(tp)
        and c:IsPreviousLocation(LOCATION_MZONE) and c:IsPreviousPosition(POS_FACEUP)
        and (c:GetReason() & REASON_BATTLE ~= 0 or (c:GetReason() & REASON_EFFECT ~= 0 and c:GetReasonPlayer() == 1 - tp))
end

function s.spfilter(c, e, tp)
    return c:IsSetCard(ARCH_PRECURE) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(s.cfilter, 1, nil, tp)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then 
        local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
        return ft >= 2 and not Duel.IsPlayerAffectedByEffect(tp, 37115575)
            and eg:IsExists(s.cfilter, 1, nil, tp)
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 2, nil, e, tp)
    end
    
    local g = eg:Filter(s.cfilter, nil, tp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
    local tg = g:Select(tp, 1, 1, nil)
    Duel.SetTargetCard(tg)
    
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, tg, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 2, tp, LOCATION_DECK)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and Duel.Remove(tc, POS_FACEUP, REASON_EFFECT) > 0 then
        if Duel.GetLocationCount(tp, LOCATION_MZONE) < 2 or Duel.IsPlayerAffectedByEffect(tp, 37115575) then return end
        
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sg = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_DECK, 0, 2, 2, nil, e, tp)
        if #sg == 2 and Duel.SpecialSummon(sg, 0, tp, tp, false, false, POS_FACEUP) > 0 then
            local fid = e:GetHandler():GetFieldID()
            local sc = sg:GetFirst()
            while sc do
                sc:RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 0, 1, fid)
                sc = sg:GetNext()
            end
            sg:KeepAlive()
    
            local e1 = Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
            e1:SetCode(EVENT_PHASE + PHASE_END)
            e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
            e1:SetCountLimit(1)
            e1:SetLabel(fid)
            e1:SetLabelObject(sg)
            e1:SetCondition(s.retcon)
            e1:SetOperation(s.retop)
            e1:SetReset(RESET_PHASE + PHASE_END)
            Duel.RegisterEffect(e1, tp)
        end
    end
end

function s.retfilter(c, fid)
    return c:GetFlagEffectLabel(id) == fid
end

function s.retcon(e, tp, eg, ep, ev, re, r, rp)
    local g = e:GetLabelObject()
    if not g or not g:IsExists(s.retfilter, 1, nil, e:GetLabel()) then
        if g then g:DeleteGroup() end
        e:Reset()
        return false
    end
    return true
end

function s.retop(e, tp, eg, ep, ev, re, r, rp)
    local g = e:GetLabelObject()
    local rg = g:Filter(s.retfilter, nil, e:GetLabel())
    g:DeleteGroup()
    if #rg > 0 then
        Duel.SendtoDeck(rg, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
    end
end

function s.tgfilter(c)
    return c:IsFaceup() and c:IsSetCard(ARCH_PRECURE)
end

function s.gyfilter(c)
    return c:IsSetCard(ARCH_PRECURE) and c:IsAbleToRemove()
end

function s.copytg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingTarget(s.tgfilter, tp, LOCATION_MZONE, 0, 1, nil)
        and Duel.IsExistingMatchingCard(s.gyfilter, tp, LOCATION_GRAVE, 0, 1, nil) end
        
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    Duel.SelectTarget(tp, s.tgfilter, tp, LOCATION_MZONE, 0, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, tp, LOCATION_GRAVE)
end

function s.copyop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
    local g = Duel.SelectMatchingCard(tp, s.gyfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil)
    if #g > 0 and Duel.Remove(g, POS_FACEUP, REASON_EFFECT) > 0 then
        local gc = g:GetFirst()
        
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CHANGE_CODE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetValue(gc:GetOriginalCode())
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
        
        tc:CopyEffect(gc:GetOriginalCode(), RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 1)
    end
end
