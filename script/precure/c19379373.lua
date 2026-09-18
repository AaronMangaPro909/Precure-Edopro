local s, id = GetID()

local CARD_PURIRUN = 41037083
local CARD_RIBBON  = 78010496 -- Black & White Precure Ribbon's ID

function s.initial_effect(c)
    c:EnableReviveLimit()
    
    -- Must be Special Summoned by Ribbon
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(s.splimit)
    c:RegisterEffect(e0)
    
    -- Name/Race Treatment Rules
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_ADD_CODE)
    e1:SetValue(CARD_PURIRUN)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EFFECT_ADD_RACE)
    e2:SetValue(RACE_FAIRY)
    c:RegisterEffect(e2)
    
    -- Unique Control Limit
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetRange(LOCATION_MZONE)
    e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e3:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e3:SetTargetRange(1, 0)
    e3:SetTarget(s.uniquetg)
    c:RegisterEffect(e3)
    
    -- LP Modifier: Pay 500 LP (Fixed)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 0))
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e4:SetCode(EVENT_SPSUMMON_SUCCESS)
    e4:SetOperation(s.lpop)
    c:RegisterEffect(e4)
    local e5 = e4:Clone()
    e5:SetCode(EVENT_ATTACK_ANNOUNCE)
    c:RegisterEffect(e5)
    
    -- Battle Restriction Rules
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
    e6:SetValue(s.atktg)
    c:RegisterEffect(e6)
    local e7 = Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_SINGLE)
    e7:SetCode(EFFECT_DIRECT_ATTACK)
    c:RegisterEffect(e7)
end

function s.splimit(e, se, sp, st)
    return se and se:GetHandler():IsCode(CARD_RIBBON)
end
function s.uniquetg(e, c, sumplayer, sumtype, sumpos, targetplayer)
    return c:IsCode(id)
end

-- Fixed: Pays 500 LP upon resolution
function s.lpop(e, tp, eg, ep, ev, re, r, rp)
    Duel.PayLPCost(tp, 500)
end

function s.atktg(e, c)
    return c:IsType(TYPE_MONSTER)
end
