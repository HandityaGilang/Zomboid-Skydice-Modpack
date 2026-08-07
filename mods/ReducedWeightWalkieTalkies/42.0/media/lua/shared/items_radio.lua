local changeWeight = function (name, property, value)
  local item = ScriptManager.instance:getItem(name)
  if item then item:DoParam(property .. " = " .. value) end
end

changeWeight("Base.WalkieTalkie1","Weight","0.1")
changeWeight("Base.WalkieTalkie2","Weight","0.1")
changeWeight("Base.WalkieTalkie3","Weight","0.1")
changeWeight("Base.WalkieTalkie4","Weight","0.1")
changeWeight("Base.WalkieTalkie5","Weight","0.1")
changeWeight("Base.WalkieTalkieMakeShift","Weight","0.1")
