require "Util/LuaList"

for i = 1, #PrintMediaDefinitions.FortuneMessage do
    PrintMediaEntries.addPrintMediaEntry(PrintMediaDefinitions.FortuneMessage[i], "SapphCooking.FortuneMessage")
end