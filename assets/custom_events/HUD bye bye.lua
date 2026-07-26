function onEvent(name, v1, v2)
    if name == 'HUD bye bye' then
        doTweenAlpha('hudTween', 'camHUD', v1, v2, 'quadIn')
    end
end