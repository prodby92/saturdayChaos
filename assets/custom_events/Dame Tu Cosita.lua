local saveY = 0.0
local char = 'dad'
local bounceTime = 0.1
local bounceHeight = 60

function onEvent(name, v1, v2)
    if name == 'Dame Tu Cosita' then
        char = v1        
        if char == 'dad' then
            saveY = getProperty("dad.y")
            triggerEvent('Play Animation', v2, 'Dad')
        else
            saveY = getProperty("boyfriend.y")
            triggerEvent('Play Animation', v2, 'BF')
        end
        doTweenY("y1", char, saveY - bounceHeight, bounceTime, "circOut")
    end
end

function onTweenCompleted(tag)
    if tag == 'y1' then
        doTweenY("y2", char, saveY, bounceTime, "circIn")
    end

    if tag == 'y2' then
        doTweenY("y3", char, saveY - (bounceHeight * 0.1), bounceTime / 2, "circOut")
    end

    if tag == 'y3' then
        doTweenY("y4", char, saveY, bounceTime / 2, "bounceOut")
    end
end