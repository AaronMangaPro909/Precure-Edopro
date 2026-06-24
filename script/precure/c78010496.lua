local s, id = GetID()

-- ID Configuration (Update these to match your database IDs)
local CARD_PURIRUN       = 41037083
local CARD_MERORON       = 5826302
local CARD_CURE_ZUKYOON  = 19379373
local CARD_CURE_KISS     = 60519833


function s.initial_effect(c)
    -- Activate: Send matching pairs/units from Hand or Field -> Special Summon from Hand/Deck
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    
    -- Continuous: If sent to GY by card effect, Set itself
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 3))
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCondition(s.setcon)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)
end

-- Validation Check Filters (Hand + Field tracking)
function s.pfilter(c)
    return c:IsCode(CARD_PURIRUN) and c:IsAbleToGrave()
end
function s.mfilter(c)
    return c:IsCode(CARD_MERORON) and c:IsAbleToGrave()
end
function s.spfilter(c, code, e, tp)
    return c:IsCode(code) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SPECIAL, tp, true, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        local p_exist = Duel.IsExistingMatchingCard(s.pfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil)
        local m_exist = Duel.IsExistingMatchingCard(s.mfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, nil)
        local can_zk = Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, CARD_CURE_ZUKYOON, e, tp)
        local can_ks = Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, CARD_CURE_KISS, e, tp)
        
        return (p_exist and can_zk) or (m_exist and can_ks)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    -- Evaluate legal modes at resolution
    local p_g = Duel.GetMatchingGroup(s.pfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
    local m_g = Duel.GetMatchingGroup(s.mfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
    
    local can_zk = Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, CARD_CURE_ZUKYOON, e, tp)
    local can_ks = Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, CARD_CURE_KISS, e, tp)
    
    local opt = {}
    local menu = {}
    
    -- Option 1: Meroron -> Cure Kiss
    if #m_g > 0 and can_ks and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
        table.insert(opt, 1)
        table.insert(menu, aux.Stringid(id, 0)) -- "Send Meroron -> Summon Cure Kiss"
    end
    -- Option 2: Purirun -> Cure Zukyoon
    if #p_g > 0 and can_zk and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
        table.insert(opt, 2)
        table.insert(menu, aux.Stringid(id, 1)) -- "Send Purirun -> Summon Cure Zukyoon"
    end
    -- Option 3: Both -> Both
    if #p_g > 0 and #m_g > 0 and can_zk and can_ks and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
        -- Check zone clearance rules
        local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
        local mzone_count = 0
        if p_g:IsExists(Card.IsLocation, 1, nil, LOCATION_MZONE) then mzone_count = mzone_count + 1 end
        if m_g:IsExists(Card.IsLocation, 1, nil, LOCATION_MZONE) then mzone_count = mzone_count + 1 end
        if ft + mzone_count >= 2 then
            table.insert(opt, 3)
            table.insert(menu, aux.Stringid(id, 2)) -- "Send Both -> Summon Both"
        end
    end
    
    if #opt == 0 then return end
    local choice = opt[Duel.SelectOption(tp, table.unpack(menu)) + 1]
    
    local tg = Group.CreateGroup()
    if choice == 1 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sg = Duel.SelectMatchingCard(tp, s.mfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil)
        if #sg > 0 and Duel.SendtoGrave(sg, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sp = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, CARD_CURE_KISS, e, tp):GetFirst()
            if sp then
                Duel.SpecialSummon(sp, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
        end
    elseif choice == 2 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sg = Duel.SelectMatchingCard(tp, s.pfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil)
        if #sg > 0 and Duel.SendtoGrave(sg, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sp = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, CARD_CURE_ZUKYOON, e, tp):GetFirst()
            if sp then
                Duel.SpecialSummon(sp, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
            end
        end
    elseif choice == 3 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sg1 = Duel.SelectMatchingCard(tp, s.pfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, nil)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
        local sg2 = Duel.SelectMatchingCard(tp, s.mfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 1, 1, sg1:GetFirst())
        sg1:Merge(sg2)
        
        if #sg1 == 2 and Duel.SendtoGrave(sg1, REASON_EFFECT) == 2 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc1 = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, CARD_CURE_ZUKYOON, e, tp):GetFirst()
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sc2 = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, sc1, CARD_CURE_KISS, e, tp):GetFirst()
            
            if sc1 and sc2 then
                Duel.SpecialSummonStep(sc1, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonStep(sc2, SUMMON_TYPE_SPECIAL, tp, tp, true, false, LOCATION_MZONE)
                Duel.SpecialSummonComplete()
            end
        end
    end
end

-- E2 Logic: Set itself if sent to GY by an effect
function s.setcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsReason(REASON_EFFECT)
