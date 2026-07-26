local isDying = false
local deathStartTime = 0.0 

function onCreatePost()
    makeLuaSprite('deathFadeOverlay', 'frankieUI/black', 0, 0)
    setGraphicSize('deathFadeOverlay', 1280, 720)
    updateHitbox('deathFadeOverlay')
    setObjectCamera('deathFadeOverlay', 'other')
    setProperty('deathFadeOverlay.alpha', 0)
    addLuaSprite('deathFadeOverlay', false) 

    local hudBaseOrder = getObjectOrder('batteryPercentText') or 100

    makeLuaSprite('deathFreezeFrameSnapshot', '', 0, 0)
    setObjectCamera('deathFreezeFrameSnapshot', 'other')
    setProperty('deathFreezeFrameSnapshot.alpha', 0)    
    addLuaSprite('deathFreezeFrameSnapshot', true)
    
    setObjectOrder('deathFreezeFrameSnapshot', hudBaseOrder + 9)
    setObjectOrder('deathFadeOverlay', hudBaseOrder + 10)
    setObjectOrder('deathIconFrame',   hudBaseOrder + 11)
    setObjectOrder('deathIconBattery', hudBaseOrder + 12)

    local targetWidth  = 235  
    local targetHeight = 150 
    local newCenterX = (1280 / 2) - (targetWidth / 2)
    local newCenterY = (720 / 2) - (targetHeight / 2)

    makeLuaSprite('deathIconFrame', 'frankieUI/deathFrame', newCenterX, newCenterY)
    setGraphicSize('deathIconFrame', targetWidth, targetHeight)
    updateHitbox('deathIconFrame')
    setObjectCamera('deathIconFrame', 'other')
    setProperty('deathIconFrame.alpha', 0) 
    addLuaSprite('deathIconFrame', true)   

    makeLuaSprite('deathIconBattery', 'frankieUI/deathBattery', newCenterX, newCenterY)
    setGraphicSize('deathIconBattery', targetWidth, targetHeight)
    updateHitbox('deathIconBattery')
    setObjectCamera('deathIconBattery', 'other')
    setProperty('deathIconBattery.alpha', 0) 
    addLuaSprite('deathIconBattery', true)   
end

function onUpdatePost(elapsed)
    if getProperty('health') == nil or not getProperty('generatedMusic') then 
        return 
    end

    local currentHealth = getProperty('health')
    local difficulty = getProperty('storyDifficultyText')
    local deathThreshold = (difficulty == '1%') and 0.02 or 0.0

    if isDying then
        Die()
        return
    end
    
    if (currentHealth <= deathThreshold) and not isDying then
        triggerCustomDeathLayout()
    end
end

function triggerCustomDeathLayout()
    isDying = true
    deathStartTime = os.clock()
    runTimer('deathSoundDelay', 0.05)
    
    setProperty('health', 2.0)

    runHaxeCode([[
        var gameSizeX = FlxG.scaleMode.gameSize.x;
        var gameSizeY = FlxG.scaleMode.gameSize.y;
        
        var snapCanvas = Type.createInstance(Type.resolveClass("openfl.display.BitmapData"), [gameSizeX, gameSizeY, true, 0]);
        snapCanvas.draw(FlxG.game);
        
        var spr = game.getLuaObject("deathFreezeFrameSnapshot");
        if (spr != null) {
            var cacheKey = "death_snapshot_" + game.songName;
            FlxG.bitmap.removeByKey(cacheKey);
            
            var gfxClass = Type.resolveClass("flixel.graphics.FlxGraphic");
            var wrappedGfx = gfxClass.fromBitmapData(snapCanvas, false, cacheKey, false);
            spr.loadGraphic(wrappedGfx);
        }
    ]])

    setProperty('deathFreezeFrameSnapshot.alpha', 1)
    setGraphicSize('deathFreezeFrameSnapshot', 1280, 720)
    updateHitbox('deathFreezeFrameSnapshot')

    setPropertyFromClass('states.PlayState', 'deathCounter', getPropertyFromClass('states.PlayState', 'deathCounter') + 1)

    setProperty('playbackRate', 0)
    setProperty('vocals.volume', 0)
    setProperty('inst.volume', 0)
end

function onGameOver()
    if not isDying then
        triggerCustomDeathLayout()
    end
    
    return Function_Stop
end

