-- Cure Star
local s, id = GetID()
function s.initial_effect(c)
    -- 1. Normal or Special Summon: Add 1 "Precure" Spell
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1, {id, 1})
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)
 --Special Summon hand
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_HAND)
    e3:SetCountLimit(1, {id, 2})
    e3:SetCondition(s.spcon)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)
    
-- Level Select  
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 0))
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetTarget(s.lvtg)
    e4:SetOperation(s.lvop)
    c:RegisterEffect(e4)
end

s.listed_names = {id, 12959074, 54422308, 30114345, 56536757}

------------------
function s.thfilter(c)
    return c:IsSetCard(0xb54) and c:IsSpell() and c:IsAbleToHand()
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


-- 2. HAND CHECK & MULTI SPECIAL SUMMON LOGIC
function s.check(g)
    local a1 = false
    local a2 = false
    local a3 = false
    local a4 = false
    local a5 = false
    for tc in aux.Next(g) do
        local code = tc:GetCode()
        if code == 12959074 then a1 = true
        elseif code == 54422308 then a2 = true
        elseif code == 30114345 then a3 = true
        elseif code == 56536757 then a4 = true
        elseif code == id then a5 = true
        end
    end
    return a1 and a2 and a3 and a4 and a5
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    local hg = Duel.GetFieldGroup(tp, LOCATION_HAND, 0)
    return s.check(hg)
end

function s.spfilter(c, e, tp)
    return c:IsCode(id, 12959074, 54422308, 30114345, 56536757)
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        local hg = Duel.GetFieldGroup(tp, LOCATION_HAND, 0)
        if not s.check(hg) then return false end
        return Duel.GetLocationCount(tp, LOCATION_MZONE) >= 1
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil, e, tp)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if ft <= 0 then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, math.min(ft, 5), nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end


-- Level

function s.lvtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsFaceup() end
    if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, LOCATION_MZONE, 0, 1, nil) end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    Duel.SelectTarget(tp, Card.IsFaceup, tp, LOCATION_MZONE, 0, 1, 1, nil)
end

function s.lvop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        local lv = Duel.AnnounceLevel(tp, 1, 12)
        
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CHANGE_LEVEL)
        e1:SetValue(lv)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
    end
end
