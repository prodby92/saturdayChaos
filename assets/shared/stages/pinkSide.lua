function onCreate()
    setProperty("skipCountdown", true)

    makeLuaSprite('sky', 'pinkSide/sky', -2000, -1200)
    setScrollFactor('sky', 0, 0)
    addLuaSprite('sky', false)

    makeLuaSprite('skyAccentA', 'pinkSide/skyAccent', -2500, -1100)
    setScrollFactor('skyAccentA', 0.05, 0.05)
    scaleObject('skyAccentA', 0.8, 0.8)
    addLuaSprite('skyAccentA', false)

    makeLuaSprite('skyAccentB', 'pinkSide/skyAccent', 2500, -1100)
    setScrollFactor('skyAccentB', 0.05, 0.05)
    scaleObject('skyAccentB', 0.8, 0.8)
    addLuaSprite('skyAccentB', false)

    makeLuaSprite('heartsTinyA', 'pinkSide/heartsTiny', -1000, -900)
    setScrollFactor('heartsTinyA', 0.1, 0.1)
    scaleObject('heartsTinyA', 0.8, 0.8)
    addLuaSprite('heartsTinyA', false)

    makeLuaSprite('heartsTinyB', 'pinkSide/heartsTiny', 3000, -900)
    setScrollFactor('heartsTinyB', 0.1, 0.1)
    scaleObject('heartsTinyB', 0.8, 0.8)
    addLuaSprite('heartsTinyB', false)

    makeLuaSprite('heartsSmallA', 'pinkSide/heartsSmall', -1000, -900)
    setScrollFactor('heartsSmallA', 0.15, 0.15)
    scaleObject('heartsSmallA', 0.8, 0.8)
    addLuaSprite('heartsSmallA', false)

    makeLuaSprite('heartsSmallB', 'pinkSide/heartsSmall', 3000, -900)
    setScrollFactor('heartsSmallB', 0.15, 0.15)
    scaleObject('heartsSmallB', 0.8, 0.8)
    addLuaSprite('heartsSmallB', false)

    makeLuaSprite('heartsMedA', 'pinkSide/heartsMed', -1000, -900)
    setScrollFactor('heartsMedA', 0.2, 0.2)
    scaleObject('heartsMedA', 0.8, 0.8)
    addLuaSprite('heartsMedA', false)

    makeLuaSprite('heartsMedB', 'pinkSide/heartsMed', 3000, -900)
    setScrollFactor('heartsMedB', 0.2, 0.2)
    scaleObject('heartsMedB', 0.8, 0.8)
    addLuaSprite('heartsMedB', false)

    makeLuaSprite('heartsBigA', 'pinkSide/heartsBig', -1000, -900)
    setScrollFactor('heartsBigA', 0.2, 0.2)
    scaleObject('heartsBigA', 0.8, 0.8)
    addLuaSprite('heartsBigA', false)

    makeLuaSprite('heartsBigB', 'pinkSide/heartsBig', 3300, -900)
    setScrollFactor('heartsBigB', 0.2, 0.2)
    scaleObject('heartsBigB', 0.8, 0.8)
    addLuaSprite('heartsBigB', false)

    makeLuaSprite('sparklesBgA', 'pinkSide/sparklesBg', -1000, -900)
    setScrollFactor('sparklesBgA', 0.2, 0.2)
    scaleObject('sparklesBgA', 0.8, 0.8)
    addLuaSprite('sparklesBgA', false)

    makeLuaSprite('sparklesBgB', 'pinkSide/sparklesBg', 3300, -900)
    setScrollFactor('sparklesBgB', 0.2, 0.2)
    scaleObject('sparklesBgB', 0.8, 0.8)
    addLuaSprite('sparklesBgB', false)

    makeLuaSprite('treesBg', 'pinkSide/treesBg', -1800, -400)
    setScrollFactor('treesBg', 0.3, 0.3)
    scaleObject('treesBg', 0.8, 0.8)
    addLuaSprite('treesBg', false)

    makeLuaSprite('trees', 'pinkSide/trees', -1800, -400)
    setScrollFactor('trees', 0.35, 0.35)
    scaleObject('trees', 0.8, 0.8)
    addLuaSprite('trees', false)

    makeLuaSprite('mp3Player', 'pinkSide/mp3Player', -700, 100)
    setScrollFactor('mp3Player', 0.5, 0.5)
    scaleObject('mp3Player', 0.6, 0.6)
    addLuaSprite('mp3Player', false)

    makeLuaSprite('headphones', 'pinkSide/headphones', 300, -400)
    setScrollFactor('headphones', 0.5, 0.5)
    scaleObject('headphones', 0.6, 0.6)
    addLuaSprite('headphones', false)

    makeLuaSprite('flipphone', 'pinkSide/flipphone', 900, 400)
    setScrollFactor('flipphone', 0.5, 0.5)
    scaleObject('flipphone', 0.6, 0.6)
    addLuaSprite('flipphone', false)

    makeLuaSprite('pinkCD', 'pinkSide/pinkCD', 1800, -100)
    setScrollFactor('pinkCD', 0.5, 0.5)
    scaleObject('pinkCD', 0.6, 0.6)
    addLuaSprite('pinkCD', false)

    makeAnimatedLuaSprite('notes', 'pinkSide/notes', 500, -400)
    addAnimationByPrefix('notes', 'loop', 'notes', 6, true)
    setScrollFactor('notes', 1, 1)
    scaleObject('notes', 0.8, 0.8)
    addLuaSprite('notes', false)
    objectPlayAnimation('notes', 'loop', true)

    makeAnimatedLuaSprite('lolipop', 'pinkSide/lolipop', -600, 00)
    addAnimationByPrefix('lolipop', 'loop', 'lolipop', 6, true)
    setScrollFactor('lolipop', 1, 1)
    scaleObject('lolipop', 0.8, 0.8)
    addLuaSprite('lolipop', false)
    objectPlayAnimation('lolipop', 'loop', true)

    makeAnimatedLuaSprite('controller', 'pinkSide/controller', 1500, 400)
    addAnimationByPrefix('controller', 'loop', 'controller', 6, true)
    setScrollFactor('controller', 1, 1)
    scaleObject('controller', 0.8, 0.8)
    addLuaSprite('controller', false)
    objectPlayAnimation('controller', 'loop', true)

    makeAnimatedLuaSprite('heartCandies', 'pinkSide/heartCandies', 2200, -200)
    addAnimationByPrefix('heartCandies', 'loop', 'heartCandies', 6, true)
    setScrollFactor('heartCandies', 1, 1)
    scaleObject('heartCandies', 0.8, 0.8)
    addLuaSprite('heartCandies', false)
    objectPlayAnimation('heartCandies', 'loop', true)

    makeLuaSprite('bgTiles', 'pinkSide/bgTiles', -1700, 500)
    setScrollFactor('bgTiles', 1, 1)
    scaleObject('bgTiles', 1, 1)
    addLuaSprite('bgTiles', false)

    makeAnimatedLuaSprite('spikes', 'pinkSide/spikes', -1620, 920)
    addAnimationByPrefix('spikes', 'loop', 'spikes', 6, true)
    setScrollFactor('spikes', 1, 1)
    scaleObject('spikes', 1, 1)
    addLuaSprite('spikes', false)
    objectPlayAnimation('spikes', 'loop', true)

    makeLuaSprite('fgTiles', 'pinkSide/fgTiles', -1700, 500)
    setScrollFactor('fgTiles', 1, 1)
    scaleObject('fgTiles', 1, 1)
    addLuaSprite('fgTiles', false)

    makeAnimatedLuaSprite('sparkleField', 'pinkSide/sparkleField', -1300, 00)
    addAnimationByPrefix('sparkleField', 'loop', 'sparkleField', 12, true)
    setScrollFactor('sparkleField', 1.2, 1.2)
    scaleObject('sparkleField', 1.5, 1.5)
    setProperty('sparkleField.alpha', 0.6)
    addLuaSprite('sparkleField', true)
    objectPlayAnimation('sparkleField', 'loop', true)
