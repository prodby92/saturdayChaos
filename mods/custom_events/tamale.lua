local tamaleTag = 'tamaleFlash'
local tamaleTween = 'tamaleEventFade'
local tamaleScaleXTween = 'tamaleEventScaleX'
local tamaleScaleYTween = 'tamaleEventScaleY'
local opponentUpTween = 'tamaleEventOpponentUp'
local opponentDownTween = 'tamaleEventOpponentDown'
local opponentScaleUpTween = 'tamaleEventOpponentScaleUp'
local opponentScaleDownTween = 'tamaleEventOpponentScaleDown'
local opponentBaseY = 0
local playerUpTween = 'tamaleEventPlayerUp'
local playerDownTween = 'tamaleEventPlayerDown'
local playerScaleUpTween = 'tamaleEventPlayerScaleUp'
local playerScaleDownTween = 'tamaleEventPlayerScaleDown'
local playerBaseY = 0
local tamaleCreated = false

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function getBounceStrength(rawValue)
    local strength = tonumber(rawValue)

    if strength == nil then
        return 1
    end

    return clamp(strength, 1, 10)
end

local function ensureTamaleText()
    if tamaleCreated then
        return
    end

    makeLuaText(tamaleTag, 'tamale', 500, 0, 80)
    setTextAlignment(tamaleTag, 'center')
    setTextSize(tamaleTag, 64)
    screenCenter(tamaleTag, 'x')
    setObjectCamera(tamaleTag, 'hud')
    setProperty(tamaleTag .. '.alpha', 0)
    setProperty(tamaleTag .. '.scale.x', 0.8)
    setProperty(tamaleTag .. '.scale.y', 0.8)
    addLuaText(tamaleTag)
    tamaleCreated = true
end

local function playTamaleEffect(strength)
    local bounceDistance = 50 * strength

    ensureTamaleText()

    cancelTween(tamaleTween)
    cancelTween(tamaleScaleXTween)
    cancelTween(tamaleScaleYTween)
    setProperty(tamaleTag .. '.alpha', 1)
    setProperty(tamaleTag .. '.scale.x', 1.2)
    setProperty(tamaleTag .. '.scale.y', 1.2)
    doTweenAlpha(tamaleTween, tamaleTag, 0, 1, 'linear')
    doTweenX(tamaleScaleXTween, tamaleTag .. '.scale', 0.8, 1, 'expoOut')
    doTweenY(tamaleScaleYTween, tamaleTag .. '.scale', 0.8, 1, 'expoOut')

    opponentBaseY = getProperty('dad.y')
    cancelTween(opponentUpTween)
    cancelTween(opponentDownTween)
    cancelTween(opponentScaleUpTween)
    cancelTween(opponentScaleDownTween)
    doTweenY(opponentUpTween, 'dad', opponentBaseY - bounceDistance, 0.5, 'sineOut')
    doTweenX(opponentScaleUpTween, 'dad.scale', 2, 0.5, 'sineOut')

    playerBaseY = getProperty('boyfriend.y')
    cancelTween(playerUpTween)
    cancelTween(playerDownTween)
    cancelTween(playerScaleUpTween)
    cancelTween(playerScaleDownTween)
    doTweenY(playerUpTween, 'boyfriend', playerBaseY - bounceDistance, 0.5, 'sineOut')
    doTweenX(playerScaleUpTween, 'boyfriend.scale', 2, 0.5, 'sineOut')
end

function onCreatePost()
    ensureTamaleText()
end

function onEvent(name, value1, value2)
    if name == 'tamale' then
        playTamaleEffect(getBounceStrength(value1))
    end
end

function onTweenCompleted(tag)
    if tag == opponentUpTween then
        doTweenY(opponentDownTween, 'dad', opponentBaseY, 0.5, 'sineIn')
        doTweenX(opponentScaleDownTween, 'dad.scale', 1, 0.5, 'sineIn')
    elseif tag == playerUpTween then
        doTweenY(playerDownTween, 'boyfriend', playerBaseY, 0.5, 'sineIn')
        doTweenX(playerScaleDownTween, 'boyfriend.scale', 1, 0.5, 'sineIn')
    end
end
