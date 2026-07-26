local peakOffsetX = 40
local peakOffsetY = 40

local activeRatingTag = ''
local activeComboTags = {}

function onCreatePost()
    setProperty('showRating', false)
    setProperty('showComboNum', false)
end

function goodNoteHit(note)
    if getPropertyFromGroup('notes', note, 'isSustainNote') then return end
    if getPropertyFromClass('backend.ClientPrefs', 'data.hideHud') then return end

    local stackingDisabled = not getPropertyFromClass('backend.ClientPrefs', 'data.comboStacking')

    if stackingDisabled and activeRatingTag ~= '' then
        cancelTimer(activeRatingTag .. '_fade')
        cancelTween(activeRatingTag .. '_tween')
        removeLuaSprite(activeRatingTag, true)
        activeRatingTag = ''
    end

    if stackingDisabled and #activeComboTags > 0 then
        for _, tagToKill in ipairs(activeComboTags) do
            cancelTimer(tagToKill .. '_fade')
            cancelTween(tagToKill .. '_tween')
            removeLuaSprite(tagToKill, true)
        end
        activeComboTags = {}
    end

    local ratingStr = getPropertyFromGroup('notes', note, 'rating')
    local judgementImgName = ''

    if ratingStr == 'sick' then judgementImgName = 'PEAK'
    elseif ratingStr == 'good' then judgementImgName = 'nice'
    elseif ratingStr == 'bad' then judgementImgName = 'ok'
    elseif ratingStr == 'shit' then judgementImgName = 'lmao'
    end
    
    if judgementImgName ~= '' then
        local tag = 'hudRating' .. getProperty('songHits')
        activeRatingTag = tag 
        
        local judgementSpawnX = 330 + 120
        local judgementSpawnY = 235
        
        if ratingStr == 'sick' then
            judgementSpawnX = judgementSpawnX - peakOffsetX
            judgementSpawnY = judgementSpawnY - peakOffsetY
        end

        makeLuaSprite(tag, 'frankieUI/' .. judgementImgName, judgementSpawnX, judgementSpawnY)
        setObjectCamera(tag, 'camHUD')
        
        setProperty(tag .. '.scale.x', 0.7)
        setProperty(tag .. '.scale.y', 0.7)
        updateHitbox(tag)
        
        addLuaSprite(tag, false)

        setProperty(tag .. '.velocity.y', -160)   
        setProperty(tag .. '.acceleration.y', 450) 
        
        runTimer(tag .. '_fade', 0.5)

        local comboCount = getProperty('combo')
        
        if comboCount >= 1 then
            local comboStr = tostring(comboCount)
            
            for i = 1, #comboStr do
                local digit = string.sub(comboStr, i, i)
                local numTag = 'hudComboDigit_' .. getProperty('songHits') .. '_' .. i
                
                if stackingDisabled then
                    table.insert(activeComboTags, numTag)
                end
                
                local digitSpacing = 55 * (i - 1) 
                local numX = 330 + 120 + digitSpacing
                local numY = 320
                
                makeLuaSprite(numTag, 'frankieUI/' .. digit, numX, numY)
                setObjectCamera(numTag, 'camHUD')
                
                setProperty(numTag .. '.scale.x', 0.8)
                setProperty(numTag .. '.scale.y', 0.8)
                updateHitbox(numTag)
                
                addLuaSprite(numTag, false)
                
                setProperty(numTag .. '.velocity.y', -140 - math.random(0, 20))
                setProperty(numTag .. '.acceleration.y', 450)
                
                runTimer(numTag .. '_fade', 0.5)
            end
        end
    end
end

function onTimerCompleted(tag)
    if string.sub(tag, 1, 9) == 'hudRating' or string.sub(tag, 1, 8) == 'hudCombo' then
        local targetJudgementSprite = string.sub(tag, 1, -6) 
        doTweenAlpha(targetJudgementSprite .. '_tween', targetJudgementSprite, 0, 0.15, 'linear')
    end
end

function onTweenCompleted(tag)
    if string.sub(tag, 1, 9) == 'hudRating' or string.sub(tag, 1, 8) == 'hudCombo' then
        local cleanJudgementSprite = string.sub(tag, 1, -7)
        removeLuaSprite(cleanJudgementSprite, true)
        
        if cleanJudgementSprite == activeRatingTag then
            activeRatingTag = ''
        end
    end
end
