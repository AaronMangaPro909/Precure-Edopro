-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

function s.initial_effect(c)
    -- Ignition Effect: Target up to 2 face-up monsters to alter Level/Rank + enable Xyz usage
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1) -- Soft Once Per Turn
    e1:SetTarget(s.lvtg)
    e1:SetOperation(s.lvop)
    c:RegisterEffect(e1)
end

-------------------------------------------------------------------------
-- LEVEL/RANK ALTERATION & RULE MODIFICATION ENGINE
-------------------------------------------------------------------------
function s.lvfilter(c)
    -- Target must be face-up and possess either a Level or a Rank
    return c:IsFaceup() and (c:HasLevel() or c:IsType(TYPE_XYZ))
end

function s.lvtg(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.IsExistingTarget(s.lvfilter, tp, LOCATION_MZONE, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    -- Selects up to 2 face-up targets
    local g = Duel.SelectTarget(tp, s.lvfilter, tp, LOCATION_MZONE, LOCATION_MZONE, 1, 2, nil)
end

function s.lvop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tg = Duel.GetTargetCards(e)
    if #tg == 0 then return end
    
    -- Prompt the player to choose a value from 1 to 10
    local list = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    local val = Duel.AnnounceNumber(tp, table.unpack(list))
    
    for tc in aux.Next(tg) do
        if tc:IsFaceup() then
            -- If it has a Level, change its Level
            if tc:HasLevel() then
                local e1 = Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_CHANGE_LEVEL)
                e1:SetValue(val)
                e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
                tc:RegisterEffect(e1)
            -- If it is an Xyz monster, change its Rank
            elseif tc:IsType(TYPE_XYZ) then
                local e2 = Effect.CreateEffect(c)
                e2:SetType(EFFECT_TYPE_SINGLE)
                e2:SetCode(EFFECT_CHANGE_RANK)
                e2:SetValue(val)
                e2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
                tc:RegisterEffect(e2)
            end
            
            -- Apply special exception: This card's current Rank can be used as a Level for Xyz Summons
            local e3 = Effect.CreateEffect(c)
            e3:SetType(EFFECT_TYPE_SINGLE)
            e3:SetCode(EFFECT_XYZ_LEVEL)
            e3:SetValue(s.xyzval)
            e3:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
            tc:RegisterEffect(e3)
        end
    end
end

function s.xyzval(e, c)
    -- For Xyz summons, evaluate this card's rank value directly as if it were a level
    return e:GetHandler():GetRank()
end
