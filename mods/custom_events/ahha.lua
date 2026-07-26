function onEvent(name, value1, value2)
	if name == 'ahha' then
        setProperty("ahha.alpha", 1)
        playAnim("ahha", "ahha")
    end
end