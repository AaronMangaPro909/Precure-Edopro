-- Twilight, Princess of Despair
-- 絶望のプリンセス・トワイライト
local s, id = GetID()

local CARD_SCARLET = 3325364110 

function s.initial_effect(c)
    c:EnableReviveLimit()
    Link.AddProcedure(c, s.matfilter, 5, 5)
    c:EnableUnsummonable()
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetProperty(EFFECT_FLAG_UNCOPYABLE + EFFECT_FLAG_CANNOT_DISABLE)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetCondition(s.spcon)
    e0:SetTarget(s.sptg)
    e0:SetOperation(s.spop)
    c:RegisterEffect(e0)
    
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(s.atkval)
    c:RegisterEffect(e1)

    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCondition(s.exspcon)
    e2:SetTarget(s.exsptg)
    e2:SetOperation(s.exspop)
    c:RegisterEffect(e2)
end

function s.matfilter(c, lc, sumtype, tp)
    if c:IsCode(CARD_SCARLET) then return true end
    return c:IsAttribute(ATTRIBUTE_DARK, lc, sumtype, tp)
end

function s.procfilter(c)
    return c:IsType(TYPE_LINK) and c:GetLink() >= 3 and c:IsAbleToRemoveAsCost()
end
function s.spcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    if Duel.GetLP(tp) > 1000 or Duel.GetFlagEffect(tp, id) > 0 then return false end
    if Duel.GetLocationCountFromEx(tp, tp, nil, c) <= 0 then return false end
    local g = Duel.GetMatchingGroup(s.procfilter, tp, LOCATION_GRAVE, 0, nil)
    return g:CheckSubGroup(aux.mzctcheck, 3, 3, tp)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, c)
    local g = Duel.GetMatchingGroup(s.procfilter, tp, LOCATION_GRAVE, 0, nil)
    local sg = aux.SelectUnselectGroup(g, e, tp, 3, 3, aux.mzctcheck, 1, tp, HINTMSG_REMOVE, nil, nil, true)
    if #sg > 0 then
        sg:KeepAlive()
        e:SetLabelObject(sg)
        return true
    end
    return false
end
function s.spop(e, tp, eg, ep, ev, re, r, rp, c)
    local sg = e:GetLabelObject()
    if not sg then return end
    Duel.RegisterFlagEffect(tp, id, 0, 0, 1)
    Duel.Remove(sg, POS_FACEUP, REASON_COST)
    c:SetMaterial(sg)
    sg:Delete()
end

function s.atkval(e, c)
    local tp = e:GetHandlerPlayer()
    local g = Duel.GetMatchingGroup(function(tc) return tc:IsType(TYPE_LINK) and tc:IsFaceup() end, tp, LOCATION_REMOVED, 0, nil)
    local count = 0
    local tc = g:GetFirst()
    while tc do
      
        local arrows = tc:GetLinkMarker()
        for i = 0, 8 do
            if i ~= 4 and (arrows & (1 << i)) ~= 0 then
                count = count + 1
            end
        end
        tc = g:GetNext()
    end
    return count * 200
end

function s.exspcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsReason(REASON_DESTROY)
end
function s.exspfilter(c, e, tp)
    return c:IsType(TYPE_LINK) and c:GetLink() >= 3 
        and c:IsCanBeSpecialSummoned(e, 0, tp, true, false, POS_FACEUP)
end
function s.exsptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCountFromEx(tp, tp, nil, TYPE_LINK) > 0
        and Duel.IsExistingMatchingCard(s.exspfilter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end
function s.exspop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCountFromEx(tp, tp, nil, TYPE_LINK) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.exspfilter, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, true, false, POS_FACEUP)
    end
end
