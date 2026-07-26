local barWidth  = 837
local barHeight = 25
local barX = 65
local barY = 578 
local shiftRight = 156
local shiftDown  = 51

local colorFadeTime = 0.2
local fadeProgress  = 0.0
local hudIsFrozen = false
local visualHealth = 2.0

local myGainMult = 0.2
local myLossMult = 3
local globalGainSetting = 1.0
local globalLossSetting = 1.0

    if downscroll then
        barY = 0
    end

local rankPositions = {
    ['-']   = {x = 1080, y = barY + 17 + 8}, 
    ['Sgold'] = {x = 1059, y = barY - 33 + 8}, 
    ['Sstar'] = {x = 1063, y = barY - 35 + 8}, 
    ['S']   = {x = 1080, y = barY - 18 + 8}, 
    ['A']   = {x = 1070, y = barY - 13 + 8}, 
    ['B']   = {x = 1075, y = barY - 13 + 8}, 
    ['C']   = {x = 1070, y = barY - 13 + 8}, 
    ['D']   = {x = 1075, y = barY - 8 + 8}, 
    ['F']   = {x = 1080, y = barY - 8 + 8}
}

local rankScaleX     = 0.7
local rankScaleY     = 0.7
local useAntialiasing = true
local hasHitNote = false
local hasMissed  = false

local songIsCompleted = false 

function onCreatePost()
    if difficultyName == '1%' then
        barWidth  = 67
        barHeight = 25
        barX = 170
        shiftRight = 458
        shiftDown  = 51
    end
    if difficultyName == '1%' then
        visualHealth = 0.025
    else
        visualHealth = 2.0
    end

    if difficultyName == 'Hard' then
        globalGainSetting = getProperty('healthGain')
        globalLossSetting = getProperty('healthLoss')

        setProperty('healthGain', 0)
        setProperty('healthLoss', 0)
    end

    setProperty('healthBar.visible', false)
    setProperty('iconP1.visible', false)
    setProperty('iconP2.visible', false)

    local frameAsset = 'frankieUI/batteryBar'
    if difficultyName == '1%' then frameAsset = 'frankieUI/1percentBatteryBar' end



    makeLuaSprite('batteryBar', frameAsset, barX, barY)
    setObjectCamera('batteryBar', 'camHUD')
    addLuaSprite('batteryBar', false)
    
    setProperty('health', 2.0)
    
    local fluidAsset = 'frankieUI/battery'
    if difficultyName == '1%' then fluidAsset = 'frankieUI/1percentBattery' end

    makeLuaSprite('healthFill_Fluid', fluidAsset, barX + shiftRight, barY + shiftDown)
    setObjectCamera('healthFill_Fluid', 'camHUD')
    
    if difficultyName == 'Low Power Mode' then
        setProperty('healthFill_Fluid.color', getColorFromHex('FFCC44'))
    elseif difficultyName == '1%' then
        setProperty('healthFill_Fluid.color', getColorFromHex('FF3B30'))
    else
        setProperty('healthFill_Fluid.color', getColorFromHex('3EFF6F'))
    end
    addLuaSprite('healthFill_Fluid', false)

    local textX = 45
    local textY = barY + 34

    if difficultyName == '1%' then
        textX = 450
    end

    makeLuaText('batteryPercentText', '100%', 160, textX, textY)

    setTextSize('batteryPercentText', 48)
    setTextFont('batteryPercentText', 'SFPro.otf')
    setTextBorder('batteryPercentText', 0, 'ffffff')
    
    setTextAlignment('batteryPercentText', 'right')
    setObjectCamera('batteryPercentText', 'camHUD')
    addLuaText('batteryPercentText', true)
    setObjectOrder('batteryPercentText', getObjectOrder('batteryBar') + 1)



    local customAlphaSetting = getPropertyFromClass('backend.ClientPrefs', 'data.healthBarAlpha')

    if customAlphaSetting == nil then 
        customAlphaSetting = 1.0 
    end


    setProperty('batteryPercentText.alpha', customAlphaSetting)
    setProperty('batteryBar.alpha', customAlphaSetting)
    setProperty('healthFill_Fluid.alpha', customAlphaSetting)


    setProperty('scoreTxt.visible', false)

    local scoreY = barY + 90

if not getPropertyFromClass('backend.ClientPrefs', 'data.hideHud') then
    makeLuaText('yummyScoreHUD', ':3', 1280, 0, scoreY)

    setTextSize('yummyScoreHUD', 30)
    setTextFont('yummyScoreHUD', 'SFPro.otf')
    setTextAlignment('yummyScoreHUD', 'center')
    setTextBorder('yummyScoreHUD', 0, 'ffffff')
    setObjectCamera('yummyScoreHUD', 'camHUD')
    
    addLuaText('yummyScoreHUD', true)
    setObjectOrder('yummyScoreHUD', getObjectOrder('batteryBar') + 1)
