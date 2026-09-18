-- Eclipse Shadow
local s, id = GetID()
function s.initial_effect(c)
    Pendulum.AddProcedure(c, false)
    c:EnableReviveLimit()
   --- Xyz Material  
    Xyz.AddProcedure(c, nil, 12, 2)   
    -- Pendulum 
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetRange(LOCATION_PZONE)
    e1:SetTargetRange(LOCATION_PZONE, 0)
    e1:SetValue(2000)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e2)
     -- Cannot be destroyed
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e3:SetRange(LOCATION_PZONE)
    e3:SetTargetRange(LOCATION_PZONE, 0)
    e3:SetValue(1)
    c:RegisterEffect(e3)
    -- Name becomes "Cure Arcana Shadow"
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetCode(EFFECT_CHANGE_CODE)
    e4:SetRange(LOCATION_MZONE + LOCATION_GRAVE)
    e4:SetValue(52303611)
    c:RegisterEffect(e4)
    -- Attach monsters from either GY (max. 9 materials)
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 0))
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1)
    e5:SetTarget(s.mttg)
    e5:SetOperation(s.mtop)
    c:RegisterEffect(e5)
  --Power Damage
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetCode(EFFECT_PIERCE)
    c:RegisterEffect(e6)
    -- Double Battle Damage
    local e7 = Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e7:SetCode(EVENT_PRE_BATTLE_DAMAGE)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCondition(s.damcon)
    e7:SetOperation(s.damop)
    c:RegisterEffect(e7)
    local e8 = Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id, 1))
    e8:SetType(EFFECT_TYPE_QUICK_O)
    e8:SetCode(EVENT_FREE_CHAIN)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCountLimit(1)
    e8:SetTarget(s.efftg)
    e8:SetOperation(s.effop)
    c:RegisterEffect(e8)
    --Detach 1 to negate activation and destroy
    local e9 = Effect.CreateEffect(c)
    e9:SetDescription(aux.Stringid(id, 2))
    e9:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e9:SetType(EFFECT_TYPE_QUICK_O)
    e9:SetCode(EVENT_CHAINING)
    e9:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e9:SetRange(LOCATION_MZONE)
    e9:SetCountLimit(1)
    e9:SetCondition(s.negcon)
    e9:SetCost(s.negcost)
    e9:SetTarget(s.negtg)
    e9:SetOperation(s.negop)
    c:RegisterEffect(e9)
   -- place in Pendulum Zone
    local e10 = Effect.CreateEffect(c)
    e10:SetDescription(aux.Stringid(id, 3))
    e10:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e10:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e10:SetProperty(EFFECT_FLAG_DELAY)
    e10:SetCode(EVENT_DESTROYED)
    e10:SetCondition(s.pencon)
    e10:SetTarget(s.pentg)
    e10:SetOperation(s.penop)
    c:RegisterEffect(e10)
end

s.listed_names = {52303611}


function s.mtfilter(c)
    return c:IsType(TYPE_MONSTER)
end

function s.mttg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    local c = e:GetHandler()
    local max_attach = 9 - c:GetOverlayCount()
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and s.mtfilter(chkc) end
    if chk == 0 then return max_attach > 0 and Duel.IsExistingTarget(s.mtfilter, tp, LOCATION_GRAVE, LOCATION_GRAVE, 1, nil) end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    local g = Duel.SelectTarget(tp, s.mtfilter, tp, LOCATION_GRAVE, LOCATION_GRAVE, 1, math.min(max_attach, 9), nil)
    Duel.SetOperationInfo(0, CATEGORY_LEAVE_GRAVE, g, #g, 0, 0)
end

function s.mtop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetChainInfo(0, CHAININFO_TARGET_CARDS)
    local sg = g:Filter(Card.IsRelateToEffect, nil, e)
    if #sg > 0 and c:IsRelateToEffect(e) then
        Duel.Overlay(c, sg)
    end
end


function s.damcon(e, tp, eg, ep, ev, re, r, rp)
    local eq = e:GetHandler()
    return Duel.GetAttacker() == eq and eq:IsControler(tp)
end

function s.damop(e, tp, eg, ep, ev, re, r, rp)
    Duel.ChangeBattleDamage(ep, ev * 2)
end


function s.efftg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    local ct = c:GetOverlayCount()
    if chk == 0 then
        return (ct >= 2 and Duel.IsExistingMatchingCard(Card.IsSpellTrap, tp, 0, LOCATION_ONFIELD, 1, nil))
            or ct >= 5
            or (ct >= 9 and Duel.IsExistingMatchingCard(aux.TRUE, tp, 0, LOCATION_ONFIELD, 1, nil))
    end
    
    local ops = {}
    local opval = {}
    if ct >= 2 and Duel.IsExistingMatchingCard(Card.IsSpellTrap, tp, 0, LOCATION_ONFIELD, 1, nil) then
        table.insert(ops, aux.Stringid(id, 4))
        table.insert(opval, 2)
    end
    if ct >= 5 then
        table.insert(ops, aux.Stringid(id, 5))
        table.insert(opval, 5)
    end
    if ct >= 9 and Duel.IsExistingMatchingCard(aux.TRUE, tp, 0, LOCATION_ONFIELD, 1, nil) then
        table.insert(ops, aux.Stringid(id, 6))
        table.insert(opval, 9)
    end
    
    local op = Duel.SelectOption(tp, table.unpack(ops)) + 1
    local selected_ct = opval[op]
    e:SetLabel(selected_ct)
    
    Duel.Hint(HINT_OPSELECTED, 1 - tp, e:GetDescription())
end

function s.effop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local selected_ct = e:GetLabel()
    if not c:IsRelateToEffect(e) or c:GetOverlayCount() < selected_ct then return end
    
    if c:CheckRemoveOverlayCard(tp, selected_ct, REASON_EFFECT) then
        c:RemoveOverlayCard(tp, selected_ct, selected_ct, REASON_EFFECT)
        
        if selected_ct == 2 then
            local g = Duel.GetMatchingGroup(Card.IsSpellTrap, tp, 0, LOCATION_ONFIELD, nil)
            if #g > 0 then
                Duel.Destroy(g, REASON_EFFECT)
            end
        elseif selected_ct == 5 then
            local e1 = Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(1000)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            c:RegisterEffect(e1)
        elseif selected_ct == 9 then
            local g = Duel.GetMatchingGroup(aux.TRUE, tp, 0, LOCATION_ONFIELD, nil)
            if #g > 0 then
                Duel.Destroy(g, REASON_EFFECT)
            end
        end
    end
end


function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
end

function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:CheckRemoveOverlayCard(tp, 1, REASON_COST) end
    c:RemoveOverlayCard(tp, 1, 1, REASON_COST)
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

function s.pencon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return c:IsPreviousControler(tp) and c:IsReason(REASON_EFFECT) and rp ~= tp
end

function s.pentg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.CheckLocation(tp, LOCATION_PZONE, 0) or Duel.CheckLocation(tp, LOCATION_PZONE, 1) end
end

function s.penop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.MoveToField(c, tp, tp, LOCATION_PZONE, POS_FACEUP, true)
    end
end
