function onEvent(name, value1, value2)
	if name == 'angela' then
        setProperty("angela.alpha", 1)
        playAnim("angela", "hey")
        playAnim("sofia", "surprise")
    end
end