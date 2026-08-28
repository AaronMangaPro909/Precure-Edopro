-- キュアブロッサム
-- Cure Blossom

local s, id = GetID()

function s.initial_effect (c)
   local e1 = Effect.CreateEffect (c)
   e1: SetDescription (aux.Stringid (id, 0))
   e1: SetCategory (CATEGORY_SPECIAL_SUMMON)
   e1: SetType (EFFECT_TYPE_IGNITION)
   e1: SetRange (LOCATION_HAND)
   e1: SetCountLimit (1, id)
   e1: SetCondition (s.hspcon)
   e1: SetTarget (s.hsptg)
   e1: SetOperation (s.hspop)
   c: RegisterEffect (e1)
   local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_FUSION_MAT_RESTRICTION)
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetProperty(EFFECT_FLAG_EVENT_PLAYER)
    e3:SetCondition(s.efcon)
    e3:SetOperation(s.efop)
    c:RegisterEffect(e3)
end

-- Special Summon
function s.cfilter (c)
    return c:IsFaceup () and c:IsSetCard (0xb54)
end
function s.hspcon (e, tp, eg, ep, ev, re, r, rp)
     return Duel.IsExistingMatchingCard (s.cfilter, tp, LOCATION_ONFIELD, 0,1, nil)
end
function s.hsptg (e, tp, eg, ep, ev, re, r, rp, chk)
     local c = e:GetHandler ()
     if chk == 0 then return Duel.GetLocationCount (tp, LOCATION_MZONE) > 0
     and c:IsCanBeSpecialSummoned (e, 0, tp, false,  false) end
     Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end
function s.hspop (e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler ()
    if c:IsRelateToEffect (e) then 
    Duel.SpecialSummon (c, 0, tp, tp, false, false,  POS_FACEUP)
    end
end


-- Fusion materials.
function s.efcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local rc = c:GetReasonCard()
    return r == REASON_FUSION and rc and rc:IsSetCard(0xb54) and rc:IsType(TYPE_MONSTER)
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
