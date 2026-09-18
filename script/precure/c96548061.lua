-- Twilight, Princess of Despair
-- 絶望のプリンセス・トワイライト
local s, id = GetID()

local CARD_CURE_SCARLET = 3325364110

function s.initial_effect(c)
    c:EnableReviveLimit()
    Link.AddProcedure(c, s.matfilter, 5, 5)
    c:EnableUnsummonable()
    
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetProperty(EFFECT_FLAG_UNCOPYABLE + EFFECT_FLAG_CANNOT_DISABLE)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetCondition(s.sprcon)
    e0:SetTarget(s.sprtg)
    e0:SetOperation(s.sprop)
    c:RegisterEffect(e0)
    
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetRange(LOCATION_MZONE)
    e1:SetValue(s.atkval)
    c:RegisterEffect(e1)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCondition(s.exspcon)
    e2:SetTarget(s.exsptg)
    e2:SetOperation(s.exspop)
    c:RegisterEffect(e2)
end

function s.matfilter(c, lc, sumtype, tp)
    if c:IsCode(CARD_CURE_SCARLET) then return true end
    return c:IsAttribute(ATTRIBUTE_DARK, lc, sumtype, tp)
end

function s.sprfilter(c)
    return c:IsType(TYPE_LINK) and c:GetLink() >= 3 and c:IsAbleToRemoveAsCost()
end
function s.sprcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    if Duel.GetFlagEffect(tp, id) ~= 0 then return false end
    if Duel.GetLP(tp) > 1000 then return false end
    local rg = Duel.GetMatchingGroup(s.sprfilter, tp, LOCATION_GRAVE, 0, nil)
    return Duel.GetLocationCountFromEx(tp, tp, rg, c) > 0 and #rg >= 3
end
function s.sprtg(e, tp, eg, ep, ev, re, r, rp, chk, c)
    local rg = Duel.GetMatchingGroup(s.sprfilter, tp, LOCATION_GRAVE, 0, nil)
    local g = aux.SelectUnselectGroup(rg, e, tp, 3, 3, nil, 1, tp, HINTMSG_REMOVE, nil, nil, true)
    if #g > 0 then
        g:KeepAlive()
        e:SetLabelObject(g)
        return true
    end
    return false
end
function s.sprop(e, tp, eg, ep, ev, re, r, rp, c)
    local g = e:GetLabelObject()
    if not g then return end
    Duel.RegisterFlagEffect(tp, id, 0, 0, 1)
    Duel.Remove(g, POS_FACEUP, REASON_COST)
    c:SetMaterial(g)
    g:Delete()
end

function s.count_arrows(c)
    local count = 0
    if c:IsLinkMarker(LINK_MARKER_BOTTOM_LEFT) then count = count + 1 end
    if c:IsLinkMarker(LINK_MARKER_BOTTOM)      then count = count + 1 end
    if c:IsLinkMarker(LINK_MARKER_BOTTOM_RIGHT) then count = count + 1 end
    if c:IsLinkMarker(LINK_MARKER_LEFT)        then count = count + 1 end
    if c:IsLinkMarker(LINK_MARKER_RIGHT)       then count = count + 1 end
    if c:IsLinkMarker(LINK_MARKER_TOP_LEFT)    then count = count + 1 end
    if c:IsLinkMarker(LINK_MARKER_TOP)         then count = count + 1 end
    if c:IsLinkMarker(LINK_MARKER_TOP_RIGHT)   then count = count + 1 end
    return count
end
function s.atkval(e, c)
    local tp = e:GetHandlerPlayer()
    local g = Duel.GetMatchingGroup(Card.IsType, tp, LOCATION_REMOVED, 0, nil, TYPE_LINK)
    local total_arrows = 0
    for tc in aux.Next(g) do
        total_arrows = total_arrows + s.count_arrows(tc)
    end
    return total_arrows * 200
end

function s.exspcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsReason(REASON_DESTROY)
end
function s.exspfilter(c, e, tp)
    return c:IsType(TYPE_LINK) and c:GetLink() >= 3 
        and c:IsCanBeSpecialSummoned(e, 0, tp, true, false)
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
