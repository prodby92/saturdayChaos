function onEvent(name, v1, v2)
    if name == 'CamZoom Change' then
        if v1 == 'add' then
            setProperty('defaultCamZoom', getProperty('defaultCamZoom') + v2)
        elseif v1 == 'sub' then
            setProperty('defaultCamZoom', getProperty('defaultCamZoom') - v2)
        end
    end
end