function onCreate()

    setProperty("skipCountdown", true)

    makeLuaSprite('C-sky', 'C-sky', -2500, -1500)
    setScrollFactor('C-sky', 0, 0)
    addLuaSprite('C-sky', false)

    makeLuaSprite('BG1', 'bbc', 1000, -600)
    setScrollFactor('BG1', 0.3, 0.3)
    scaleObject('BG1', 0.8, 0.8)
    addLuaSprite('BG1', false)

    makeLuaSprite('BG2', 'bbc', 24000, -600)
    setScrollFactor('BG2', 0.3, 0.3)
    scaleObject('BG2', 0.8, 0.8)
    addLuaSprite('BG2', false)

    makeLuaSprite('A-train', 'A-train', -3900, -300)
    setScrollFactor('A-train', 1.0, 1.0)
    scaleObject('A-train', 0.8, 0.8)
    addLuaSprite('A-train', false)
end

function onUpdate(elapsed)
    setProperty('BG1.x', getProperty('BG1.x') + (6000 * elapsed))
    setProperty('BG2.x', getProperty('BG2.x') + (6000 * elapsed))

    if getProperty('BG1.x') > 1000 then
        setProperty('BG1.x', -21000)
        setProperty('BG2.x', -43000)
    end
end

function onCreatePost()
    setCameraScroll(0, 300) 
end