end


    if difficultyName == '1%' then
        local rankXoffset = 350
        
        for rankName, coordinates in pairs(rankPositions) do
            coordinates.x = coordinates.x - rankXoffset
        end
    end

if not getPropertyFromClass('backend.ClientPrefs', 'data.hideHud') then
    makeLuaSprite('Rank', 'frankieUI/-', rankPositions['-'].x, rankPositions['-'].y)
    
    setObjectCamera('Rank', 'camHUD')
    scaleObject('Rank', rankScaleX, rankScaleY)
    setProperty('Rank.antialiasing', useAntialiasing)
    updateHitbox('Rank')
    addLuaSprite('Rank', false) 

    makeLuaSprite('RankPop', 'frankieUI/-', rankPositions['-'].x, rankPositions['-'].y)
    setObjectCamera('RankPop', 'camHUD')
    setProperty('RankPop.antialiasing', useAntialiasing)
    addLuaSprite('RankPop', false) 
    setProperty('RankPop.alpha', 0) 

    setProperty('Rank.alpha', customAlphaSetting)
end

    setProperty('timeBar.visible', false)
    setProperty('timeBarBG.visible', false)
    setProperty('timeTxt.visible', false)

    local barWidth  = 1280    
    local barHeight = 8       
    local barX      = 0       
    local barY      = 720 - barHeight 

    makeLuaSprite('customTimeBarShadow', 'frankieUI/timerShadow', barX, barY - (84 - barHeight)) 
    setObjectCamera('customTimeBarShadow', 'camHUD')
    addLuaSprite('customTimeBarShadow', false)
    
    setGraphicSize('customTimeBarShadow', 1280, 84)
    updateHitbox('customTimeBarShadow')

    makeLuaSprite('customTimeBarFill', '', barX, barY)
    makeGraphic('customTimeBarFill', 1280, barHeight, '00BBFF') 
    setObjectCamera('customTimeBarFill', 'camHUD')
    addLuaSprite('customTimeBarFill', false)
    
    makeLuaSprite('timerNodeSprite', 'frankieUI/timerNode', 0, 0)
    setObjectCamera('timerNodeSprite', 'camHUD')
    addLuaSprite('timerNodeSprite', true) 
    
    scaleObject('timerNodeSprite', 1, 1) 
    updateHitbox('timerNodeSprite')
    setProperty('timerNodeSprite.y', barY + (barHeight / 2) - (getProperty('timerNodeSprite.height') / 2))

    makeLuaText('customClockText', '0:00 / 0:00', 270, 20, barY - 36)
    setTextSize('customClockText', 24)
    setTextAlignment('customClockText', 'left') 
    setObjectCamera('customClockText', 'camHUD')
    
    setTextFont('customClockText', 'SFPro.otf') 

    setTextColor('customClockText', '00BBFF')
    setTextBorder('customClockText', 0, '000000')

    addLuaText('customClockText')

    setProperty('customTimeBarFill.origin.x', 0)
    setVar('maxTimeBarFillWidth', barWidth)



    local currentBarOption = getPropertyFromClass('backend.ClientPrefs', 'data.timeBarType')

    if currentBarOption == 'Disabled' then
        setProperty('customTimeBarShadow.visible', false)
        setProperty('customTimeBarFill.visible', false)
        setProperty('timerNodeSprite.visible', false)
        setProperty('customClockText.visible', false)
    end 
end

local rankWeights = {
    ['-']   = 1,
    ['F']   = 2,
    ['D']   = 3,
    ['C']   = 4,
    ['B']   = 5,
    ['A']   = 6,
    ['S']   = 7,
    ['S✨'] = 8,
    ['S🏅'] = 9
}

local lastRank = '-'

