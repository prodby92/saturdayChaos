function onCreate()

    setProperty("skipCountdown", true)

    makeLuaSprite('G-bg', 'G-bg', -5000, -2000)
    setScrollFactor('F-star', 0, 0)
    scaleObject('G-bg', 3, 3)
    addLuaSprite('G-bg', false)

    makeLuaSprite('F-star', 'F-star', -1750, -1750)
    setScrollFactor('F-star', 0.05, 0.05)
    scaleObject('F-star', 1.5, 1.5)
    addLuaSprite('F-star', false)

    makeLuaSprite('E-backback', 'E-backback', -1500, -400)
    setScrollFactor('E-backback', 0.1, 0.1)
    scaleObject('E-backback', 1.5, 1.5)
    addLuaSprite('E-backback', false)

    makeLuaSprite('D-backfront', 'D-backfront', -1500, -50)
    setScrollFactor('D-backfront', 0.15, 0.15)
    scaleObject('D-backfront', 1.5, 1.5)
    addLuaSprite('D-backfront', false)

    makeLuaSprite('C-bigPillar', 'C-bigPillar', 400, -1000)
    setScrollFactor('C-bigPillar', 0.4, 0.4)
    scaleObject('C-bigPillar', 1.5, 1.5)
    addLuaSprite('C-bigPillar', false)

    makeLuaSprite('B-smallPillars', 'B-smallPillars', -1200, -700)
    setScrollFactor('B-smallPillars', 0.5, 0.5)
    scaleObject('B-smallPillars', 1.6, 1.6)
    addLuaSprite('B-smallPillars', false)

    makeLuaSprite('A-platform', 'A-platform', -2400, 300)
    setScrollFactor('A-platform', 1.0, 1.0)
    scaleObject('A-platform', 2.2, 2.4)
    addLuaSprite('A-platform', false)

    makeLuaSprite('vignette', 'vignette', -1300, -800)
    setScrollFactor('vignette', 0, 0)
    scaleObject('vignette', 3.2, 3.2)
    addLuaSprite('vignette', true)
end

function onCreatePost()
    setCameraScroll(0, 0) 
end