end







function onUpdate(elapsed)
    setProperty('skyAccentA.x', getProperty('skyAccentA.x') + (-200 * elapsed))
    setProperty('skyAccentB.x', getProperty('skyAccentB.x') + (-200 * elapsed))

    if getProperty('skyAccentA.x') < -7500 then
        setProperty('skyAccentA.x', -2500)
        setProperty('skyAccentB.x', 2500)
    end

    setProperty('heartsTinyA.x', getProperty('heartsTinyA.x') + (-1500 * elapsed))
    setProperty('heartsTinyB.x', getProperty('heartsTinyB.x') + (-1500 * elapsed))

    if getProperty('heartsTinyA.x') < -5000 then
        setProperty('heartsTinyA.x', -1000)
        setProperty('heartsTinyB.x', 3000)
    end

    setProperty('heartsSmallA.x', getProperty('heartsSmallA.x') + (-1200 * elapsed))
    setProperty('heartsSmallB.x', getProperty('heartsSmallB.x') + (-1200 * elapsed))

    if getProperty('heartsSmallA.x') < -5000 then
        setProperty('heartsSmallA.x', -1000)
        setProperty('heartsSmallB.x', 3000)
    end

    setProperty('heartsMedA.x', getProperty('heartsMedA.x') + (-900 * elapsed))
    setProperty('heartsMedB.x', getProperty('heartsMedB.x') + (-900 * elapsed))

    if getProperty('heartsMedA.x') < -5000 then
        setProperty('heartsMedA.x', -1000)
        setProperty('heartsMedB.x', 3000)
    end

    setProperty('heartsBigA.x', getProperty('heartsBigA.x') + (-600 * elapsed))
    setProperty('heartsBigB.x', getProperty('heartsBigB.x') + (-600 * elapsed))

    if getProperty('heartsBigA.x') < -5300 then
        setProperty('heartsBigA.x', -1000)
        setProperty('heartsBigB.x', 3300)
    end

    setProperty('sparklesBgA.x', getProperty('sparklesBgA.x') + (-300 * elapsed))
    setProperty('sparklesBgB.x', getProperty('sparklesBgB.x') + (-300 * elapsed))

    if getProperty('sparklesBgA.x') < -5300 then
        setProperty('sparklesBgA.x', -1000)
        setProperty('sparklesBgB.x', 3300)
    end
end