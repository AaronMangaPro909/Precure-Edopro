-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

function s.initial_effect(c)
    -- Activate/Ignition Effect: Target up to 2 monsters to modulate Level/Rank
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1) -- Soft Once Per Turn
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

-- Filter out monsters that can actually have their Level or Rank changed
function s.filter(c)
    return c:IsFaceup() and (c:HasLevel() or c:IsType(TYPE_XYZ))
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk, chcl)
    if chk == 0 then return Duel.IsExistingTarget(s.filter, tp, LOCATION_MZONE, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    -- Target up to 2 face-up monsters on either side of the field
    local g = Duel.SelectTarget(tp, s.filter, tp, LOCATION_MZONE, LOCATION_MZONE, 1, 2, nil)
    
    -- Prompt player to declare a number (Level/Rank) from 1 to 10
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_LVRANK)
    local lv = Duel.AnnounceLevel(tp, 1, 10)
    e:SetLabel(lv)
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetTargetCards(e)
    if #g == 0 then return end
    local lv = e:GetLabel()

    for tc in aux.Next(g) do
        if tc:IsFaceup() then
            -- Case A: Monster has a Level -> Change its Level
            if tc:HasLevel() then
                local e1 = Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_CHANGE_LEVEL)
                e1:SetValue(lv)
                e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
                tc:RegisterEffect(e1)
            
            -- Case B: Monster is an Xyz Monster -> Change its Rank
            elseif tc:IsType(TYPE_XYZ) then
                local e2 = Effect.CreateEffect(c)
                e2:SetType(EFFECT_TYPE_SINGLE)
                e2:SetCode(EFFECT_CHANGE_RANK)
                e2:SetValue(lv)
                e2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
                tc:RegisterEffect(e2)
            end

            -- Rule Modification: Allow updated Rank to be used as a Level for Xyz Summons
            local e3 = Effect.CreateEffect(c)
            e3:SetType(EFFECT_TYPE_SINGLE)
            e3:SetCode(EFFECT_XYZ_LEVEL)
            e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e3:SetValue(s.xyzlv)
            e3:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
            tc:RegisterEffect(e3)
        end
    end
end

-- This system function overrides how the game calculates Xyz materials, 
-- instructing the engine to look at the monster's current Rank value and read it as a Level.
function s.xyzlv(e, c, xyzcard)
    return c:GetRank()
end
