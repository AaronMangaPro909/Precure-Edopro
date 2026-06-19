--43091163

-- Substitute XXXX with this card's 8-digit ID
local s, id = GetID()

function s.initial_effect(c)
    -- Activate: Fusion Summon 1 "Precure" Fusion monster by banishing from Hand/Field/Deck
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_FUSION_SUMMON + CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1, id, EFFECT_COUNT_LIMIT_OATH) -- Hard Once Per Turn
    e1:SetTarget(s.fustg)
    e1:SetOperation(s.fusop)
    c:RegisterEffect(e1)
end

-- Filter to target only "Precure" (0xb54) Fusion Monsters
function s.ffilter(c)
    return c:IsSetCard(0xb54) and c:IsType(TYPE_FUSION)
end

-- Tells the engine where it is allowed to look for Fusion materials
function s.fextra(e, tp, mg)
    return Duel.GetMatchingGroup(Card.IsAbleToRemove, tp, LOCATION_HAND + LOCATION_ONFIELD + LOCATION_DECK, 0, nil)
end

function s.fustg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        local params = {
            filter = s.ffilter,
            extrafil = s.fextra,
            extratg = Fusion.BanishMaterial,
            insandbox = true
        }
        return Fusion.SummonEffTG(params)(e, tp, eg, ep, ev, re, r, rp, 0)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, tp, LOCATION_HAND + LOCATION_ONFIELD + LOCATION_DECK)
end

function s.fusop(e, tp, eg, ep, ev, re, r, rp)
    local params = {
        filter = s.ffilter,
        extrafil = s.fextra,
        extratg = Fusion.BanishMaterial
    }
    Fusion.SummonEffOP(params)(e, tp, eg, ep, ev, re, r, rp)
end