function onTimerCompleted(tag)
    if tag == 'deathSoundDelay' then
        playSound('batteryDeplete', 1.0)
    end
end

function Die()
    local secondsPassed = os.clock() - deathStartTime

    local fadeInTime  = 0.3 
    local freezeHold  = 1.5 
    local blackoutTime = 0.2

    local iconFadeInTime  = 0.15
    local iconFadeOutTime = 0.1

    local startScaleSize  = 0.9
    local exitScaleSize   = 0.9
    
    local endOfFadeIn   = fadeInTime
    local endOfHold     = fadeInTime + freezeHold
    local endOfBlackout = fadeInTime + freezeHold + blackoutTime

    if secondsPassed <= endOfFadeIn then
        local progress = secondsPassed / fadeInTime
        setProperty('deathFadeOverlay.alpha', progress * 0.5)
        
        local iconProgress = math.min(1.0, secondsPassed / iconFadeInTime)
        setProperty('deathIconFrame.alpha', iconProgress)
        
        local scaleValue = startScaleSize + ((1.0 - startScaleSize) * iconProgress)
        setProperty('deathIconFrame.scale.x', scaleValue)
        setProperty('deathIconFrame.scale.y', scaleValue)
        setProperty('deathIconBattery.scale.x', scaleValue)
        setProperty('deathIconBattery.scale.y', scaleValue)

        local totalCombinedTime = fadeInTime + freezeHold
        local globalProgress = secondsPassed / totalCombinedTime

        if globalProgress <= 0.25 then
            setProperty('deathIconBattery.alpha', iconProgress)
        elseif globalProgress > 0.25 and globalProgress <= 0.50 then
            setProperty('deathIconBattery.alpha', 0.0) 
        elseif globalProgress > 0.50 and globalProgress <= 0.75 then
            setProperty('deathIconBattery.alpha', iconProgress) 
        else
            setProperty('deathIconBattery.alpha', 0.0) 
        end

    elseif secondsPassed > endOfFadeIn and secondsPassed <= endOfHold then
        setProperty('deathFadeOverlay.alpha', 0.5)
        setProperty('deathIconFrame.alpha', 1.0)
        
        setProperty('deathIconFrame.scale.x', 1.0)
        setProperty('deathIconFrame.scale.y', 1.0)
        setProperty('deathIconBattery.scale.x', 1.0)
        setProperty('deathIconBattery.scale.y', 1.0)

        local totalCombinedTime = fadeInTime + freezeHold
        local globalProgress = secondsPassed / totalCombinedTime

        if globalProgress <= 0.25 then
            setProperty('deathIconFrame.alpha', 1.0)
            setProperty('deathIconBattery.alpha', 1.0)
        elseif globalProgress > 0.25 and globalProgress <= 0.50 then
            setProperty('deathIconFrame.alpha', 0.8)
            setProperty('deathIconBattery.alpha', 0.0)
        elseif globalProgress > 0.50 and globalProgress <= 0.75 then
            setProperty('deathIconFrame.alpha', 1.0)
            setProperty('deathIconBattery.alpha', 1.0)
        else
            setProperty('deathIconFrame.alpha', 0.8)
            setProperty('deathIconBattery.alpha', 0.0)
        end

    elseif secondsPassed > endOfHold and secondsPassed <= endOfBlackout then
        local progress = (secondsPassed - endOfHold) / blackoutTime
        setProperty('deathFadeOverlay.alpha', math.min(1.0, 0.5 + (progress * 0.5)))
        
        local iconSeconds = secondsPassed - endOfHold
        local iconProgress = iconSeconds / iconFadeOutTime
        
        setProperty('deathIconFrame.alpha', math.max(0.0, 1.0 - iconProgress))
        setProperty('deathIconBattery.alpha', math.max(0.0, 1.0 - iconProgress))
        
        local scaleValue = math.max(exitScaleSize, 1.0 - ((1.0 - exitScaleSize) * iconProgress))
        setProperty('deathIconFrame.scale.x', scaleValue)
        setProperty('deathIconFrame.scale.y', scaleValue)
        setProperty('deathIconBattery.scale.x', scaleValue)
        setProperty('deathIconBattery.scale.y', scaleValue)
        
    elseif secondsPassed > endOfBlackout then
        setProperty('playbackRate', 1)
        restartSong(true)
    end
end

function onPause()
    if isDying then
        return Function_Stop
    end
end