function onUpdatePost(elapsed)
    if getProperty('generatedMusic') and difficultyName == '1%' and not hudIsFrozen and getProperty('health') > 0.025 then
        setProperty('health', 0.025)
        visualHealth = 0.025
        currentHealth = 0.025 
    end

    local currentHealth = getProperty('health')
    if getProperty('generatedMusic') and difficultyName == '1%' and not hudIsFrozen then currentHealth = 0.025 end

    
    local deathThreshold = (difficultyName == '1%') and 0.025 or 0.0

    local trueThreshold = (difficultyName == '1%') and 0.01 or deathThreshold
    if (getProperty('generatedMusic') and currentHealth <= trueThreshold) or hudIsFrozen then
        hudIsFrozen = true
        currentHealth = 0.0
    else

    if difficultyName == '1%' then 
        currentHealth = 0.025 
    end

            if getProperty('deathFadeOverlay.alpha') > 0 then
                currentHealth = 0.0
            else
                if currentHealth > 2.0 then currentHealth = 2.0 elseif currentHealth < 0 then currentHealth = 0 end
            end
        end

        local targetGoal = currentHealth
        local isActuallyDead = (getProperty('vocals.volume') <= 0 and getProperty('generatedMusic'))
        
        if getProperty('deathFadeOverlay.alpha') > 0 or (currentHealth >= 2.0 and isActuallyDead) then
            targetGoal = 0.0
        end
        visualHealth = visualHealth + (targetGoal - visualHealth) * (elapsed / 0.075)

    local healthPercent = visualHealth / 2.0
    local displaysPercent = (currentHealth <= 0) and 0 or math.floor((healthPercent * 100) + 0.5)
    setTextString('batteryPercentText', displaysPercent .. '%')
    
    local targetWidth = math.max(1, math.floor(barWidth * healthPercent))

    if difficultyName == '1%' then
        if visualHealth > 0.005 and not hudIsFrozen then
            local dynamicMin = math.max(1, math.floor(8 * (visualHealth / 0.025)))
            targetWidth = math.max(dynamicMin, targetWidth)
        else
            targetWidth = 1
        end
    else
        targetWidth = math.max(1, targetWidth)
    end
    
    local currentFluidPath = 'frankieUI/battery'
    if difficultyName == '1%' then currentFluidPath = 'frankieUI/1percentBattery' end
    
    loadGraphic('healthFill_Fluid', currentFluidPath, targetWidth, barHeight)

    if currentHealth <= 0.4 then
        fadeProgress = math.min(1.0, fadeProgress + (elapsed / colorFadeTime))
    else
        fadeProgress = math.max(0.0, fadeProgress - (elapsed / colorFadeTime))
    end
    
    local baseR, baseG, baseB = 62, 255, 111
    
    if getProperty('deathFadeOverlay.alpha') > 0 then
        baseR, baseG, baseB = 255, 59, 48
    elseif difficultyName == 'Low Power Mode' then
        baseR, baseG, baseB = 255, 204, 68
    elseif difficultyName == '1%' then
        baseR, baseG, baseB = 255, 59, 48
    end

    local currentR = math.floor(baseR + (255 - baseR) * fadeProgress)
    local currentG = math.floor(baseG + (59  - baseG) * fadeProgress)
    local currentB = math.floor(baseB + (48  - baseB) * fadeProgress)
    
    local hexString = string.format("%02x%02x%02x", currentR, currentG, currentB)
    setProperty('healthFill_Fluid.color', getColorFromHex(hexString))
    
    setProperty('healthFill_Fluid.x', barX + shiftRight)
    setProperty('healthFill_Fluid.y', barY + shiftDown)

    if difficultyName == '1%' then
        setTextString('yummyScoreHUD', '' .. getProperty('songScore') .. ' | ' .. string.format("%.2f", getProperty('ratingPercent') * 100) .. '%')
    else
        setTextString('yummyScoreHUD', '' .. getProperty('songScore') .. ' | Misses: ' .. getProperty('songMisses') .. ' | ' .. string.format("%.2f", getProperty('ratingPercent') * 100) .. '%')
    end

    if hasHitNote then
        local currentAccuracy = getProperty('ratingPercent')
        local currentFC = getProperty('ratingFC') 
        local currentRank = 'D'

        if currentFC == 'SFC' then
            currentRank = 'S🏅'
            loadGraphic('Rank', 'frankieUI/S🏅')

        elseif currentFC == 'GFC' then
            currentRank = 'S✨'
            loadGraphic('Rank', 'frankieUI/S✨')

        elseif not hasMissed or currentFC == 'FC' then
            currentRank = 'S'
            loadGraphic('Rank', 'frankieUI/S')

        elseif currentAccuracy == 0 then
            currentRank = 'F'
            loadGraphic('Rank', 'frankieUI/F')

        elseif (currentAccuracy >= 0.90) then
            currentRank = 'A'
            loadGraphic('Rank', 'frankieUI/A')

        elseif currentAccuracy >= 0.80 then
            currentRank = 'B'
            loadGraphic('Rank', 'frankieUI/B')

        elseif currentAccuracy >= 0.70 then
            currentRank = 'C'
            loadGraphic('Rank', 'frankieUI/C')
        else
            currentRank = 'D'
            loadGraphic('Rank', 'frankieUI/D')
        end

        setProperty('Rank.x', rankPositions[currentRank].x)
        setProperty('Rank.y', rankPositions[currentRank].y)

        if currentRank ~= lastRank then
            cancelTween('rankPopX')
            cancelTween('rankPopY')
            
            scaleObject('Rank', rankScaleX, rankScaleY)
            updateHitbox('Rank')

            setProperty('Rank.origin.x', getProperty('Rank.frameWidth') / 2)
            setProperty('Rank.origin.y', getProperty('Rank.frameHeight') / 2)
            
            local currentWeight = rankWeights[currentRank] or 1
            local lastWeight = rankWeights[lastRank] or 1

            if currentWeight > lastWeight then
                setProperty('Rank.scale.x', rankScaleX * 1.3)
                setProperty('Rank.scale.y', rankScaleY * 1.3)
            else
                setProperty('Rank.scale.x', rankScaleX * 0.7)
                setProperty('Rank.scale.y', rankScaleY * 0.7)
            end
            
            doTweenX('rankPopX', 'Rank.scale', rankScaleX, 0.4, 'cubeOut')
            doTweenY('rankPopY', 'Rank.scale', rankScaleY, 0.4, 'cubeOut')

            lastRank = currentRank
        end
    end


    if songIsCompleted then
        setProperty('customTimeBarFill.scale.x', 1.0)
        setProperty('timerNodeSprite.x', 1280 - (getProperty('timerNodeSprite.width') / 2))
        return
    end

    if getProperty('songLength') == nil or getProperty('songLength') <= 10 or getSongPosition() <= 0 then
        return
    end

    local currentPos = getSongPosition()
    local totalLength = getProperty('songLength')

    if (totalLength - currentPos) <= 50 or getProperty('songPercent') >= 1.0 then
        songIsCompleted = true
        currentPos = totalLength
    end

    currentPos = math.max(0, math.min(currentPos, totalLength))
    local progressPercent = currentPos / totalLength

    setProperty('customTimeBarFill.scale.x', progressPercent)
    
    local nodeTargetX = (progressPercent * 1280) - (getProperty('timerNodeSprite.width') / 2)
    setProperty('timerNodeSprite.x', nodeTargetX)


    local currentBarOption = getPropertyFromClass('backend.ClientPrefs', 'data.timeBarType')

    if currentBarOption == 'Song Name' then
        local currentSongTitle = getProperty('songName') or 'Unknown'
        setTextString('customClockText', currentSongTitle)
    else

    local curSeconds = math.floor(currentPos / 1000)
    local curMins = math.floor(curSeconds / 60)
    local curSecsRemain = curSeconds % 60

    local totSeconds = math.floor(totalLength / 1000)
    local totMins = math.floor(totSeconds / 60)
    local totSecsRemain = totSeconds % 60

    local curString = curMins .. ':' .. (curSecsRemain < 10 and '0' or '') .. curSecsRemain
    local totString = totMins .. ':' .. (totSecsRemain < 10 and '0' or '') .. totSecsRemain

    setTextString('customClockText', curString .. ' / ' .. totString)
