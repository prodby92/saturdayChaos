function onEvent(name, value1, value2)
   if name == 'Camera Flash' then
      makeLuaSprite('flash')
      makeGraphic('flash', 2000, 2000, value1)
      setObjectCamera('flash', 'Other')
      addLuaSprite('flash')
      if songName == 'Akuma-No-Bushi' then
         setObjectCamera('flash', 'HUD')
      end

      doTweenAlpha('flashTwn', 'flash', 0, value2)
   end
end