end
end

function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    hasHitNote = true 

    if difficultyName == 'Hard' then
        local currentHealth = getProperty('health')
        local baseGain = isSustainNote and 0.004 or 0.023
        
        local finalGain = baseGain * globalGainSetting * myGainMult
        
        setProperty('health', math.min(2, currentHealth + finalGain))
    end
end

function noteMiss(id, noteData, noteType, isSustainNote)
    hasHitNote = true 
    hasMissed = true  

    if difficultyName == 'Hard' then
        local currentHealth = getProperty('health')
        
        local baseLoss = 0.1
        
        local finalLoss = baseLoss * globalLossSetting * myLossMult
        
        setProperty('health', math.max(0, currentHealth - finalLoss))
    end

    if difficultyName == '1%' then
        setProperty('health', 0)
    end
end

function onTweenCompleted(tag)
    if tag == 'rankPopX' or tag == 'rankPopY' then
        updateHitbox('Rank')
    end
end

function onEndSong()
    songIsCompleted = true
    
    local totalLength = getProperty('songLength') or 0
    local totSeconds = math.floor(totalLength / 1000)
    local totMins = math.floor(totSeconds / 60)
    local totSecsRemain = totSeconds % 60
    local totString = totMins .. ':' .. (totSecsRemain < 10 and '0' or '') .. totSecsRemain
    
    setTextString('customClockText', totString .. ' / ' .. totString)
    setProperty('customTimeBarFill.scale.x', 1.0)
    setProperty('timerNodeSprite.x', 1280 - (getProperty('timerNodeSprite.width') / 2))

    return Function_Continue
end