--------------------------------------------------------------------------------------------------
--        ----      |              |            |         |                |    --    |      ----            --
--        ----      |              |            |         |                |    --       |      ----            --
--        ----      |        -------       -----|     ---------        -----          -      ----       -------
--        ----      |            ---            |         -----        ------        --      ----            --
--        ----      |            ---            |         -----        -------          ---      ----            --
--        ----      |        -------       ----------     -----        -------         ---      ----       -------
--            |      |        -------            |         -----        -------         ---          |            --
--            |      |        -------            |          -----        -------         ---          |            --
--------------------------------------------------------------------------------------------------


require "ISUI/ISPanelJoypad"
require "LifestyleCore/LSK_Scheduler"

DJSoundboardOverlay = ISPanelJoypad:derive("DJSoundboardOverlay");

local DJBoothNumberCount = 0
local DJBoothNumberTotal = 40
local DJFailstateTexture = false

local onMouseUpBigButtonRecorded
local DJBoothCustomLoopNumberCount = 0
local DJBoothCustomLoopNumberCountTotal = 0
local DJBoothCustomLoopNumberLimit = 999
local DJBoothCustomLoopNumberCount2 = 1000
local DJBoothCustomLoopNumberCountTotal2 = 0
local DJBoothCustomLoopNumberLimit2 = 1999
local DJBoothCustomLoopNumberCount3 = 2000
local DJBoothCustomLoopNumberCountTotal3 = 0
local DJBoothCustomLoopNumberLimit3 = 2999
local DJBoothThisNumberCount
local DJBoothCustomLoopNumberTime1 = {}; local DJBoothCustomLoopNumberTime2 = {}; local DJBoothCustomLoopNumberTime3 = {}; local DJBoothCustomLoopNumberTime4 = {}; local DJBoothCustomLoopNumberTime5 = {}; local DJBoothCustomLoopNumberTime6 = {}; local DJBoothCustomLoopNumberTime7 = {}; local DJBoothCustomLoopNumberTime8 = {}; local DJBoothCustomLoopNumberTime9 = {}; local DJBoothCustomLoopNumberTime10 = {};
local DJBoothCustomLoopNumberTime11 = {}; local DJBoothCustomLoopNumberTime12 = {}; local DJBoothCustomLoopNumberTime13 = {}; local DJBoothCustomLoopNumberTime14 = {}; local DJBoothCustomLoopNumberTime15 = {}; local DJBoothCustomLoopNumberTime16 = {}; local DJBoothCustomLoopNumberTime17 = {}; local DJBoothCustomLoopNumberTime18 = {}; local DJBoothCustomLoopNumberTime19 = {}; local DJBoothCustomLoopNumberTime20 = {};
local DJBoothCustomLoopNumberTime21 = {}; local DJBoothCustomLoopNumberTime22 = {}; local DJBoothCustomLoopNumberTime23 = {}; local DJBoothCustomLoopNumberTime24 = {}; local DJBoothCustomLoopNumberTime25 = {}; local DJBoothCustomLoopNumberTime26 = {}; local DJBoothCustomLoopNumberTime27 = {}; local DJBoothCustomLoopNumberTime28 = {}; local DJBoothCustomLoopNumberTime29 = {}; local DJBoothCustomLoopNumberTime30 = {};
local DJBoothCustomLoopNumberTime31 = {}; local DJBoothCustomLoopNumberTime32 = {}; local DJBoothCustomLoopNumberTime33 = {}; local DJBoothCustomLoopNumberTime34 = {}; local DJBoothCustomLoopNumberTime35 = {}; local DJBoothCustomLoopNumberTime36 = {}; local DJBoothCustomLoopNumberTime37 = {}; local DJBoothCustomLoopNumberTime38 = {}; local DJBoothCustomLoopNumberTime39 = {}; local DJBoothCustomLoopNumberTime40 = {};
local DJBoothCustomLoopNumberTime41 = {}; local DJBoothCustomLoopNumberTime42 = {};-- local DJBoothCustomLoopNumberTime43 = {}; local DJBoothCustomLoopNumberTime44 = {}; local DJBoothCustomLoopNumberTime45 = {}; local DJBoothCustomLoopNumberTime46 = {}; local DJBoothCustomLoopNumberTime47 = {}; local DJBoothCustomLoopNumberTime48 = {}; local DJBoothCustomLoopNumberTime49 = {}; local DJBoothCustomLoopNumberTime50 = {};
--local DJBoothCustomLoopNumberTime51 = {}; local DJBoothCustomLoopNumberTime52 = {}; local DJBoothCustomLoopNumberTime53 = {}; local DJBoothCustomLoopNumberTime54 = {}; local DJBoothCustomLoopNumberTime55 = {}; local DJBoothCustomLoopNumberTime56 = {}; local DJBoothCustomLoopNumberTime57 = {}; local DJBoothCustomLoopNumberTime58 = {}; local DJBoothCustomLoopNumberTime59 = {}; local DJBoothCustomLoopNumberTime60 = {};
--local DJBoothCustomLoopNumberTime61 = {}; local DJBoothCustomLoopNumberTime62 = {}; local DJBoothCustomLoopNumberTime63 = {}; local DJBoothCustomLoopNumberTime64 = {}; local DJBoothCustomLoopNumberTime65 = {}; local DJBoothCustomLoopNumberTime66 = {}; local DJBoothCustomLoopNumberTime67 = {}; local DJBoothCustomLoopNumberTime68 = {}; local DJBoothCustomLoopNumberTime69 = {}; local DJBoothCustomLoopNumberTime70 = {};
--local DJBoothCustomLoopNumberTime71 = {}; local DJBoothCustomLoopNumberTime72 = {}; local DJBoothCustomLoopNumberTime73 = {}; local DJBoothCustomLoopNumberTime74 = {}; local DJBoothCustomLoopNumberTime75 = {}; local DJBoothCustomLoopNumberTime76 = {}; local DJBoothCustomLoopNumberTime77 = {}; local DJBoothCustomLoopNumberTime78 = {}; local DJBoothCustomLoopNumberTime79 = {}; local DJBoothCustomLoopNumberTime80 = {};
--local DJBoothCustomLoopNumberTime81 = {}; local DJBoothCustomLoopNumberTime82 = {}; local DJBoothCustomLoopNumberTime83 = {}; local DJBoothCustomLoopNumberTime84 = {}; local DJBoothCustomLoopNumberTime85 = {}; local DJBoothCustomLoopNumberTime86 = {}; local DJBoothCustomLoopNumberTime87 = {}; local DJBoothCustomLoopNumberTime88 = {}; local DJBoothCustomLoopNumberTime89 = {}; local DJBoothCustomLoopNumberTime90 = {};
--local DJBoothCustomLoopNumberTime91 = {}; local DJBoothCustomLoopNumberTime92 = {}; local DJBoothCustomLoopNumberTime93 = {}; local DJBoothCustomLoopNumberTime94 = {}; local DJBoothCustomLoopNumberTime95 = {}; local DJBoothCustomLoopNumberTime96 = {}; local DJBoothCustomLoopNumberTime97 = {}; local DJBoothCustomLoopNumberTime98 = {}; local DJBoothCustomLoopNumberTime99 = {}; local DJBoothCustomLoopNumberTime100 = {};
local ButtonSmallCustomLoopImage

local KeyNumberTexture = getTexture("media/textures/DJBooth_OverlayNumber0.png")
local KeyNumberTextureOn = getTexture("media/textures/DJBooth_OverlayNumber1.png")
local KeyNumberImage

local SwitchTexture = getTexture("media/textures/DJBooth_SwitchAOff.png")
local SwitchTextureOn = getTexture("media/textures/DJBooth_SwitchAOn.png")
local SwitchAImage
local SwitchBImage
local SwitchCImage
local SwitchDImage
local SwitchBTexture = getTexture("media/textures/DJBooth_SwitchBOff.png")
local SwitchBTextureOn = getTexture("media/textures/DJBooth_SwitchBOn.png")
local SwitchBAImage

local BigButtonTexture = getTexture("media/textures/DJBooth_OverlayButtonBig.png")
local BigButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonBigPressed1.png")
local VynilTextureA = getTexture("media/textures/DJBooth_VynilA1.png")
local VynilTextureB = getTexture("media/textures/DJBooth_VynilB1.png")
local VynilAImage
local VynilBImage
local ButtonBigAImage
local ButtonBigBImage
local ButtonBigCImage
local ButtonBigDImage
local ButtonBigEImage
local ButtonBigFImage
local ButtonBigGImage
local ButtonBigHImage
local ButtonBig1Image
local ButtonBig2Image
local ButtonBig3Image
local ButtonBig4Image
local ButtonBig5Image
local ButtonBig6Image
local ButtonBig7Image
local ButtonBig8Image

local SmallSwitchIndicatorTexture = getTexture("media/textures/DJBooth_OverlaySwitchIndicatorSmallOff.png")
local SmallSwitchIndicatorTextureOn = getTexture("media/textures/DJBooth_OverlaySwitchIndicatorSmallOn.png")
local SmallSwitchIndicatorTextureRED = getTexture("media/textures/DJBooth_OverlaySwitchIndicatorSmallRED.png")
local SmallSwitchIndicatorAImage
local SmallSwitchIndicatorBImage
local SmallSwitchIndicatorCImage
local SmallSwitchIndicatorDImage
local SmallSwitchIndicatorEImage
local SmallSwitchIndicatorFImage
local SmallSwitchIndicatorGImage

local SmallButtonTexture = getTexture("media/textures/DJBooth_OverlayButtonSmall.png")
local SmallButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonSmallPressed1.png")
local ButtonSmallAImage
local ButtonSmallBImage
local ButtonSmallCImage
local ButtonSmallDImage
local ButtonSmallEImage
local ButtonSmallFImage
local ButtonSmallGImage
local ButtonSmallHImage
local ButtonSmallIImage
local ButtonSmallJImage
local ButtonSmallKImage
local ButtonSmallLImage
local ButtonSmallMImage
local ButtonSmallNImage
local ButtonSmallOImage
local ButtonSmallPImage
--local BigButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonBigPressedA.png") ------ initialise them for all buttons but make them invisible then make visible as needed, set all invisible in destroy
--local BigButtonPressedB
--local BigButtonPressedC
--local BigButtonWasPressedA = false ---- first to happen if A B C are false, set all false in destroy
--local BigButtonWasPressedB = false ----- if A is true and B C false
--local BigButtonWasPressedC = false ----- if A and B is true and C false, then for the next if A B C is true then pick A and A is false (this means make invisible for last button that was A and visible for new one), then if A is false and B C is true pick B and A B is false, then if A B is false and C is true then pick C and A B C is false


function DJSoundboardOverlay.onRecordedLoop(RecordedNumber)
    local specificPlayer = getSpecificPlayer(0)

    if RecordedNumber == 1 then
        if specificPlayer:getModData().DJNotFailstate == true then
            DJKeypress(44)
            specificPlayer:getModData().DJBoothBigButton1Pressed = true
            specificPlayer:getModData().DJBoothBigButton1PressedCount = 0
            DJSoundboardOverlay:updateStatus()
        end
    elseif RecordedNumber == 2 then
        if specificPlayer:getModData().DJNotFailstate == true then
            DJKeypress(45)
            specificPlayer:getModData().DJBoothBigButton2Pressed = true
            specificPlayer:getModData().DJBoothBigButton2PressedCount = 0
            DJSoundboardOverlay:updateStatus()
        end
    elseif RecordedNumber == 3 then
        if specificPlayer:getModData().DJNotFailstate == true then
            DJKeypress(46)
            specificPlayer:getModData().DJBoothBigButton3Pressed = true
            specificPlayer:getModData().DJBoothBigButton3PressedCount = 0
            DJSoundboardOverlay:updateStatus()
        end
    elseif RecordedNumber == 4 then
        if specificPlayer:getModData().DJNotFailstate == true then
            DJKeypress(47)
            specificPlayer:getModData().DJBoothBigButton4Pressed = true
            specificPlayer:getModData().DJBoothBigButton4PressedCount = 0
            DJSoundboardOverlay:updateStatus()
        end
    elseif RecordedNumber == 5 then
        if specificPlayer:getModData().DJNotFailstate == true then
            DJKeypress(48)
            specificPlayer:getModData().DJBoothBigButton5Pressed = true
            specificPlayer:getModData().DJBoothBigButton5PressedCount = 0
            DJSoundboardOverlay:updateStatus()
        end
    elseif RecordedNumber == 6 then
        if specificPlayer:getModData().DJNotFailstate == true then
            DJKeypress(49)
            specificPlayer:getModData().DJBoothBigButton6Pressed = true
            specificPlayer:getModData().DJBoothBigButton6PressedCount = 0
            DJSoundboardOverlay:updateStatus()
        end
    elseif RecordedNumber == 7 then
        if specificPlayer:getModData().DJNotFailstate == true then
            DJKeypress(50)
            specificPlayer:getModData().DJBoothBigButton7Pressed = true
            specificPlayer:getModData().DJBoothBigButton7PressedCount = 0
            DJSoundboardOverlay:updateStatus()
        end
    elseif RecordedNumber == 8 then
        if specificPlayer:getModData().DJNotFailstate == true then
            DJKeypress(51)
            specificPlayer:getModData().DJBoothBigButton8Pressed = true
            specificPlayer:getModData().DJBoothBigButton8PressedCount = 0
            DJSoundboardOverlay:updateStatus()
        end
    end

end

function DJBoothEventListener()
    local specificPlayer = getSpecificPlayer(0)
    
    if specificPlayer:getModData().DJBoothOverlayPanel == true then

            
        if specificPlayer:getModData().DJNotFailstate == true then
            if DJFailstateTexture == true then
            
                if specificPlayer:getModData().DJBoothSwitchAPressed == true then
                SmallSwitchIndicatorAImage.texture = SmallSwitchIndicatorTextureOn
                else
                SmallSwitchIndicatorAImage.texture = SmallSwitchIndicatorTexture
                end
                if specificPlayer:getModData().DJBoothSwitchBPressed == true then
                SmallSwitchIndicatorBImage.texture = SmallSwitchIndicatorTextureOn
                else
                SmallSwitchIndicatorBImage.texture = SmallSwitchIndicatorTexture
                end
                if specificPlayer:getModData().DJBoothSwitchCPressed == true then
                SmallSwitchIndicatorCImage.texture = SmallSwitchIndicatorTextureOn
                else
                SmallSwitchIndicatorCImage.texture = SmallSwitchIndicatorTexture
                end
                if specificPlayer:getModData().DJBoothSwitchDPressed == true then
                SmallSwitchIndicatorDImage.texture = SmallSwitchIndicatorTextureOn
                else
                SmallSwitchIndicatorDImage.texture = SmallSwitchIndicatorTexture
                end
                SmallSwitchIndicatorEImage.texture = SmallSwitchIndicatorTexture
                SmallSwitchIndicatorFImage.texture = SmallSwitchIndicatorTexture
                SmallSwitchIndicatorGImage.texture = SmallSwitchIndicatorTexture
                --if specificPlayer:getModData().DJBoothSwitchBAPressed == true then
                --SwitchBAImage.texture = SwitchBTextureOn
                --end
            
                if specificPlayer:getModData().DJKEY == 1 then
                    KeyNumberImage.texture = getTexture("media/textures/DJBooth_OverlayNumber1.png")
                elseif specificPlayer:getModData().DJKEY == 2 then
                    KeyNumberImage.texture = getTexture("media/textures/DJBooth_OverlayNumber2.png")
                elseif specificPlayer:getModData().DJKEY == 3 then
                    KeyNumberImage.texture = getTexture("media/textures/DJBooth_OverlayNumber3.png")
                elseif specificPlayer:getModData().DJKEY == 4 then
                    KeyNumberImage.texture = getTexture("media/textures/DJBooth_OverlayNumber4.png")
                end
            
            DJFailstateTexture = false
            end
            DJBoothNumberCount = DJBoothNumberCount + 1
            
            if DJBoothNumberCount % DJBoothNumberTotal == 0 then
                DJBoothNumberCount = 0
                --NUMBER KEY
                
                if specificPlayer:getModData().DJKEY == 1 and KeyNumberImage.texture ~= getTexture("media/textures/DJBooth_OverlayNumber1.png") then
                    KeyNumberImage.texture = getTexture("media/textures/DJBooth_OverlayNumber1.png")
                elseif specificPlayer:getModData().DJKEY == 2 and KeyNumberImage.texture ~= getTexture("media/textures/DJBooth_OverlayNumber2.png") then
                    KeyNumberImage.texture = getTexture("media/textures/DJBooth_OverlayNumber2.png")
                elseif specificPlayer:getModData().DJKEY == 3 and KeyNumberImage.texture ~= getTexture("media/textures/DJBooth_OverlayNumber3.png") then
                    KeyNumberImage.texture = getTexture("media/textures/DJBooth_OverlayNumber3.png")
                elseif specificPlayer:getModData().DJKEY == 4 and KeyNumberImage.texture ~= getTexture("media/textures/DJBooth_OverlayNumber4.png") then
                    KeyNumberImage.texture = getTexture("media/textures/DJBooth_OverlayNumber4.png")
                end
                
                --BIG BUTTON A
                if specificPlayer:getModData().DJBoothBigButtonAPressedCount >= 7 and ButtonBigAImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonAPressedCount = 0
                    ButtonBigAImage.texture = BigButtonTexture
                elseif ButtonBigAImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonAPressedCount = specificPlayer:getModData().DJBoothBigButtonAPressedCount + 1
                end
                --BIG BUTTON B
                if specificPlayer:getModData().DJBoothBigButtonBPressedCount >= 7 and ButtonBigBImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonBPressedCount = 0
                    ButtonBigBImage.texture = BigButtonTexture
                elseif ButtonBigBImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonBPressedCount = specificPlayer:getModData().DJBoothBigButtonBPressedCount + 1
                end
                --BIG BUTTON C
                if specificPlayer:getModData().DJBoothBigButtonCPressedCount >= 6 and ButtonBigCImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonCPressedCount = 0
                    ButtonBigCImage.texture = BigButtonTexture
                elseif ButtonBigCImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonCPressedCount = specificPlayer:getModData().DJBoothBigButtonCPressedCount + 1
                end
                --BIG BUTTON D
                if specificPlayer:getModData().DJBoothBigButtonDPressedCount >= 15 and ButtonBigDImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonDPressedCount = 0
                    ButtonBigDImage.texture = BigButtonTexture
                elseif ButtonBigDImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonDPressedCount = specificPlayer:getModData().DJBoothBigButtonDPressedCount + 1
                end
                --BIG BUTTON E
                if specificPlayer:getModData().DJBoothBigButtonEPressedCount >= 10 and ButtonBigEImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonEPressedCount = 0
                    ButtonBigEImage.texture = BigButtonTexture
                elseif ButtonBigEImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonEPressedCount = specificPlayer:getModData().DJBoothBigButtonEPressedCount + 1
                end
                --BIG BUTTON F
                if specificPlayer:getModData().DJBoothBigButtonFPressedCount >= 6 and ButtonBigFImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonFPressedCount = 0
                    ButtonBigFImage.texture = BigButtonTexture
                elseif ButtonBigFImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonFPressedCount = specificPlayer:getModData().DJBoothBigButtonFPressedCount + 1
                end
                --BIG BUTTON G
                if specificPlayer:getModData().DJBoothBigButtonGPressedCount >= 10 and ButtonBigGImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonGPressedCount = 0
                    ButtonBigGImage.texture = BigButtonTexture
                elseif ButtonBigGImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonGPressedCount = specificPlayer:getModData().DJBoothBigButtonGPressedCount + 1
                end
                --BIG BUTTON H
                if specificPlayer:getModData().DJBoothBigButtonHPressedCount >= 8 and ButtonBigHImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonHPressedCount = 0
                    ButtonBigHImage.texture = BigButtonTexture
                elseif ButtonBigHImage.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButtonHPressedCount = specificPlayer:getModData().DJBoothBigButtonHPressedCount + 1
                end
                --BIG BUTTON 1
                if specificPlayer:getModData().DJBoothBigButton1PressedCount >= 1 and ButtonBig1Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton1PressedCount = 0
                    ButtonBig1Image.texture = BigButtonTexture
                elseif ButtonBig1Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton1PressedCount = specificPlayer:getModData().DJBoothBigButton1PressedCount + 1
                end
                --BIG BUTTON 2
                if specificPlayer:getModData().DJBoothBigButton2PressedCount >= 1 and ButtonBig2Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton2PressedCount = 0
                    ButtonBig2Image.texture = BigButtonTexture
                elseif ButtonBig2Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton2PressedCount = specificPlayer:getModData().DJBoothBigButton2PressedCount + 1
                end
                --BIG BUTTON 3
                if specificPlayer:getModData().DJBoothBigButton3PressedCount >= 1 and ButtonBig3Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton3PressedCount = 0
                    ButtonBig3Image.texture = BigButtonTexture
                elseif ButtonBig3Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton3PressedCount = specificPlayer:getModData().DJBoothBigButton3PressedCount + 1
                end
                --BIG BUTTON 4
                if specificPlayer:getModData().DJBoothBigButton4PressedCount >= 1 and ButtonBig4Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton4PressedCount = 0
                    ButtonBig4Image.texture = BigButtonTexture
                elseif ButtonBig4Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton4PressedCount = specificPlayer:getModData().DJBoothBigButton4PressedCount + 1
                end
                --BIG BUTTON 5
                if specificPlayer:getModData().DJBoothBigButton5PressedCount >= 1 and ButtonBig5Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton5PressedCount = 0
                    ButtonBig5Image.texture = BigButtonTexture
                elseif ButtonBig5Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton5PressedCount = specificPlayer:getModData().DJBoothBigButton5PressedCount + 1
                end
                --BIG BUTTON 6
                if specificPlayer:getModData().DJBoothBigButton6PressedCount >= 1 and ButtonBig6Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton6PressedCount = 0
                    ButtonBig6Image.texture = BigButtonTexture
                elseif ButtonBig6Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton6PressedCount = specificPlayer:getModData().DJBoothBigButton6PressedCount + 1
                end
                --BIG BUTTON 7
                if specificPlayer:getModData().DJBoothBigButton7PressedCount >= 1 and ButtonBig7Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton7PressedCount = 0
                    ButtonBig7Image.texture = BigButtonTexture
                elseif ButtonBig7Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton7PressedCount = specificPlayer:getModData().DJBoothBigButton7PressedCount + 1
                end
                --BIG BUTTON 8
                if specificPlayer:getModData().DJBoothBigButton8PressedCount >= 1 and ButtonBig8Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton8PressedCount = 0
                    ButtonBig8Image.texture = BigButtonTexture
                elseif ButtonBig8Image.texture ~= BigButtonTexture then
                    specificPlayer:getModData().DJBoothBigButton8PressedCount = specificPlayer:getModData().DJBoothBigButton8PressedCount + 1
                end

            end
        elseif DJFailstateTexture == false then
            ButtonBigAImage.texture = BigButtonTexture
            ButtonBigBImage.texture = BigButtonTexture
            ButtonBigCImage.texture = BigButtonTexture
            ButtonBigDImage.texture = BigButtonTexture
            ButtonBigEImage.texture = BigButtonTexture
            ButtonBigFImage.texture = BigButtonTexture
            ButtonBigGImage.texture = BigButtonTexture
            ButtonBigHImage.texture = BigButtonTexture
            
            SmallSwitchIndicatorAImage.texture = SmallSwitchIndicatorTextureRED
            SmallSwitchIndicatorBImage.texture = SmallSwitchIndicatorTextureRED
            SmallSwitchIndicatorCImage.texture = SmallSwitchIndicatorTextureRED
            SmallSwitchIndicatorDImage.texture = SmallSwitchIndicatorTextureRED
            SmallSwitchIndicatorEImage.texture = SmallSwitchIndicatorTextureRED
            SmallSwitchIndicatorFImage.texture = SmallSwitchIndicatorTextureRED
            SmallSwitchIndicatorGImage.texture = SmallSwitchIndicatorTextureRED            
            
            specificPlayer:getModData().DJBoothSmallButtonAPressed = false
            ButtonSmallAImage.texture = SmallButtonTexture
            
            if specificPlayer:getModData().DJBoothSwitchAPressed == true then
                specificPlayer:getModData().DJBoothSmallButtonBPressed = false
                specificPlayer:getModData().DJBoothSmallButtonCPressed = false
                specificPlayer:getModData().DJBoothSmallButtonDPressed = false
                ButtonSmallBImage.texture = SmallButtonTexture
                ButtonSmallCImage.texture = SmallButtonTexture
                ButtonSmallDImage.texture = SmallButtonTexture
            end
            if specificPlayer:getModData().DJBoothSwitchBPressed == true then
                specificPlayer:getModData().DJBoothSmallButtonEPressed = false
                specificPlayer:getModData().DJBoothSmallButtonFPressed = false
                specificPlayer:getModData().DJBoothSmallButtonGPressed = false
                specificPlayer:getModData().DJBoothSmallButtonHPressed = false
                ButtonSmallEImage.texture = SmallButtonTexture
                ButtonSmallFImage.texture = SmallButtonTexture
                ButtonSmallGImage.texture = SmallButtonTexture
                ButtonSmallHImage.texture = SmallButtonTexture
            end
            if specificPlayer:getModData().DJBoothSwitchCPressed == true then
                specificPlayer:getModData().DJBoothSmallButtonIPressed = false
                specificPlayer:getModData().DJBoothSmallButtonJPressed = false
                specificPlayer:getModData().DJBoothSmallButtonKPressed = false
                specificPlayer:getModData().DJBoothSmallButtonLPressed = false
                ButtonSmallIImage.texture = SmallButtonTexture
                ButtonSmallJImage.texture = SmallButtonTexture
                ButtonSmallKImage.texture = SmallButtonTexture
                ButtonSmallLImage.texture = SmallButtonTexture
            end
            if specificPlayer:getModData().DJBoothSwitchDPressed == true then
                specificPlayer:getModData().DJBoothSmallButtonMPressed = false
                specificPlayer:getModData().DJBoothSmallButtonNPressed = false
                specificPlayer:getModData().DJBoothSmallButtonOPressed = false
                specificPlayer:getModData().DJBoothSmallButtonPPressed = false
                ButtonSmallMImage.texture = SmallButtonTexture
                ButtonSmallNImage.texture = SmallButtonTexture
                ButtonSmallOImage.texture = SmallButtonTexture
                ButtonSmallPImage.texture = SmallButtonTexture
            end
            
            if specificPlayer:getModData().DJBoothSwitchBAPressed == true then
                SwitchBAImage.texture = SwitchBTexture
                specificPlayer:getModData().DJBoothSwitchBAPressed = false
            end
            
            if specificPlayer:getModData().DJKEY ~= 0 then
                KeyNumberImage.texture = KeyNumberTexture
            end
            
            DJFailstateTexture = true
        end---FAILSTATE

    else
    DJBoothNumberCount = 0
    LSKScheduler.remove("dj-overlay-main")
    end
end

function DJBoothEventListenerRecorder()
    local specificPlayer = getSpecificPlayer(0)
    
    if specificPlayer:getModData().DJBoothOverlayPanel == true then
        if specificPlayer:getModData().DJNotFailstate == true and specificPlayer:getModData().DJBoothCustomLoop == true then
                
                if specificPlayer:getModData().DJBoothCustomLoopActive == 1 then
                DJBoothCustomLoopNumberCount = DJBoothCustomLoopNumberCount + 1
                DJBoothThisNumberCount = DJBoothCustomLoopNumberCount
                elseif specificPlayer:getModData().DJBoothCustomLoopActive == 2 then
                DJBoothCustomLoopNumberCount2 = DJBoothCustomLoopNumberCount2 + 1
                DJBoothThisNumberCount = DJBoothCustomLoopNumberCount2
                elseif specificPlayer:getModData().DJBoothCustomLoopActive == 3 then
                DJBoothCustomLoopNumberCount3 = DJBoothCustomLoopNumberCount3 + 1
                DJBoothThisNumberCount = DJBoothCustomLoopNumberCount3
                end
                
                if specificPlayer:getModData().DJBoothCustomLoopKeyPressed ~= 0 then
                
                    if DJBoothCustomLoopNumberTime1.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime1.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime1.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime2.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime2.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime2.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime3.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime3.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime3.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime4.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime4.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime4.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime5.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime5.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime5.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime6.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime6.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime6.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime7.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime7.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime7.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime8.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime8.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime8.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime9.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime9.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime9.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime10.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime10.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime10.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    
                    elseif DJBoothCustomLoopNumberTime11.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime11.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime11.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime12.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime12.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime12.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime13.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime13.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime13.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime14.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime14.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime14.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime15.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime15.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime15.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime16.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime16.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime16.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime17.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime17.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime17.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime18.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime18.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime18.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime19.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime19.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime19.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime20.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime20.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime20.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0

                    elseif DJBoothCustomLoopNumberTime21.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime21.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime21.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime22.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime22.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime22.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime23.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime23.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime23.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime24.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime24.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime24.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime25.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime25.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime25.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime26.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime26.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime26.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime27.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime27.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime27.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime28.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime28.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime28.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime29.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime29.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime29.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime30.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime30.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime30.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    
                    elseif DJBoothCustomLoopNumberTime31.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime31.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime31.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime32.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime32.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime32.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime33.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime33.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime33.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime34.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime34.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime34.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime35.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime35.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime35.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime36.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime36.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime36.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime37.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime37.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime37.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime38.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime38.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime38.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime39.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime39.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime39.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime40.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime40.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime40.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    
                    elseif DJBoothCustomLoopNumberTime41.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime41.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime41.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    elseif DJBoothCustomLoopNumberTime42.KeyTime == 0 then
                    DJBoothCustomLoopNumberTime42.KeyTime = DJBoothThisNumberCount
                    DJBoothCustomLoopNumberTime42.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                --    elseif DJBoothCustomLoopNumberTime43.KeyTime == 0 then
                --    DJBoothCustomLoopNumberTime43.KeyTime = DJBoothThisNumberCount
                --    DJBoothCustomLoopNumberTime43.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    --specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                --    elseif DJBoothCustomLoopNumberTime44.KeyTime == 0 then
                --    DJBoothCustomLoopNumberTime44.KeyTime = DJBoothThisNumberCount
                --    DJBoothCustomLoopNumberTime44.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                --    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    --elseif DJBoothCustomLoopNumberTime45.KeyTime == 0 then
                    --DJBoothCustomLoopNumberTime45.KeyTime = DJBoothThisNumberCount
                --    DJBoothCustomLoopNumberTime45.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                --    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    --elseif DJBoothCustomLoopNumberTime46.KeyTime == 0 then
                    --DJBoothCustomLoopNumberTime46.KeyTime = DJBoothThisNumberCount
                    --DJBoothCustomLoopNumberTime46.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    --specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    --elseif DJBoothCustomLoopNumberTime47.KeyTime == 0 then
                    --DJBoothCustomLoopNumberTime47.KeyTime = DJBoothThisNumberCount
                    --DJBoothCustomLoopNumberTime47.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    --specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    --elseif DJBoothCustomLoopNumberTime48.KeyTime == 0 then
                --    DJBoothCustomLoopNumberTime48.KeyTime = DJBoothThisNumberCount
                    --DJBoothCustomLoopNumberTime48.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    --specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    --elseif DJBoothCustomLoopNumberTime49.KeyTime == 0 then
                    --DJBoothCustomLoopNumberTime49.KeyTime = DJBoothThisNumberCount
                    --DJBoothCustomLoopNumberTime49.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    --specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    --elseif DJBoothCustomLoopNumberTime50.KeyTime == 0 then
                    --DJBoothCustomLoopNumberTime50.KeyTime = DJBoothThisNumberCount
                --    DJBoothCustomLoopNumberTime50.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed
                    --specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                    --elseif DJBoothCustomLoopNumberTime11.KeyTime == 0 then; DJBoothCustomLoopNumberTime11.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime11.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime12.KeyTime == 0 then; DJBoothCustomLoopNumberTime12.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime12.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime13.KeyTime == 0 then; DJBoothCustomLoopNumberTime13.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime13.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime14.KeyTime == 0 then; DJBoothCustomLoopNumberTime14.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime14.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime15.KeyTime == 0 then; DJBoothCustomLoopNumberTime15.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime15.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime16.KeyTime == 0 then; DJBoothCustomLoopNumberTime16.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime16.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime17.KeyTime == 0 then; DJBoothCustomLoopNumberTime17.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime17.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime18.KeyTime == 0 then; DJBoothCustomLoopNumberTime18.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime18.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime19.KeyTime == 0 then; DJBoothCustomLoopNumberTime19.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime19.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime20.KeyTime == 0 then; DJBoothCustomLoopNumberTime20.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime20.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;
                    --elseif DJBoothCustomLoopNumberTime21.KeyTime == 0 then; DJBoothCustomLoopNumberTime21.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime21.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime22.KeyTime == 0 then; DJBoothCustomLoopNumberTime22.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime22.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime23.KeyTime == 0 then; DJBoothCustomLoopNumberTime23.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime23.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime24.KeyTime == 0 then; DJBoothCustomLoopNumberTime24.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime24.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime25.KeyTime == 0 then; DJBoothCustomLoopNumberTime25.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime25.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime26.KeyTime == 0 then; DJBoothCustomLoopNumberTime26.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime26.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime27.KeyTime == 0 then; DJBoothCustomLoopNumberTime27.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime27.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime28.KeyTime == 0 then; DJBoothCustomLoopNumberTime28.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime28.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime29.KeyTime == 0 then; DJBoothCustomLoopNumberTime29.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime29.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime30.KeyTime == 0 then; DJBoothCustomLoopNumberTime30.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime30.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;
                    --elseif DJBoothCustomLoopNumberTime31.KeyTime == 0 then; DJBoothCustomLoopNumberTime31.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime31.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime32.KeyTime == 0 then; DJBoothCustomLoopNumberTime32.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime32.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime33.KeyTime == 0 then; DJBoothCustomLoopNumberTime33.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime33.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime34.KeyTime == 0 then; DJBoothCustomLoopNumberTime34.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime34.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime35.KeyTime == 0 then; DJBoothCustomLoopNumberTime35.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime35.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime36.KeyTime == 0 then; DJBoothCustomLoopNumberTime36.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime36.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime37.KeyTime == 0 then; DJBoothCustomLoopNumberTime37.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime37.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime38.KeyTime == 0 then; DJBoothCustomLoopNumberTime38.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime38.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime39.KeyTime == 0 then; DJBoothCustomLoopNumberTime39.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime39.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime40.KeyTime == 0 then; DJBoothCustomLoopNumberTime40.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime40.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;
                    --elseif DJBoothCustomLoopNumberTime41.KeyTime == 0 then; DJBoothCustomLoopNumberTime41.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime41.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime42.KeyTime == 0 then; DJBoothCustomLoopNumberTime42.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime42.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime43.KeyTime == 0 then; DJBoothCustomLoopNumberTime43.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime43.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime44.KeyTime == 0 then; DJBoothCustomLoopNumberTime44.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime44.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime45.KeyTime == 0 then; DJBoothCustomLoopNumberTime45.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime45.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime46.KeyTime == 0 then; DJBoothCustomLoopNumberTime46.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime46.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime47.KeyTime == 0 then; DJBoothCustomLoopNumberTime47.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime47.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime48.KeyTime == 0 then; DJBoothCustomLoopNumberTime48.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime48.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime49.KeyTime == 0 then; DJBoothCustomLoopNumberTime49.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime49.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime50.KeyTime == 0 then; DJBoothCustomLoopNumberTime50.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime50.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;
                    --elseif DJBoothCustomLoopNumberTime51.KeyTime == 0 then; DJBoothCustomLoopNumberTime51.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime51.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime52.KeyTime == 0 then; DJBoothCustomLoopNumberTime52.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime52.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;  elseif DJBoothCustomLoopNumberTime53.KeyTime == 0 then; DJBoothCustomLoopNumberTime53.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime53.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime54.KeyTime == 0 then; DJBoothCustomLoopNumberTime54.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime54.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime55.KeyTime == 0 then; DJBoothCustomLoopNumberTime55.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime55.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime56.KeyTime == 0 then; DJBoothCustomLoopNumberTime56.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime56.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime57.KeyTime == 0 then; DJBoothCustomLoopNumberTime57.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime57.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime58.KeyTime == 0 then; DJBoothCustomLoopNumberTime58.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime58.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime59.KeyTime == 0 then; DJBoothCustomLoopNumberTime59.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime59.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime60.KeyTime == 0 then; DJBoothCustomLoopNumberTime60.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime60.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;
                    --elseif DJBoothCustomLoopNumberTime61.KeyTime == 0 then; DJBoothCustomLoopNumberTime61.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime61.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime62.KeyTime == 0 then; DJBoothCustomLoopNumberTime62.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime62.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;  elseif DJBoothCustomLoopNumberTime63.KeyTime == 0 then; DJBoothCustomLoopNumberTime63.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime63.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime64.KeyTime == 0 then; DJBoothCustomLoopNumberTime64.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime64.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime65.KeyTime == 0 then; DJBoothCustomLoopNumberTime65.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime65.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime66.KeyTime == 0 then; DJBoothCustomLoopNumberTime66.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime66.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime67.KeyTime == 0 then; DJBoothCustomLoopNumberTime67.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime67.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime68.KeyTime == 0 then; DJBoothCustomLoopNumberTime68.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime68.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime69.KeyTime == 0 then; DJBoothCustomLoopNumberTime69.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime69.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime70.KeyTime == 0 then; DJBoothCustomLoopNumberTime70.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime70.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;
                    --elseif DJBoothCustomLoopNumberTime71.KeyTime == 0 then; DJBoothCustomLoopNumberTime71.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime71.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime72.KeyTime == 0 then; DJBoothCustomLoopNumberTime72.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime72.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;  elseif DJBoothCustomLoopNumberTime73.KeyTime == 0 then; DJBoothCustomLoopNumberTime73.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime73.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime74.KeyTime == 0 then; DJBoothCustomLoopNumberTime74.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime74.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime75.KeyTime == 0 then; DJBoothCustomLoopNumberTime75.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime75.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime76.KeyTime == 0 then; DJBoothCustomLoopNumberTime76.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime76.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime77.KeyTime == 0 then; DJBoothCustomLoopNumberTime77.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime77.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime78.KeyTime == 0 then; DJBoothCustomLoopNumberTime78.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime78.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime79.KeyTime == 0 then; DJBoothCustomLoopNumberTime79.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime79.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime80.KeyTime == 0 then; DJBoothCustomLoopNumberTime80.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime80.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;
                    --elseif DJBoothCustomLoopNumberTime81.KeyTime == 0 then; DJBoothCustomLoopNumberTime81.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime81.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime82.KeyTime == 0 then; DJBoothCustomLoopNumberTime82.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime82.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;  elseif DJBoothCustomLoopNumberTime83.KeyTime == 0 then; DJBoothCustomLoopNumberTime83.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime83.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime84.KeyTime == 0 then; DJBoothCustomLoopNumberTime84.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime84.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime85.KeyTime == 0 then; DJBoothCustomLoopNumberTime85.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime85.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime86.KeyTime == 0 then; DJBoothCustomLoopNumberTime86.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime86.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime87.KeyTime == 0 then; DJBoothCustomLoopNumberTime87.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime87.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime88.KeyTime == 0 then; DJBoothCustomLoopNumberTime88.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime88.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime89.KeyTime == 0 then; DJBoothCustomLoopNumberTime89.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime89.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime90.KeyTime == 0 then; DJBoothCustomLoopNumberTime90.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime90.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;
                    --elseif DJBoothCustomLoopNumberTime91.KeyTime == 0 then; DJBoothCustomLoopNumberTime91.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime91.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime92.KeyTime == 0 then; DJBoothCustomLoopNumberTime92.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime92.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;  elseif DJBoothCustomLoopNumberTime93.KeyTime == 0 then; DJBoothCustomLoopNumberTime93.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime93.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime94.KeyTime == 0 then; DJBoothCustomLoopNumberTime94.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime94.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime95.KeyTime == 0 then; DJBoothCustomLoopNumberTime95.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime95.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime96.KeyTime == 0 then; DJBoothCustomLoopNumberTime96.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime96.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime97.KeyTime == 0 then; DJBoothCustomLoopNumberTime97.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime97.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime98.KeyTime == 0 then; DJBoothCustomLoopNumberTime98.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime98.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime99.KeyTime == 0 then; DJBoothCustomLoopNumberTime99.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime99.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed; elseif DJBoothCustomLoopNumberTime100.KeyTime == 0 then; DJBoothCustomLoopNumberTime100.KeyTime = DJBoothCustomLoopNumberCount; DJBoothCustomLoopNumberTime100.KeySound = specificPlayer:getModData().DJBoothCustomLoopKeyPressed;
        
                    end
                    specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 0
                end
                
                if DJBoothCustomLoopNumberCount > DJBoothCustomLoopNumberLimit or DJBoothCustomLoopNumberCount2 > DJBoothCustomLoopNumberLimit2 or DJBoothCustomLoopNumberCount3 > DJBoothCustomLoopNumberLimit3 then
                
                    if specificPlayer:getModData().DJBoothSwitchBAPressed == true then
                        SwitchBAImage.texture = SwitchBTexture
                        specificPlayer:getModData().DJBoothSwitchBAPressed = false
                    end
                    
                    if specificPlayer:getModData().DJBoothCustomLoopActive == 1 then
                        DJBoothCustomLoopNumberCountTotal = tonumber(DJBoothCustomLoopNumberCount)
                        DJBoothCustomLoopNumberCount = 0
                    elseif specificPlayer:getModData().DJBoothCustomLoopActive == 2 then
                        DJBoothCustomLoopNumberCountTotal2 = tonumber(DJBoothCustomLoopNumberCount2)
                        DJBoothCustomLoopNumberCount2 = 1000
                    elseif specificPlayer:getModData().DJBoothCustomLoopActive == 3 then
                        DJBoothCustomLoopNumberCountTotal3 = tonumber(DJBoothCustomLoopNumberCount3)
                        DJBoothCustomLoopNumberCount3 = 2000
                    end
                
                specificPlayer:getModData().DJBoothCustomLoop = false
                
                elseif specificPlayer:getModData().DJBoothSwitchBAPressed == false then
                
                    if specificPlayer:getModData().DJBoothCustomLoopActive == 1 then
                        DJBoothCustomLoopNumberCountTotal = tonumber(DJBoothCustomLoopNumberCount)
                        DJBoothCustomLoopNumberCount = 0
                    elseif specificPlayer:getModData().DJBoothCustomLoopActive == 2 then
                        DJBoothCustomLoopNumberCountTotal2 = tonumber(DJBoothCustomLoopNumberCount2)
                        DJBoothCustomLoopNumberCount2 = 1000
                    elseif specificPlayer:getModData().DJBoothCustomLoopActive == 3 then
                        DJBoothCustomLoopNumberCountTotal3 = tonumber(DJBoothCustomLoopNumberCount3)
                        DJBoothCustomLoopNumberCount3 = 2000
                    end

                specificPlayer:getModData().DJBoothCustomLoop = false
                
                end

            
        end
    else
    LSKScheduler.remove("dj-overlay-recorder")
    end
end

function DJBoothEventListenerPlayer()
    local specificPlayer = getSpecificPlayer(0)
    
    if specificPlayer:getModData().DJBoothOverlayPanel == true then
        if specificPlayer:getModData().DJNotFailstate == true then
    
            if specificPlayer:getModData().DJBoothCustomLoopPlaying == true and ((specificPlayer:getModData().DJBoothCustomLoopActive == 1 and specificPlayer:getModData().DJBoothCustomLoop == false) or (specificPlayer:getModData().DJBoothCustomLoopActive == 2) or (specificPlayer:getModData().DJBoothCustomLoopActive == 3)) then
            
                if specificPlayer:getModData().DJBoothCustomLoopActive == 1 then
                    if DJBoothCustomLoopNumberCount > DJBoothCustomLoopNumberLimit or DJBoothCustomLoopNumberCount > DJBoothCustomLoopNumberCountTotal then
                    DJBoothCustomLoopNumberCount = 0
                    end
                DJBoothCustomLoopNumberCount = DJBoothCustomLoopNumberCount + 1
                elseif specificPlayer:getModData().DJBoothCustomLoopActive == 2 and specificPlayer:getModData().DJBoothCustomLoop == true then
                    if DJBoothCustomLoopNumberCount > DJBoothCustomLoopNumberLimit or DJBoothCustomLoopNumberCount > DJBoothCustomLoopNumberCountTotal then
                    DJBoothCustomLoopNumberCount = 0
                    end
                DJBoothCustomLoopNumberCount = DJBoothCustomLoopNumberCount + 1
                elseif specificPlayer:getModData().DJBoothCustomLoopActive == 2 then
                    if DJBoothCustomLoopNumberCount > DJBoothCustomLoopNumberLimit or DJBoothCustomLoopNumberCount > DJBoothCustomLoopNumberCountTotal then
                    DJBoothCustomLoopNumberCount = 0
                    end
                    if DJBoothCustomLoopNumberCount2 > DJBoothCustomLoopNumberLimit2 or DJBoothCustomLoopNumberCount2 > DJBoothCustomLoopNumberCountTotal2 then
                        DJBoothCustomLoopNumberCount2 = 1000
                    end
                DJBoothCustomLoopNumberCount = DJBoothCustomLoopNumberCount + 1
                DJBoothCustomLoopNumberCount2 = DJBoothCustomLoopNumberCount2 + 1
                elseif specificPlayer:getModData().DJBoothCustomLoopActive == 3 and specificPlayer:getModData().DJBoothCustomLoop == true then
                    if DJBoothCustomLoopNumberCount > DJBoothCustomLoopNumberLimit or DJBoothCustomLoopNumberCount > DJBoothCustomLoopNumberCountTotal then
                    DJBoothCustomLoopNumberCount = 0
                    end
                    if DJBoothCustomLoopNumberCount2 > DJBoothCustomLoopNumberLimit2 or DJBoothCustomLoopNumberCount2 > DJBoothCustomLoopNumberCountTotal2 then
                        DJBoothCustomLoopNumberCount2 = 1000
                    end
                DJBoothCustomLoopNumberCount = DJBoothCustomLoopNumberCount + 1
                DJBoothCustomLoopNumberCount2 = DJBoothCustomLoopNumberCount2 + 1
                elseif specificPlayer:getModData().DJBoothCustomLoopActive == 3 then
                    if DJBoothCustomLoopNumberCount > DJBoothCustomLoopNumberLimit or DJBoothCustomLoopNumberCount > DJBoothCustomLoopNumberCountTotal then
                    DJBoothCustomLoopNumberCount = 0
                    end
                    if DJBoothCustomLoopNumberCount2 > DJBoothCustomLoopNumberLimit2 or DJBoothCustomLoopNumberCount2 > DJBoothCustomLoopNumberCountTotal2 then
                        DJBoothCustomLoopNumberCount2 = 1000
                    end
                    if DJBoothCustomLoopNumberCount3 > DJBoothCustomLoopNumberLimit3 or DJBoothCustomLoopNumberCount3 > DJBoothCustomLoopNumberCountTotal3 then
                        DJBoothCustomLoopNumberCount3 = 2000
                    end
                DJBoothCustomLoopNumberCount = DJBoothCustomLoopNumberCount + 1
                DJBoothCustomLoopNumberCount2 = DJBoothCustomLoopNumberCount2 + 1
                DJBoothCustomLoopNumberCount3 = DJBoothCustomLoopNumberCount3 + 1
                end
            
                --if DJBoothCustomLoopNumberCount ~= 0 then

                    if DJBoothCustomLoopNumberTime1.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime1.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime1.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime1.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime1.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime2.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime2.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime2.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime2.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime2.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime3.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime3.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime3.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime3.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime3.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime4.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime4.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime4.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime4.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime4.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime5.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime5.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime5.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime5.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime5.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime6.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime6.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime6.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime6.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime6.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime7.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime7.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime7.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime7.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime7.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime8.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime8.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime8.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime8.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime8.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime9.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime9.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime9.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime9.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime9.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime10.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime10.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime10.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime10.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime10.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)

                    elseif DJBoothCustomLoopNumberTime11.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime11.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime11.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime11.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime11.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime12.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime12.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime12.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime12.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime12.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime13.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime13.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime13.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime13.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime13.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime14.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime14.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime14.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime14.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime14.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime15.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime15.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime15.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime15.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime15.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime16.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime16.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime16.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime16.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime16.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime17.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime17.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime17.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime17.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime17.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime18.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime18.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime18.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime18.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime18.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime19.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime19.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime19.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime19.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime19.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime20.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime20.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime20.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime20.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime20.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)

                    elseif DJBoothCustomLoopNumberTime21.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime21.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime21.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime21.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime21.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime22.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime22.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime22.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime22.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime22.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime23.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime23.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime23.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime23.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime23.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime24.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime24.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime24.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime24.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime24.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime25.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime25.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime25.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime25.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime25.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime26.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime26.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime26.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime26.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime26.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime27.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime27.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime27.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime27.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime27.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime28.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime28.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime28.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime28.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime28.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime29.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime29.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime29.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime29.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime29.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime30.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime30.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime30.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime30.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime30.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    
                    elseif DJBoothCustomLoopNumberTime31.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime31.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime31.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime31.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime31.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime32.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime32.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime32.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime32.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime32.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime33.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime33.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime33.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime33.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime33.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime34.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime34.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime34.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime34.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime34.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime35.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime35.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime35.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime35.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime35.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime36.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime36.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime36.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime36.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime36.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime37.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime37.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime37.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime37.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime37.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime38.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime38.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime38.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime38.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime38.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime39.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime39.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime39.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime39.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime39.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime40.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime40.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime40.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime40.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime40.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    
                    elseif DJBoothCustomLoopNumberTime41.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime41.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime41.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime41.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime41.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    elseif DJBoothCustomLoopNumberTime42.KeyTime ~= 0 and (DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime42.KeyTime or DJBoothCustomLoopNumberCount2 == DJBoothCustomLoopNumberTime42.KeyTime or DJBoothCustomLoopNumberCount3 == DJBoothCustomLoopNumberTime42.KeyTime) then
                    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime42.KeySound
                    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    --elseif DJBoothCustomLoopNumberTime43.KeyTime ~= 0 and DJBoothCustomLoopNumberCountAll == DJBoothCustomLoopNumberTime43.KeyTime then
                    --onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime43.KeySound
                    --DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    --elseif DJBoothCustomLoopNumberTime44.KeyTime ~= 0 and DJBoothCustomLoopNumberCountAll == DJBoothCustomLoopNumberTime44.KeyTime then
                    --onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime44.KeySound
                --    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                --    elseif DJBoothCustomLoopNumberTime45.KeyTime ~= 0 and DJBoothCustomLoopNumberCountAll == DJBoothCustomLoopNumberTime45.KeyTime then
                --    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime45.KeySound
                --    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    --elseif DJBoothCustomLoopNumberTime46.KeyTime ~= 0 and DJBoothCustomLoopNumberCountAll == DJBoothCustomLoopNumberTime46.KeyTime then
                    --onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime46.KeySound
                    --DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                --    elseif DJBoothCustomLoopNumberTime47.KeyTime ~= 0 and DJBoothCustomLoopNumberCountAll == DJBoothCustomLoopNumberTime47.KeyTime then
                    --onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime47.KeySound
                --    DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    --elseif DJBoothCustomLoopNumberTime48.KeyTime ~= 0 and DJBoothCustomLoopNumberCountAll == DJBoothCustomLoopNumberTime48.KeyTime then
                    --onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime48.KeySound
                    --DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    --elseif DJBoothCustomLoopNumberTime49.KeyTime ~= 0 and DJBoothCustomLoopNumberCountAll == DJBoothCustomLoopNumberTime49.KeyTime then
                    --onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime49.KeySound
                    --DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)
                    --elseif DJBoothCustomLoopNumberTime50.KeyTime ~= 0 and DJBoothCustomLoopNumberCountAll == DJBoothCustomLoopNumberTime50.KeyTime then
                --    onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime50.KeySound
                    --DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded)

                    --elseif DJBoothCustomLoopNumberTime11.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime11.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime11.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime12.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime12.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime12.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime13.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime13.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime13.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime14.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime14.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime14.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime15.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime15.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime15.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime16.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime16.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime16.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime17.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime17.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime17.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime18.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime18.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime18.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime19.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime19.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime19.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime20.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime20.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime20.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded);
                    --elseif DJBoothCustomLoopNumberTime21.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime21.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime21.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime22.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime22.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime22.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime23.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime23.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime23.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime24.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime24.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime24.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime25.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime25.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime25.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime26.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime26.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime26.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime27.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime27.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime27.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime28.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime28.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime28.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime29.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime29.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime29.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime30.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime30.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime30.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded);
                    --elseif DJBoothCustomLoopNumberTime31.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime31.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime31.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime32.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime32.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime32.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime33.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime33.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime33.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime34.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime34.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime34.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime35.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime35.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime35.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime36.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime36.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime36.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime37.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime37.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime37.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime38.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime38.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime38.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime39.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime39.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime39.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime40.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime40.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime40.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded);
                    --elseif DJBoothCustomLoopNumberTime41.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime41.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime41.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime42.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime42.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime42.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime43.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime43.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime43.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime44.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime44.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime44.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime45.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime45.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime45.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime46.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime46.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime46.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime47.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime47.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime47.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime48.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime48.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime48.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime49.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime49.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime49.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime50.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime50.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime50.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded);
                    --elseif DJBoothCustomLoopNumberTime51.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime51.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime51.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime52.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime52.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime52.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime53.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime53.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime53.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime54.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime54.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime54.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime55.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime55.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime55.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime56.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime56.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime56.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime57.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime57.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime57.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime58.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime58.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime58.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime59.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime59.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime59.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime60.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime60.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime60.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded);
                    --elseif DJBoothCustomLoopNumberTime61.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime61.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime61.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime62.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime62.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime62.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime63.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime63.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime63.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime64.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime64.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime64.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime65.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime65.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime65.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime66.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime66.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime66.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime67.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime67.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime67.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime68.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime68.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime68.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime69.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime69.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime69.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime70.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime70.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime70.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded);
                    --elseif DJBoothCustomLoopNumberTime71.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime71.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime71.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime72.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime72.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime72.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime73.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime73.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime73.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime74.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime74.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime74.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime75.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime75.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime75.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime76.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime76.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime76.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime77.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime77.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime77.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime78.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime78.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime78.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime79.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime79.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime79.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime80.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime80.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime80.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded);
                    --elseif DJBoothCustomLoopNumberTime81.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime81.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime81.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime82.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime82.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime82.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime83.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime83.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime83.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime84.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime84.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime84.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime85.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime85.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime85.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime86.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime86.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime86.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime87.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime87.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime87.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime88.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime88.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime88.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime89.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime89.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime89.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime90.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime90.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime90.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded);
                    --elseif DJBoothCustomLoopNumberTime91.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime91.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime91.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime92.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime92.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime92.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime93.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime93.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime93.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime94.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime94.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime94.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime95.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime95.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime95.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime96.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime96.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime96.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime97.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime97.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime97.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime98.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime98.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime98.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime99.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime99.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime99.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded); elseif DJBoothCustomLoopNumberTime100.KeyTime ~= 0 and DJBoothCustomLoopNumberCount == DJBoothCustomLoopNumberTime100.KeyTime then; onMouseUpBigButtonRecorded = DJBoothCustomLoopNumberTime100.KeySound; DJSoundboardOverlay.onRecordedLoop(onMouseUpBigButtonRecorded);
                    end
                --end
                
            end
        elseif specificPlayer:getModData().DJNotFailstate == false then
            specificPlayer:getModData().DJBoothCustomLoopActive = 0
            specificPlayer:getModData().DJBoothCustomLoopPlaying = false
            ButtonSmallCustomLoopImage.texture = SmallButtonTexture
            specificPlayer:getModData().DJBoothCustomLoop = false
        end
    else
    LSKScheduler.remove("dj-overlay-player")
    end
end

function DJSoundboardOverlay.onMouseUpSwitchA(x, y)

    local specificPlayer = getSpecificPlayer(0)
    if (specificPlayer:getModData().DJNotFailstate == true) and (specificPlayer:getPerkLevel(Perks.Music) >= 2) then
    if specificPlayer:getModData().DJBoothSwitchBPressed == true then
        SwitchBImage.texture = SwitchTexture
        SmallSwitchIndicatorBImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallEImage.texture = SmallButtonTexture
        ButtonSmallFImage.texture = SmallButtonTexture
        ButtonSmallGImage.texture = SmallButtonTexture
        ButtonSmallHImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchBPressed = false
    end
    if specificPlayer:getModData().DJBoothSwitchCPressed == true then
        SwitchCImage.texture = SwitchTexture
        SmallSwitchIndicatorCImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallIImage.texture = SmallButtonTexture
        ButtonSmallJImage.texture = SmallButtonTexture
        ButtonSmallKImage.texture = SmallButtonTexture
        ButtonSmallLImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchCPressed = false
    end
    if specificPlayer:getModData().DJBoothSwitchDPressed == true then
        SwitchDImage.texture = SwitchTexture
        SmallSwitchIndicatorDImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallMImage.texture = SmallButtonTexture
        ButtonSmallNImage.texture = SmallButtonTexture
        ButtonSmallOImage.texture = SmallButtonTexture
        ButtonSmallPImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchDPressed = false
    end
    
    if specificPlayer:getModData().DJBoothSwitchAPressed == true then
        DJKeypress(41)
        SwitchAImage.texture = SwitchTexture
        SmallSwitchIndicatorAImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallBImage.texture = SmallButtonTexture
        ButtonSmallCImage.texture = SmallButtonTexture
        ButtonSmallDImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchAPressed = false
    elseif specificPlayer:getModData().DJBoothSwitchAPressed == false then
        DJKeypress(41)
        specificPlayer:getModData().DJBoothSwitchAPressed = true
        SmallSwitchIndicatorAImage.texture = SmallSwitchIndicatorTextureOn
        SwitchAImage.texture = SwitchTextureOn
    end
        --getSoundManager():PlayWorldSound("JukeboxTurnOn", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
        getSoundManager():playUISound("JukeboxTurnOn")
        --DJSoundboardOverlay:updateStatus()
    elseif (specificPlayer:getModData().DJNotFailstate == true) then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSwitchB(x, y)

    local specificPlayer = getSpecificPlayer(0)
    if (specificPlayer:getModData().DJNotFailstate == true) and (specificPlayer:getPerkLevel(Perks.Music) >= 4) then
    if specificPlayer:getModData().DJBoothSwitchAPressed == true then
        SwitchAImage.texture = SwitchTexture
        SmallSwitchIndicatorAImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallBImage.texture = SmallButtonTexture
        ButtonSmallCImage.texture = SmallButtonTexture
        ButtonSmallDImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchAPressed = false
    end
    if specificPlayer:getModData().DJBoothSwitchCPressed == true then
        SwitchCImage.texture = SwitchTexture
        SmallSwitchIndicatorCImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallIImage.texture = SmallButtonTexture
        ButtonSmallJImage.texture = SmallButtonTexture
        ButtonSmallKImage.texture = SmallButtonTexture
        ButtonSmallLImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchCPressed = false
    end
    if specificPlayer:getModData().DJBoothSwitchDPressed == true then
        SwitchDImage.texture = SwitchTexture
        SmallSwitchIndicatorDImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallMImage.texture = SmallButtonTexture
        ButtonSmallNImage.texture = SmallButtonTexture
        ButtonSmallOImage.texture = SmallButtonTexture
        ButtonSmallPImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchDPressed = false
    end
    
    if specificPlayer:getModData().DJBoothSwitchBPressed == true then
        DJKeypress(41)
        SwitchBImage.texture = SwitchTexture
        SmallSwitchIndicatorBImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallEImage.texture = SmallButtonTexture
        ButtonSmallFImage.texture = SmallButtonTexture
        ButtonSmallGImage.texture = SmallButtonTexture
        ButtonSmallHImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchBPressed = false
    elseif specificPlayer:getModData().DJBoothSwitchBPressed == false then
        DJKeypress(41)
        specificPlayer:getModData().DJBoothSwitchBPressed = true
        SmallSwitchIndicatorBImage.texture = SmallSwitchIndicatorTextureOn
        SwitchBImage.texture = SwitchTextureOn
    end
        --getSoundManager():PlayWorldSound("JukeboxTurnOn", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
        getSoundManager():playUISound("JukeboxTurnOn")
        --DJSoundboardOverlay:updateStatus()
    elseif (specificPlayer:getModData().DJNotFailstate == true) then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSwitchC(x, y)

    local specificPlayer = getSpecificPlayer(0)
    if (specificPlayer:getModData().DJNotFailstate == true) and (specificPlayer:getPerkLevel(Perks.Music) >= 6) then
    if specificPlayer:getModData().DJBoothSwitchAPressed == true then
        SwitchAImage.texture = SwitchTexture
        SmallSwitchIndicatorAImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallBImage.texture = SmallButtonTexture
        ButtonSmallCImage.texture = SmallButtonTexture
        ButtonSmallDImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchAPressed = false
    end
    if specificPlayer:getModData().DJBoothSwitchBPressed == true then
        SwitchBImage.texture = SwitchTexture
        SmallSwitchIndicatorBImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallEImage.texture = SmallButtonTexture
        ButtonSmallFImage.texture = SmallButtonTexture
        ButtonSmallGImage.texture = SmallButtonTexture
        ButtonSmallHImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchBPressed = false
    end
    if specificPlayer:getModData().DJBoothSwitchDPressed == true then
        SwitchDImage.texture = SwitchTexture
        SmallSwitchIndicatorDImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallMImage.texture = SmallButtonTexture
        ButtonSmallNImage.texture = SmallButtonTexture
        ButtonSmallOImage.texture = SmallButtonTexture
        ButtonSmallPImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchDPressed = false
    end
    
    if specificPlayer:getModData().DJBoothSwitchCPressed == true then
        DJKeypress(41)
        SwitchCImage.texture = SwitchTexture
        SmallSwitchIndicatorCImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallIImage.texture = SmallButtonTexture
        ButtonSmallJImage.texture = SmallButtonTexture
        ButtonSmallKImage.texture = SmallButtonTexture
        ButtonSmallLImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchCPressed = false
    elseif specificPlayer:getModData().DJBoothSwitchCPressed == false then
        DJKeypress(41)
        specificPlayer:getModData().DJBoothSwitchCPressed = true
        SmallSwitchIndicatorCImage.texture = SmallSwitchIndicatorTextureOn
        SwitchCImage.texture = SwitchTextureOn
    end
        --getSoundManager():PlayWorldSound("JukeboxTurnOn", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
        getSoundManager():playUISound("JukeboxTurnOn")
        --DJSoundboardOverlay:updateStatus()
    elseif (specificPlayer:getModData().DJNotFailstate == true) then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSwitchD(x, y)

    local specificPlayer = getSpecificPlayer(0)
    if (specificPlayer:getModData().DJNotFailstate == true) and (specificPlayer:getPerkLevel(Perks.Music) >= 8) then
    if specificPlayer:getModData().DJBoothSwitchAPressed == true then
        SwitchAImage.texture = SwitchTexture
        SmallSwitchIndicatorAImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallBImage.texture = SmallButtonTexture
        ButtonSmallCImage.texture = SmallButtonTexture
        ButtonSmallDImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchAPressed = false
    end
    if specificPlayer:getModData().DJBoothSwitchBPressed == true then
        SwitchBImage.texture = SwitchTexture
        SmallSwitchIndicatorBImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallEImage.texture = SmallButtonTexture
        ButtonSmallFImage.texture = SmallButtonTexture
        ButtonSmallGImage.texture = SmallButtonTexture
        ButtonSmallHImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchBPressed = false
    end
    if specificPlayer:getModData().DJBoothSwitchCPressed == true then
        SwitchCImage.texture = SwitchTexture
        SmallSwitchIndicatorCImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallIImage.texture = SmallButtonTexture
        ButtonSmallJImage.texture = SmallButtonTexture
        ButtonSmallKImage.texture = SmallButtonTexture
        ButtonSmallLImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchCPressed = false
    end
    
    if specificPlayer:getModData().DJBoothSwitchDPressed == true then
        DJKeypress(41)
        SwitchDImage.texture = SwitchTexture
        SmallSwitchIndicatorDImage.texture = SmallSwitchIndicatorTexture
        ButtonSmallMImage.texture = SmallButtonTexture
        ButtonSmallNImage.texture = SmallButtonTexture
        ButtonSmallOImage.texture = SmallButtonTexture
        ButtonSmallPImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSwitchDPressed = false
    elseif specificPlayer:getModData().DJBoothSwitchDPressed == false then
        DJKeypress(41)
        specificPlayer:getModData().DJBoothSwitchDPressed = true
        SmallSwitchIndicatorDImage.texture = SmallSwitchIndicatorTextureOn
        SwitchDImage.texture = SwitchTextureOn
    end
        --getSoundManager():PlayWorldSound("JukeboxTurnOn", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
        getSoundManager():playUISound("JukeboxTurnOn")
        --DJSoundboardOverlay:updateStatus()
    elseif (specificPlayer:getModData().DJNotFailstate == true) then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSwitchBA(x, y)

    local specificPlayer = getSpecificPlayer(0)
    if (specificPlayer:getModData().DJNotFailstate == true) and (specificPlayer:getPerkLevel(Perks.Music) >= 5) then
    if specificPlayer:getModData().DJBoothSwitchBAPressed == true then
        SwitchBAImage.texture = SwitchBTexture
        specificPlayer:getModData().DJBoothSwitchBAPressed = false

    elseif specificPlayer:getModData().DJBoothSwitchBAPressed == false then
        
        specificPlayer:getModData().DJBoothSwitchBAPressed = true
        SwitchBAImage.texture = SwitchBTextureOn

        if specificPlayer:getModData().DJBoothCustomLoopActive == 1 then
            SmallSwitchIndicatorFImage.texture = SmallSwitchIndicatorTextureOn
            specificPlayer:getModData().DJBoothCustomLoopActive = 2
            DJBoothCustomLoopNumberCount2 = 1000
            DJBoothCustomLoopNumberCountTotal2 = 0
        elseif specificPlayer:getModData().DJBoothCustomLoopActive == 2 then
            SmallSwitchIndicatorGImage.texture = SmallSwitchIndicatorTextureOn
            specificPlayer:getModData().DJBoothCustomLoopActive = 3
            DJBoothCustomLoopNumberCount3 = 2000
            DJBoothCustomLoopNumberCountTotal3 = 0
        elseif  specificPlayer:getModData().DJBoothCustomLoopActive == 0 or specificPlayer:getModData().DJBoothCustomLoopActive == 3 then
        

            ButtonSmallCustomLoopImage.texture = SmallButtonTexture
            specificPlayer:getModData().DJBoothCustomLoopPlaying = false    

            SmallSwitchIndicatorEImage.texture = SmallSwitchIndicatorTextureOn
            SmallSwitchIndicatorFImage.texture = SmallSwitchIndicatorTexture
            SmallSwitchIndicatorGImage.texture = SmallSwitchIndicatorTexture
            specificPlayer:getModData().DJBoothCustomLoopActive = 1
            DJBoothCustomLoopNumberCount = 0
            DJBoothCustomLoopNumberCount2 = 1000
            DJBoothCustomLoopNumberCount3 = 2000
            DJBoothCustomLoopNumberCountTotal = 0
            DJBoothCustomLoopNumberTime1 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime2 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime3 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime4 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime5 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime6 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime7 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime8 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime9 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime10 = {KeyTime = 0, KeySound = 0};
            DJBoothCustomLoopNumberTime11 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime12 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime13 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime14 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime15 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime16 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime17 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime18 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime19 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime20 = {KeyTime = 0, KeySound = 0};
            DJBoothCustomLoopNumberTime21 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime22 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime23 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime24 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime25 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime26 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime27 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime28 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime29 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime30 = {KeyTime = 0, KeySound = 0};
            DJBoothCustomLoopNumberTime31 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime32 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime33 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime34 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime35 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime36 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime37 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime38 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime39 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime40 = {KeyTime = 0, KeySound = 0};
            DJBoothCustomLoopNumberTime41 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime42 = {KeyTime = 0, KeySound = 0};-- DJBoothCustomLoopNumberTime43 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime44 = {KeyTime = 0, KeySound = 0}; DJBoothCustomLoopNumberTime45 = {KeyTime = 0, KeySound = 0};
        end
        specificPlayer:getModData().DJBoothCustomLoop = true
    end
        --getSoundManager():PlayWorldSound("UI_Button_SELECT", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
        getSoundManager():playUISound("UI_Button_SELECT")
        --DJSoundboardOverlay:updateStatus()
    elseif (specificPlayer:getModData().DJNotFailstate == true) then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

local function getCustomName(object, cName)
    if not object then return false; end
    local properties = object:getSprite() and object:getSprite():getProperties()
    if properties and properties:has("CustomName") and (properties:get("CustomName") == cName) then
        return true
    end
    return false
end

local function hasActiveData(obj)
    if obj:getModData().DFOnOff and obj:getModData().IsMainDF and
    obj:getModData().DFOnOff == "on" then return true; end
    return false
end

local function setDFMLight(object)
    for x = object:getX()-8,object:getX()+8 do
        for y = object:getY()-8,object:getY()+8 do
            local square = getCell():getGridSquare(x,y,object:getZ());
            if square then
                for i = 0,square:getObjects():size()-1 do
                    local newObject = square:getObjects():get(i);
                    if newObject and instanceof(newObject, "IsoObject") then
                        if getCustomName(newObject, "Disco Floor") and hasActiveData(newObject) then
                            newObject:getModData().MainLight = 0
                            --newObject:transmitModData()
                            sendClientCommand("LSK", "ModifyObjData", {{newObject:getX(),newObject:getY(),newObject:getZ(),newObject:getSprite():getName()}, false, newObject:getModData()})
                        end
                    end
                end
            end
        end
    end
end

DJSoundboardOverlay.onMouseUpSwitchLightAll = function(parent, num, tex)
    if (not parent.switchLight[num].active) and (parent.switchLightDelay <= 0) and parent.switchLightInteract then
        for k, v in pairs(parent.switchLight) do
            if v.active then
                v.active = false
                if v.texture == getTexture(parent.switchLightTex.onL) then 
                    v.texture = getTexture(parent.switchLightTex.offL);
                else v.texture = getTexture(parent.switchLightTex.offR); end
            end
            v.light.texture = SmallSwitchIndicatorTextureRED
        end
        parent.switchLight[num].active = true
        parent.switchLight[num].texture = getTexture(tex)
        parent.switchLight[num].light.texture = SmallSwitchIndicatorTextureOn
        parent.djbooth:getModData().LightStyle = parent.switchLight[num].style
        --print("onMouseUpSwitchLightAll style IS: "..parent.switchLight[num].style)
        --parent.djbooth:transmitModData()
        sendClientCommand("LSK", "ModifyObjData", {{parent.djbooth:getX(),parent.djbooth:getY(),parent.djbooth:getZ(),parent.djbooth:getSprite():getName()}, false, parent.djbooth:getModData()})
        setDFMLight(parent.djbooth)
        getSoundManager():playUISound("UI_Button_SELECT")
        parent.switchLightDelay = 100
    else
        getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay:onMouseUpSwitchLightA(x, y)
    if not getSpecificPlayer(0):getModData().DJNotFailstate then return; end
    self.parent.onMouseUpSwitchLightAll(self.parent, "a", self.parent.switchLightTex.onL)
end

function DJSoundboardOverlay:onMouseUpSwitchLightB(x, y)
    if not getSpecificPlayer(0):getModData().DJNotFailstate then return; end
    self.parent.onMouseUpSwitchLightAll(self.parent, "b", self.parent.switchLightTex.onL)
end

function DJSoundboardOverlay:onMouseUpSwitchLightC(x, y)
    if not getSpecificPlayer(0):getModData().DJNotFailstate then return; end
    self.parent.onMouseUpSwitchLightAll(self.parent, "c", self.parent.switchLightTex.onL)
end

function DJSoundboardOverlay:onMouseUpSwitchLightD(x, y)
    if not getSpecificPlayer(0):getModData().DJNotFailstate then return; end
    self.parent.onMouseUpSwitchLightAll(self.parent, "d", self.parent.switchLightTex.onR)
end

function DJSoundboardOverlay:onMouseUpSwitchLightE(x, y)
    if not getSpecificPlayer(0):getModData().DJNotFailstate then return; end
    self.parent.onMouseUpSwitchLightAll(self.parent, "e", self.parent.switchLightTex.onR)
end

function DJSoundboardOverlay:onMouseUpSwitchLightF(x, y)
    if not getSpecificPlayer(0):getModData().DJNotFailstate then return; end
    self.parent.onMouseUpSwitchLightAll(self.parent, "f", self.parent.switchLightTex.onR)
end

function DJSoundboardOverlay.onMouseUpVynilA(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJNotFailstate == true then
    DJKeypress(79)
    specificPlayer:getModData().VynilAScratched = true
    if     specificPlayer:getModData().VynilAScratchedTimes == 0 then
    specificPlayer:getModData().VynilAScratchedTimes = 1
    elseif     specificPlayer:getModData().VynilAScratchedTimes == 1 then
    specificPlayer:getModData().VynilAScratchedTimes = 0
    end
    DJSoundboardOverlay:updateStatus()
    end
end

function DJSoundboardOverlay.onMouseUpVynilB(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJNotFailstate == true then
    DJKeypress(79)
    specificPlayer:getModData().VynilBScratched = true
    if     specificPlayer:getModData().VynilBScratchedTimes == 0 then
    specificPlayer:getModData().VynilBScratchedTimes = 1
    elseif     specificPlayer:getModData().VynilBScratchedTimes == 1 then
    specificPlayer:getModData().VynilBScratchedTimes = 0
    end
    DJSoundboardOverlay:updateStatus()
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonCustomLoop(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJNotFailstate == true and specificPlayer:getModData().DJBoothCustomLoopPlaying == false and ((specificPlayer:getModData().DJBoothCustomLoop == false and specificPlayer:getModData().DJBoothCustomLoopActive == 1) or specificPlayer:getModData().DJBoothCustomLoopActive > 1) then
        DJBoothCustomLoopNumberCount = 0
        if specificPlayer:getModData().DJBoothCustomLoop == true and specificPlayer:getModData().DJBoothCustomLoopActive == 3 then
            DJBoothCustomLoopNumberCount2 = 1000
        elseif specificPlayer:getModData().DJBoothCustomLoop == false then
            DJBoothCustomLoopNumberCount2 = 1000
            DJBoothCustomLoopNumberCount3 = 2000
        end
        if specificPlayer:getModData().DJBoothSmallButtonAPressed == true then
            ButtonSmallAImage.texture = SmallButtonTexture
            specificPlayer:getModData().DJBoothSmallButtonAPressed = false
        end
        specificPlayer:getModData().DJBoothCustomLoopPlaying = true
        --getSoundManager():PlayWorldSound("JukeboxTurnOff", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
        getSoundManager():playUISound("JukeboxTurnOff")
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJNotFailstate == true and specificPlayer:getModData().DJBoothCustomLoopPlaying == true and ((specificPlayer:getModData().DJBoothCustomLoop == false and specificPlayer:getModData().DJBoothCustomLoopActive == 1) or specificPlayer:getModData().DJBoothCustomLoopActive > 1) then
        DJBoothCustomLoopNumberCount = 0
        if specificPlayer:getModData().DJBoothCustomLoop == true and specificPlayer:getModData().DJBoothCustomLoopActive == 3 then
            DJBoothCustomLoopNumberCount2 = 1000
        elseif specificPlayer:getModData().DJBoothCustomLoop == false then
            DJBoothCustomLoopNumberCount2 = 1000
            DJBoothCustomLoopNumberCount3 = 2000
        end
        if specificPlayer:getModData().DJBoothSmallButtonAPressed == true then
            ButtonSmallAImage.texture = SmallButtonTexture
            specificPlayer:getModData().DJBoothSmallButtonAPressed = false
        end
        ButtonSmallCustomLoopImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothCustomLoopPlaying = false
    else
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonA(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonAPressed = true    
        DJKeypress(41)
        specificPlayer:getModData().DJBoothCustomLoopActive = 0
        specificPlayer:getModData().DJBoothCustomLoopPlaying = false
        ButtonSmallCustomLoopImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothCustomLoop = false
        SwitchBAImage.texture = SwitchBTexture
        specificPlayer:getModData().DJBoothSwitchBAPressed = false
        SmallSwitchIndicatorEImage.texture = SmallSwitchIndicatorTexture
        SmallSwitchIndicatorFImage.texture = SmallSwitchIndicatorTexture
        SmallSwitchIndicatorGImage.texture = SmallSwitchIndicatorTexture
        --getSoundManager():PlayWorldSound("JukeboxTurnOff", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
        getSoundManager():playUISound("JukeboxTurnOff")
        DJSoundboardOverlay:updateStatus()
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonB(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchAPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonBPressed = true    
        DJKeypress(2)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchAPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonC(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchAPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonCPressed = true    
        DJKeypress(3)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchAPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonD(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchAPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonDPressed = true    
        DJKeypress(4)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchAPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonE(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchBPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonEPressed = true    
        DJKeypress(5)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchBPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonF(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchBPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonFPressed = true    
        DJKeypress(6)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchBPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonG(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchBPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonGPressed = true    
        DJKeypress(7)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchBPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonH(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchBPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonHPressed = true    
        DJKeypress(8)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchBPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonI(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchCPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonIPressed = true    
        DJKeypress(9)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchCPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonJ(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchCPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonJPressed = true    
        DJKeypress(10)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchCPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonK(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchCPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonKPressed = true    
        DJKeypress(11)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchCPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonL(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchCPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonLPressed = true    
        DJKeypress(12)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchCPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonM(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchDPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonMPressed = true    
        DJKeypress(19)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchDPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonN(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchDPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonNPressed = true    
        DJKeypress(20)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchDPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonO(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchDPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonOPressed = true    
        DJKeypress(21)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchDPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpSmallButtonP(x, y)
    
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothSwitchDPressed == true and specificPlayer:getModData().DJNotFailstate == true then
        specificPlayer:getModData().DJBoothSmallButtonPPressed = true    
        DJKeypress(22)
        DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJBoothSwitchDPressed == false and specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpBigButtonA(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJNotFailstate == true and ((ButtonBigAImage.texture == BigButtonTexture) or (specificPlayer:getModData().DJBoothBigButtonAPressedCount >= 5)) then
    DJKeypress(80)
    specificPlayer:getModData().DJBoothBigButtonAPressed = true
    specificPlayer:getModData().DJBoothBigButtonAPressedCount = 0
    DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpBigButtonB(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJNotFailstate == true and ((ButtonBigBImage.texture == BigButtonTexture) or (specificPlayer:getModData().DJBoothBigButtonBPressedCount >= 5)) then
    DJKeypress(81)
    specificPlayer:getModData().DJBoothBigButtonBPressed = true
    specificPlayer:getModData().DJBoothBigButtonBPressedCount = 0
    DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpBigButtonC(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJNotFailstate == true and ((ButtonBigCImage.texture == BigButtonTexture) or (specificPlayer:getModData().DJBoothBigButtonCPressedCount >= 3)) then
    DJKeypress(75)
    specificPlayer:getModData().DJBoothBigButtonCPressed = true
    specificPlayer:getModData().DJBoothBigButtonCPressedCount = 0
    DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpBigButtonD(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJNotFailstate == true and ((ButtonBigDImage.texture == BigButtonTexture) or (specificPlayer:getModData().DJBoothBigButtonDPressedCount >= 12)) then
    DJKeypress(76)
    specificPlayer:getModData().DJBoothBigButtonDPressed = true
    specificPlayer:getModData().DJBoothBigButtonDPressedCount = 0
    DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpBigButtonE(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJNotFailstate == true and ((ButtonBigEImage.texture == BigButtonTexture) or (specificPlayer:getModData().DJBoothBigButtonEPressedCount >= 6)) then
    DJKeypress(77)
    specificPlayer:getModData().DJBoothBigButtonEPressed = true
    specificPlayer:getModData().DJBoothBigButtonEPressedCount = 0
    DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpBigButtonF(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJNotFailstate == true and ((ButtonBigFImage.texture == BigButtonTexture) or (specificPlayer:getModData().DJBoothBigButtonFPressedCount >= 3)) then
    DJKeypress(71)
    specificPlayer:getModData().DJBoothBigButtonFPressed = true
    specificPlayer:getModData().DJBoothBigButtonFPressedCount = 0
    DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpBigButtonG(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJNotFailstate == true and ((ButtonBigGImage.texture == BigButtonTexture) or (specificPlayer:getModData().DJBoothBigButtonGPressedCount >= 5)) then
    DJKeypress(72)
    specificPlayer:getModData().DJBoothBigButtonGPressed = true
    specificPlayer:getModData().DJBoothBigButtonGPressedCount = 0
    DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpBigButtonH(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJNotFailstate == true and ((ButtonBigHImage.texture == BigButtonTexture) or (specificPlayer:getModData().DJBoothBigButtonHPressedCount >= 3)) then
    DJKeypress(73)
    specificPlayer:getModData().DJBoothBigButtonHPressed = true
    specificPlayer:getModData().DJBoothBigButtonHPressedCount = 0
    DJSoundboardOverlay:updateStatus()
    elseif specificPlayer:getModData().DJNotFailstate == true then
    --getSoundManager():PlayWorldSound("UI_DJBooth_ERROR", getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
    getSoundManager():playUISound("UI_DJBooth_ERROR")
    end
end

function DJSoundboardOverlay.onMouseUpBigButton1(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothCustomLoop == true then
        specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 1
    end
    if specificPlayer:getModData().DJNotFailstate == true then
    DJKeypress(44)
    specificPlayer:getModData().DJBoothBigButton1Pressed = true
    specificPlayer:getModData().DJBoothBigButton1PressedCount = 0
    DJSoundboardOverlay:updateStatus()
    end
end

function DJSoundboardOverlay.onMouseUpBigButton2(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothCustomLoop == true then
        specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 2
    end
    if specificPlayer:getModData().DJNotFailstate == true then
    DJKeypress(45)
    specificPlayer:getModData().DJBoothBigButton2Pressed = true
    specificPlayer:getModData().DJBoothBigButton2PressedCount = 0
    DJSoundboardOverlay:updateStatus()
    end
end

function DJSoundboardOverlay.onMouseUpBigButton3(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothCustomLoop == true then
        specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 3
    end
    if specificPlayer:getModData().DJNotFailstate == true then
    DJKeypress(46)
    specificPlayer:getModData().DJBoothBigButton3Pressed = true
    specificPlayer:getModData().DJBoothBigButton3PressedCount = 0
    DJSoundboardOverlay:updateStatus()
    end
end

function DJSoundboardOverlay.onMouseUpBigButton4(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothCustomLoop == true then
        specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 4
    end
    if specificPlayer:getModData().DJNotFailstate == true then
    DJKeypress(47)
    specificPlayer:getModData().DJBoothBigButton4Pressed = true
    specificPlayer:getModData().DJBoothBigButton4PressedCount = 0
    DJSoundboardOverlay:updateStatus()
    end
end

function DJSoundboardOverlay.onMouseUpBigButton5(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothCustomLoop == true then
        specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 5
    end
    if specificPlayer:getModData().DJNotFailstate == true then
    DJKeypress(48)
    specificPlayer:getModData().DJBoothBigButton5Pressed = true
    specificPlayer:getModData().DJBoothBigButton5PressedCount = 0
    DJSoundboardOverlay:updateStatus()
    end
end

function DJSoundboardOverlay.onMouseUpBigButton6(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothCustomLoop == true then
        specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 6
    end
    if specificPlayer:getModData().DJNotFailstate == true then
    DJKeypress(49)
    specificPlayer:getModData().DJBoothBigButton6Pressed = true
    specificPlayer:getModData().DJBoothBigButton6PressedCount = 0
    DJSoundboardOverlay:updateStatus()
    end
end

function DJSoundboardOverlay.onMouseUpBigButton7(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothCustomLoop == true then
        specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 7
    end
    if specificPlayer:getModData().DJNotFailstate == true then
    DJKeypress(50)
    specificPlayer:getModData().DJBoothBigButton7Pressed = true
    specificPlayer:getModData().DJBoothBigButton7PressedCount = 0
    DJSoundboardOverlay:updateStatus()
    end
end

function DJSoundboardOverlay.onMouseUpBigButton8(x, y)
    local specificPlayer = getSpecificPlayer(0)
    if specificPlayer:getModData().DJBoothCustomLoop == true then
        specificPlayer:getModData().DJBoothCustomLoopKeyPressed = 8
    end
    if specificPlayer:getModData().DJNotFailstate == true then
    DJKeypress(51)
    specificPlayer:getModData().DJBoothBigButton8Pressed = true
    specificPlayer:getModData().DJBoothBigButton8PressedCount = 0
    DJSoundboardOverlay:updateStatus()
    end
end

function DJSoundboardOverlay:initialise()
    ISPanel.initialise(self);
    local specificPlayer = getSpecificPlayer(0)
    local DJMusicLevel = specificPlayer:getPerkLevel(Perks.Music)
    local LevelNeededText2 = getText("UI_DJBooth_Need2")
    local LevelNeededText4 = getText("UI_DJBooth_Need4")
    local LevelNeededText5 = getText("UI_DJBooth_Need5")
    local LevelNeededText6 = getText("UI_DJBooth_Need6")
    local LevelNeededText8 = getText("UI_DJBooth_Need8")
    if DJMusicLevel >= 8 then
    LevelNeededText2 = getText("UI_DJBooth_LoopMode1")
    LevelNeededText4 = getText("UI_DJBooth_LoopMode2")
    LevelNeededText6 = getText("UI_DJBooth_LoopMode3")
    LevelNeededText5 = getText("UI_DJBooth_LoopRecord")
    LevelNeededText8 = getText("UI_DJBooth_LoopMode4")
    elseif DJMusicLevel >= 6 then
    LevelNeededText2 = getText("UI_DJBooth_LoopMode1")
    LevelNeededText4 = getText("UI_DJBooth_LoopMode2")
    LevelNeededText5 = getText("UI_DJBooth_LoopRecord")
    LevelNeededText6 = getText("UI_DJBooth_LoopMode3")
    elseif DJMusicLevel >= 5 then
    LevelNeededText2 = getText("UI_DJBooth_LoopMode1")
    LevelNeededText4 = getText("UI_DJBooth_LoopMode2")
    LevelNeededText5 = getText("UI_DJBooth_LoopRecord")
    elseif DJMusicLevel >= 4 then
    LevelNeededText2 = getText("UI_DJBooth_LoopMode1")
    LevelNeededText4 = getText("UI_DJBooth_LoopMode2")
    elseif DJMusicLevel >= 2 then
    LevelNeededText2 = getText("UI_DJBooth_LoopMode1")
    end

    local switchLightIndicatorTex, switchLightText = SmallSwitchIndicatorTextureRED, " - "..getText("UI_DJBooth_FloorLight_Missing")
    if self.switchLightInteract then switchLightIndicatorTex, switchLightText = SmallSwitchIndicatorTexture, " "; end

    local DJSoundboardOverlayTexture = getTexture("media/textures/DJBooth_Overlay.png")
    self.DJSoundboardOverlayImage = ISImage:new((self:getWidth() / 2) -430, (self:getHeight() / 2) - 160, 100, 25, DJSoundboardOverlayTexture)
    self.DJSoundboardOverlayImage:initialise()
    self.DJSoundboardOverlayImage:instantiate()
    self:addChild(self.DJSoundboardOverlayImage)
    
------- REGULAR BUTTONS

    if specificPlayer:getModData().DJKEY == 0 then
    KeyNumberTextureOn = getTexture("media/textures/DJBooth_OverlayNumber0.png")
    elseif specificPlayer:getModData().DJKEY == 1 then
    KeyNumberTextureOn = getTexture("media/textures/DJBooth_OverlayNumber1.png")
    elseif specificPlayer:getModData().DJKEY == 2 then
    KeyNumberTextureOn = getTexture("media/textures/DJBooth_OverlayNumber2.png")
    elseif specificPlayer:getModData().DJKEY == 3 then
    KeyNumberTextureOn = getTexture("media/textures/DJBooth_OverlayNumber3.png")
    elseif specificPlayer:getModData().DJKEY == 4 then
    KeyNumberTextureOn = getTexture("media/textures/DJBooth_OverlayNumber4.png")
    end
    self.DJSoundboardOverlayKeyNumberImage = ISImage:new((self:getWidth() / 2) - 16, (self:getHeight() / 2) - 36, 31, 50, KeyNumberTextureOn)
    KeyNumberImage = self.DJSoundboardOverlayKeyNumberImage
    self.DJSoundboardOverlayKeyNumberImage:initialise()
    self.DJSoundboardOverlayKeyNumberImage:instantiate()
    self:addChild(self.DJSoundboardOverlayKeyNumberImage)

    self.button1p = ISButton:new((self:getWidth() / 2) + 22, (self:getHeight() / 2) + 20, 15, 26, getText(">"), self, DJSoundboardOverlay.onClick);
    self.button1p.internal = "RIGHTLEFT";
    self.button1p:initialise();
    self.button1p:instantiate();
    self.button1p.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.button1p);
    
    self.button4p = ISButton:new((self:getWidth() / 2) - 37, (self:getHeight() / 2) + 20, 15, 26, getText("<"), self, DJSoundboardOverlay.onClick);
    self.button4p.internal = "RIGHTLEFT";
    self.button4p:initialise();
    self.button4p:instantiate();
    self.button4p.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.button4p);
    
    self.button2p = ISButton:new((self:getWidth() / 2) - 17, (self:getHeight() / 2) + 18, 35, 12, getText("^"), self, DJSoundboardOverlay.onClick);
    self.button2p.internal = "UP";
    self.button2p:initialise();
    self.button2p:instantiate();
    self.button2p.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.button2p);
    
    self.button3p = ISButton:new((self:getWidth() / 2) - 17, (self:getHeight() / 2) + 38, 35, 12, getText("v"), self, DJSoundboardOverlay.onClick);
    self.button3p.internal = "DOWN";
    self.button3p:initialise();
    self.button3p:instantiate();
    self.button3p.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.button3p);

------ VYNILS

    self.DJSoundboardOverlayVynilAImage = ISImage:new((self:getWidth() / 2) - 430, (self:getHeight() / 2) - 90, 220, 290, VynilTextureA)
    self.DJSoundboardOverlayVynilAImage.onMouseUp = DJSoundboardOverlay.onMouseUpVynilA
    VynilAImage = self.DJSoundboardOverlayVynilAImage
    self.DJSoundboardOverlayVynilAImage:setMouseOverText(getText("UI_DJBooth_Scratch"))
    --self.DJSoundboardOverlayVynilAImage.tooltip = getText("Tooltip_DJBooth_Scratch")
    self.DJSoundboardOverlayVynilAImage:initialise()
    self.DJSoundboardOverlayVynilAImage:instantiate()
    self:addChild(self.DJSoundboardOverlayVynilAImage)

    self.DJSoundboardOverlayVynilBImage = ISImage:new((self:getWidth() / 2) + 210, (self:getHeight() / 2) - 90, 220, 290, VynilTextureB)
    self.DJSoundboardOverlayVynilBImage.onMouseUp = DJSoundboardOverlay.onMouseUpVynilB
    VynilBImage = self.DJSoundboardOverlayVynilBImage
    self.DJSoundboardOverlayVynilBImage:setMouseOverText(getText("UI_DJBooth_Scratch"))
    --self.DJSoundboardOverlayVynilBImage:setUIName("UI_DJBoothScratch")
    self.DJSoundboardOverlayVynilBImage:initialise()
    self.DJSoundboardOverlayVynilBImage:instantiate()
    self:addChild(self.DJSoundboardOverlayVynilBImage)

------ SWITCHES

    self.DJSoundboardOverlaySwitchAImage = ISImage:new((self:getWidth() / 2) - 118, (self:getHeight() / 2) + 60, 35, 60, SwitchTexture)
    self.DJSoundboardOverlaySwitchAImage.onMouseUp = DJSoundboardOverlay.onMouseUpSwitchA
    SwitchAImage = self.DJSoundboardOverlaySwitchAImage
    self.DJSoundboardOverlaySwitchAImage:setMouseOverText(LevelNeededText2)
    self.DJSoundboardOverlaySwitchAImage:initialise()
    self.DJSoundboardOverlaySwitchAImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySwitchAImage)

    self.DJSoundboardOverlaySwitchBImage = ISImage:new((self:getWidth() / 2) - 51, (self:getHeight() / 2) + 60, 35, 60, SwitchTexture)
    self.DJSoundboardOverlaySwitchBImage.onMouseUp = DJSoundboardOverlay.onMouseUpSwitchB
    SwitchBImage = self.DJSoundboardOverlaySwitchBImage
    self.DJSoundboardOverlaySwitchBImage:setMouseOverText(LevelNeededText4)
    self.DJSoundboardOverlaySwitchBImage:initialise()
    self.DJSoundboardOverlaySwitchBImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySwitchBImage)

    self.DJSoundboardOverlaySwitchCImage = ISImage:new((self:getWidth() / 2) + 15, (self:getHeight() / 2) + 60, 35, 60, SwitchTexture)
    self.DJSoundboardOverlaySwitchCImage.onMouseUp = DJSoundboardOverlay.onMouseUpSwitchC
    SwitchCImage = self.DJSoundboardOverlaySwitchCImage
    self.DJSoundboardOverlaySwitchCImage:setMouseOverText(LevelNeededText6)
    self.DJSoundboardOverlaySwitchCImage:initialise()
    self.DJSoundboardOverlaySwitchCImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySwitchCImage)
    
    self.DJSoundboardOverlaySwitchDImage = ISImage:new((self:getWidth() / 2) + 82, (self:getHeight() / 2) + 60, 35, 60, SwitchTexture)
    self.DJSoundboardOverlaySwitchDImage.onMouseUp = DJSoundboardOverlay.onMouseUpSwitchD
    SwitchDImage = self.DJSoundboardOverlaySwitchDImage
    self.DJSoundboardOverlaySwitchDImage:setMouseOverText(LevelNeededText8)
    self.DJSoundboardOverlaySwitchDImage:initialise()
    self.DJSoundboardOverlaySwitchDImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySwitchDImage)
    
    self.DJSoundboardOverlaySwitchBAImage = ISImage:new((self:getWidth() / 2) - 18, (self:getHeight() / 2) - 80, 36, 36, SwitchBTexture)
    self.DJSoundboardOverlaySwitchBAImage.onMouseUp = DJSoundboardOverlay.onMouseUpSwitchBA
    SwitchBAImage = self.DJSoundboardOverlaySwitchBAImage
    self.DJSoundboardOverlaySwitchBAImage:setMouseOverText(LevelNeededText5)
    self.DJSoundboardOverlaySwitchBAImage:initialise()
    self.DJSoundboardOverlaySwitchBAImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySwitchBAImage)

    self.DJSoundboardOverlaySwitchLightAImage = ISImage:new((self:getWidth() / 2) - 240, (self:getHeight() / 2) - 155, 22, 26, getTexture(self.switchLightTex.offL))
    self.DJSoundboardOverlaySwitchLightAImage.onMouseUp = DJSoundboardOverlay.onMouseUpSwitchLightA
    self.switchLight.a = self.DJSoundboardOverlaySwitchLightAImage
    self.switchLight.a.style = "None"
    self.DJSoundboardOverlaySwitchLightAImage:setMouseOverText(getText("UI_DJBooth_FloorLight").." 1"..switchLightText)
    self.DJSoundboardOverlaySwitchLightAImage:initialise()
    self.DJSoundboardOverlaySwitchLightAImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySwitchLightAImage)

    self.DJSoundboardOverlaySwitchLightBImage = ISImage:new((self:getWidth() / 2) - 220, (self:getHeight() / 2) - 155, 22, 26, getTexture(self.switchLightTex.offL))
    self.DJSoundboardOverlaySwitchLightBImage.onMouseUp = DJSoundboardOverlay.onMouseUpSwitchLightB
    self.switchLight.b = self.DJSoundboardOverlaySwitchLightBImage
    self.switchLight.b.style = "disco"
    self.DJSoundboardOverlaySwitchLightBImage:setMouseOverText(getText("UI_DJBooth_FloorLight").." 2"..switchLightText)
    self.DJSoundboardOverlaySwitchLightBImage:initialise()
    self.DJSoundboardOverlaySwitchLightBImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySwitchLightBImage)

    self.DJSoundboardOverlaySwitchLightCImage = ISImage:new((self:getWidth() / 2) - 200, (self:getHeight() / 2) - 155, 22, 26, getTexture(self.switchLightTex.offL))
    self.DJSoundboardOverlaySwitchLightCImage.onMouseUp = DJSoundboardOverlay.onMouseUpSwitchLightC
    self.switchLight.c = self.DJSoundboardOverlaySwitchLightCImage
    self.switchLight.c.style = "jazz"
    self.DJSoundboardOverlaySwitchLightCImage:setMouseOverText(getText("UI_DJBooth_FloorLight").." 3"..switchLightText)
    self.DJSoundboardOverlaySwitchLightCImage:initialise()
    self.DJSoundboardOverlaySwitchLightCImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySwitchLightCImage)

    self.DJSoundboardOverlaySwitchLightDImage = ISImage:new((self:getWidth() / 2) + 178, (self:getHeight() / 2) - 155, 22, 26, getTexture(self.switchLightTex.offR))
    self.DJSoundboardOverlaySwitchLightDImage.onMouseUp = DJSoundboardOverlay.onMouseUpSwitchLightD
    self.switchLight.d = self.DJSoundboardOverlaySwitchLightDImage
    self.switchLight.d.style = "electronic1"
    self.DJSoundboardOverlaySwitchLightDImage:setMouseOverText(getText("UI_DJBooth_FloorLight").." 4"..switchLightText)
    self.DJSoundboardOverlaySwitchLightDImage:initialise()
    self.DJSoundboardOverlaySwitchLightDImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySwitchLightDImage)

    self.DJSoundboardOverlaySwitchLightEImage = ISImage:new((self:getWidth() / 2) + 198, (self:getHeight() / 2) - 155, 22, 26, getTexture(self.switchLightTex.offR))
    self.DJSoundboardOverlaySwitchLightEImage.onMouseUp = DJSoundboardOverlay.onMouseUpSwitchLightE
    self.switchLight.e = self.DJSoundboardOverlaySwitchLightEImage
    self.switchLight.e.style = "electronic2"
    self.DJSoundboardOverlaySwitchLightEImage:setMouseOverText(getText("UI_DJBooth_FloorLight").." 5"..switchLightText)
    self.DJSoundboardOverlaySwitchLightEImage:initialise()
    self.DJSoundboardOverlaySwitchLightEImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySwitchLightEImage)

    self.DJSoundboardOverlaySwitchLightFImage = ISImage:new((self:getWidth() / 2) + 218, (self:getHeight() / 2) - 155, 22, 26, getTexture(self.switchLightTex.offR))
    self.DJSoundboardOverlaySwitchLightFImage.onMouseUp = DJSoundboardOverlay.onMouseUpSwitchLightF
    self.switchLight.f = self.DJSoundboardOverlaySwitchLightFImage
    self.switchLight.f.style = "electronic3"
    self.DJSoundboardOverlaySwitchLightFImage:setMouseOverText(getText("UI_DJBooth_FloorLight").." 6"..switchLightText)
    self.DJSoundboardOverlaySwitchLightFImage:initialise()
    self.DJSoundboardOverlaySwitchLightFImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySwitchLightFImage)

------ SMALL BUTTONS

    self.DJSoundboardOverlaySmallLightSwitchIndicatorAImage = ISImage:new((self:getWidth() / 2) - 236, (self:getHeight() / 2) - 125, 12, 13, switchLightIndicatorTex)
    --SmallSwitchIndicatorAImage = self.DJSoundboardOverlaySmallLightSwitchIndicatorAImage
    self.DJSoundboardOverlaySmallLightSwitchIndicatorAImage:initialise()
    self.DJSoundboardOverlaySmallLightSwitchIndicatorAImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallLightSwitchIndicatorAImage)
    self.switchLight.a.light = self.DJSoundboardOverlaySmallLightSwitchIndicatorAImage

    self.DJSoundboardOverlaySmallLightSwitchIndicatorBImage = ISImage:new((self:getWidth() / 2) - 216, (self:getHeight() / 2) - 125, 12, 13, switchLightIndicatorTex)
    --SmallSwitchIndicatorAImage = self.DJSoundboardOverlaySmallLightSwitchIndicatorBImage
    self.DJSoundboardOverlaySmallLightSwitchIndicatorBImage:initialise()
    self.DJSoundboardOverlaySmallLightSwitchIndicatorBImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallLightSwitchIndicatorBImage)
    self.switchLight.b.light = self.DJSoundboardOverlaySmallLightSwitchIndicatorBImage

    self.DJSoundboardOverlaySmallLightSwitchIndicatorCImage = ISImage:new((self:getWidth() / 2) - 196, (self:getHeight() / 2) - 125, 12, 13, switchLightIndicatorTex)
    --SmallSwitchIndicatorAImage = self.DJSoundboardOverlaySmallLightSwitchIndicatorCImage
    self.DJSoundboardOverlaySmallLightSwitchIndicatorCImage:initialise()
    self.DJSoundboardOverlaySmallLightSwitchIndicatorCImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallLightSwitchIndicatorCImage)
    self.switchLight.c.light = self.DJSoundboardOverlaySmallLightSwitchIndicatorCImage

    self.DJSoundboardOverlaySmallLightSwitchIndicatorDImage = ISImage:new((self:getWidth() / 2) + 184, (self:getHeight() / 2) - 125, 12, 13, switchLightIndicatorTex)
    --SmallSwitchIndicatorAImage = self.DJSoundboardOverlaySmallLightSwitchIndicatorDImage
    self.DJSoundboardOverlaySmallLightSwitchIndicatorDImage:initialise()
    self.DJSoundboardOverlaySmallLightSwitchIndicatorDImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallLightSwitchIndicatorDImage)
    self.switchLight.d.light = self.DJSoundboardOverlaySmallLightSwitchIndicatorDImage

    self.DJSoundboardOverlaySmallLightSwitchIndicatorEImage = ISImage:new((self:getWidth() / 2) + 204, (self:getHeight() / 2) - 125, 12, 13, switchLightIndicatorTex)
    --SmallSwitchIndicatorAImage = self.DJSoundboardOverlaySmallLightSwitchIndicatorEImage
    self.DJSoundboardOverlaySmallLightSwitchIndicatorEImage:initialise()
    self.DJSoundboardOverlaySmallLightSwitchIndicatorEImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallLightSwitchIndicatorEImage)
    self.switchLight.e.light = self.DJSoundboardOverlaySmallLightSwitchIndicatorEImage

    self.DJSoundboardOverlaySmallLightSwitchIndicatorFImage = ISImage:new((self:getWidth() / 2) + 224, (self:getHeight() / 2) - 125, 12, 13, switchLightIndicatorTex)
    --SmallSwitchIndicatorAImage = self.DJSoundboardOverlaySmallLightSwitchIndicatorFImage
    self.DJSoundboardOverlaySmallLightSwitchIndicatorFImage:initialise()
    self.DJSoundboardOverlaySmallLightSwitchIndicatorFImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallLightSwitchIndicatorFImage)
    self.switchLight.f.light = self.DJSoundboardOverlaySmallLightSwitchIndicatorFImage

    self.DJSoundboardOverlaySmallButtonCustomLoopImage = ISImage:new((self:getWidth() / 2) - 63, (self:getHeight() / 2) + 10, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonCustomLoopImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonCustomLoop
    ButtonSmallCustomLoopImage = self.DJSoundboardOverlaySmallButtonCustomLoopImage
    self.DJSoundboardOverlaySmallButtonCustomLoopImage:setMouseOverText(getText("UI_DJBooth_CustomLoop"))
    self.DJSoundboardOverlaySmallButtonCustomLoopImage:initialise()
    self.DJSoundboardOverlaySmallButtonCustomLoopImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonCustomLoopImage)

    self.DJSoundboardOverlaySmallSwitchIndicatorAImage = ISImage:new((self:getWidth() / 2) - 90, (self:getHeight() / 2) - 140, 12, 13, SmallSwitchIndicatorTexture)
    SmallSwitchIndicatorAImage = self.DJSoundboardOverlaySmallSwitchIndicatorAImage
    self.DJSoundboardOverlaySmallSwitchIndicatorAImage:initialise()
    self.DJSoundboardOverlaySmallSwitchIndicatorAImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallSwitchIndicatorAImage)

    self.DJSoundboardOverlaySmallSwitchIndicatorBImage = ISImage:new((self:getWidth() / 2) + 10, (self:getHeight() / 2) - 140, 12, 13, SmallSwitchIndicatorTexture)
    SmallSwitchIndicatorBImage = self.DJSoundboardOverlaySmallSwitchIndicatorBImage
    self.DJSoundboardOverlaySmallSwitchIndicatorBImage:initialise()
    self.DJSoundboardOverlaySmallSwitchIndicatorBImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallSwitchIndicatorBImage)
    
    self.DJSoundboardOverlaySmallSwitchIndicatorCImage = ISImage:new((self:getWidth() / 2) - 108, (self:getHeight() / 2) - 110, 12, 13, SmallSwitchIndicatorTexture)
    SmallSwitchIndicatorCImage = self.DJSoundboardOverlaySmallSwitchIndicatorCImage
    self.DJSoundboardOverlaySmallSwitchIndicatorCImage:initialise()
    self.DJSoundboardOverlaySmallSwitchIndicatorCImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallSwitchIndicatorCImage)
    
    self.DJSoundboardOverlaySmallSwitchIndicatorDImage = ISImage:new((self:getWidth() / 2) + 10, (self:getHeight() / 2) - 110, 12, 13, SmallSwitchIndicatorTexture)
    SmallSwitchIndicatorDImage = self.DJSoundboardOverlaySmallSwitchIndicatorDImage
    self.DJSoundboardOverlaySmallSwitchIndicatorDImage:initialise()
    self.DJSoundboardOverlaySmallSwitchIndicatorDImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallSwitchIndicatorDImage)

    self.DJSoundboardOverlaySmallSwitchIndicatorEImage = ISImage:new((self:getWidth() / 2) - 35, (self:getHeight() / 2) - 40, 12, 13, SmallSwitchIndicatorTexture)
    SmallSwitchIndicatorEImage = self.DJSoundboardOverlaySmallSwitchIndicatorEImage
    self.DJSoundboardOverlaySmallSwitchIndicatorEImage:initialise()
    self.DJSoundboardOverlaySmallSwitchIndicatorEImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallSwitchIndicatorEImage)

    self.DJSoundboardOverlaySmallSwitchIndicatorFImage = ISImage:new((self:getWidth() / 2) - 35, (self:getHeight() / 2) - 20, 12, 13, SmallSwitchIndicatorTexture)
    SmallSwitchIndicatorFImage = self.DJSoundboardOverlaySmallSwitchIndicatorFImage
    self.DJSoundboardOverlaySmallSwitchIndicatorFImage:initialise()
    self.DJSoundboardOverlaySmallSwitchIndicatorFImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallSwitchIndicatorFImage)
    
    self.DJSoundboardOverlaySmallSwitchIndicatorGImage = ISImage:new((self:getWidth() / 2) - 35, (self:getHeight() / 2) + 0, 12, 13, SmallSwitchIndicatorTexture)
    SmallSwitchIndicatorGImage = self.DJSoundboardOverlaySmallSwitchIndicatorGImage
    self.DJSoundboardOverlaySmallSwitchIndicatorGImage:initialise()
    self.DJSoundboardOverlaySmallSwitchIndicatorGImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallSwitchIndicatorGImage)

    self.DJSoundboardOverlaySmallButtonAImage = ISImage:new((self:getWidth() / 2) - 115, (self:getHeight() / 2) - 140, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonAImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonA
    ButtonSmallAImage = self.DJSoundboardOverlaySmallButtonAImage
    self.DJSoundboardOverlaySmallButtonAImage:setMouseOverText(getText("UI_DJBooth_StopLoop"))
    self.DJSoundboardOverlaySmallButtonAImage:initialise()
    self.DJSoundboardOverlaySmallButtonAImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonAImage)

    self.DJSoundboardOverlaySmallButtonBImage = ISImage:new((self:getWidth() / 2) - 65, (self:getHeight() / 2) - 140, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonBImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonB
    ButtonSmallBImage = self.DJSoundboardOverlaySmallButtonBImage
    self.DJSoundboardOverlaySmallButtonBImage:setMouseOverText(getText("UI_DJBooth_Loop1A"))
    self.DJSoundboardOverlaySmallButtonBImage:initialise()
    self.DJSoundboardOverlaySmallButtonBImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonBImage)

    self.DJSoundboardOverlaySmallButtonCImage = ISImage:new((self:getWidth() / 2) - 45, (self:getHeight() / 2) - 140, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonCImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonC
    ButtonSmallCImage = self.DJSoundboardOverlaySmallButtonCImage
    self.DJSoundboardOverlaySmallButtonCImage:setMouseOverText(getText("UI_DJBooth_Loop1B"))
    self.DJSoundboardOverlaySmallButtonCImage:initialise()
    self.DJSoundboardOverlaySmallButtonCImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonCImage)

    self.DJSoundboardOverlaySmallButtonDImage = ISImage:new((self:getWidth() / 2) - 25, (self:getHeight() / 2) - 140, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonDImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonD
    ButtonSmallDImage = self.DJSoundboardOverlaySmallButtonDImage
    self.DJSoundboardOverlaySmallButtonDImage:setMouseOverText(getText("UI_DJBooth_Loop1C"))
    self.DJSoundboardOverlaySmallButtonDImage:initialise()
    self.DJSoundboardOverlaySmallButtonDImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonDImage)

    self.DJSoundboardOverlaySmallButtonEImage = ISImage:new((self:getWidth() / 2) + 35, (self:getHeight() / 2) - 140, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonEImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonE
    ButtonSmallEImage = self.DJSoundboardOverlaySmallButtonEImage
    self.DJSoundboardOverlaySmallButtonEImage:setMouseOverText(getText("UI_DJBooth_Loop2A"))
    self.DJSoundboardOverlaySmallButtonEImage:initialise()
    self.DJSoundboardOverlaySmallButtonEImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonEImage)
    
    self.DJSoundboardOverlaySmallButtonFImage = ISImage:new((self:getWidth() / 2) + 55, (self:getHeight() / 2) - 140, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonFImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonF
    ButtonSmallFImage = self.DJSoundboardOverlaySmallButtonFImage
    self.DJSoundboardOverlaySmallButtonFImage:setMouseOverText(getText("UI_DJBooth_Loop2B"))
    self.DJSoundboardOverlaySmallButtonFImage:initialise()
    self.DJSoundboardOverlaySmallButtonFImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonFImage)
    
    self.DJSoundboardOverlaySmallButtonGImage = ISImage:new((self:getWidth() / 2) + 75, (self:getHeight() / 2) - 140, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonGImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonG
    ButtonSmallGImage = self.DJSoundboardOverlaySmallButtonGImage
    self.DJSoundboardOverlaySmallButtonGImage:setMouseOverText(getText("UI_DJBooth_Loop2C"))
    self.DJSoundboardOverlaySmallButtonGImage:initialise()
    self.DJSoundboardOverlaySmallButtonGImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonGImage)
    
    self.DJSoundboardOverlaySmallButtonHImage = ISImage:new((self:getWidth() / 2) + 95, (self:getHeight() / 2) - 140, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonHImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonH
    ButtonSmallHImage = self.DJSoundboardOverlaySmallButtonHImage
    self.DJSoundboardOverlaySmallButtonHImage:setMouseOverText(getText("UI_DJBooth_Loop2D"))
    self.DJSoundboardOverlaySmallButtonHImage:initialise()
    self.DJSoundboardOverlaySmallButtonHImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonHImage)
    
    self.DJSoundboardOverlaySmallButtonIImage = ISImage:new((self:getWidth() / 2) - 85, (self:getHeight() / 2) - 110, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonIImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonI
    ButtonSmallIImage = self.DJSoundboardOverlaySmallButtonIImage
    self.DJSoundboardOverlaySmallButtonIImage:setMouseOverText(getText("UI_DJBooth_Loop3A"))
    self.DJSoundboardOverlaySmallButtonIImage:initialise()
    self.DJSoundboardOverlaySmallButtonIImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonIImage)
    
    self.DJSoundboardOverlaySmallButtonJImage = ISImage:new((self:getWidth() / 2) - 65, (self:getHeight() / 2) - 110, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonJImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonJ
    ButtonSmallJImage = self.DJSoundboardOverlaySmallButtonJImage
    self.DJSoundboardOverlaySmallButtonJImage:setMouseOverText(getText("UI_DJBooth_Loop3B"))
    self.DJSoundboardOverlaySmallButtonJImage:initialise()
    self.DJSoundboardOverlaySmallButtonJImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonJImage)
    
    self.DJSoundboardOverlaySmallButtonKImage = ISImage:new((self:getWidth() / 2) - 45, (self:getHeight() / 2) - 110, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonKImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonK
    ButtonSmallKImage = self.DJSoundboardOverlaySmallButtonKImage
    self.DJSoundboardOverlaySmallButtonKImage:setMouseOverText(getText("UI_DJBooth_Loop3C"))
    self.DJSoundboardOverlaySmallButtonKImage:initialise()
    self.DJSoundboardOverlaySmallButtonKImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonKImage)
    
    self.DJSoundboardOverlaySmallButtonLImage = ISImage:new((self:getWidth() / 2) - 25, (self:getHeight() / 2) - 110, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonLImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonL
    ButtonSmallLImage = self.DJSoundboardOverlaySmallButtonLImage
    self.DJSoundboardOverlaySmallButtonLImage:setMouseOverText(getText("UI_DJBooth_Loop3D"))
    self.DJSoundboardOverlaySmallButtonLImage:initialise()
    self.DJSoundboardOverlaySmallButtonLImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonLImage)
    
    self.DJSoundboardOverlaySmallButtonMImage = ISImage:new((self:getWidth() / 2) + 35, (self:getHeight() / 2) - 110, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonMImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonM
    ButtonSmallMImage = self.DJSoundboardOverlaySmallButtonMImage
    self.DJSoundboardOverlaySmallButtonMImage:setMouseOverText(getText("UI_DJBooth_Loop4A"))
    self.DJSoundboardOverlaySmallButtonMImage:initialise()
    self.DJSoundboardOverlaySmallButtonMImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonMImage)
    
    self.DJSoundboardOverlaySmallButtonNImage = ISImage:new((self:getWidth() / 2) + 55, (self:getHeight() / 2) - 110, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonNImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonN
    ButtonSmallNImage = self.DJSoundboardOverlaySmallButtonNImage
    self.DJSoundboardOverlaySmallButtonNImage:setMouseOverText(getText("UI_DJBooth_Loop4B"))
    self.DJSoundboardOverlaySmallButtonNImage:initialise()
    self.DJSoundboardOverlaySmallButtonNImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonNImage)
    
    self.DJSoundboardOverlaySmallButtonOImage = ISImage:new((self:getWidth() / 2) + 75, (self:getHeight() / 2) - 110, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonOImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonO
    ButtonSmallOImage = self.DJSoundboardOverlaySmallButtonOImage
    self.DJSoundboardOverlaySmallButtonOImage:setMouseOverText(getText("UI_DJBooth_Loop4C"))
    self.DJSoundboardOverlaySmallButtonOImage:initialise()
    self.DJSoundboardOverlaySmallButtonOImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonOImage)
    
    self.DJSoundboardOverlaySmallButtonPImage = ISImage:new((self:getWidth() / 2) + 95, (self:getHeight() / 2) - 110, 12, 13, SmallButtonTexture)
    self.DJSoundboardOverlaySmallButtonPImage.onMouseUp = DJSoundboardOverlay.onMouseUpSmallButtonP
    ButtonSmallPImage = self.DJSoundboardOverlaySmallButtonPImage
    self.DJSoundboardOverlaySmallButtonPImage:setMouseOverText(getText("UI_DJBooth_Loop4D"))
    self.DJSoundboardOverlaySmallButtonPImage:initialise()
    self.DJSoundboardOverlaySmallButtonPImage:instantiate()
    self:addChild(self.DJSoundboardOverlaySmallButtonPImage)

------ BIG BUTTONS

    self.DJSoundboardOverlayBigButtonAImage = ISImage:new((self:getWidth() / 2) + 70, (self:getHeight() / 2) + 5, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButtonAImage.onMouseUp = DJSoundboardOverlay.onMouseUpBigButtonA
    ButtonBigAImage = self.DJSoundboardOverlayBigButtonAImage
    self.DJSoundboardOverlayBigButtonAImage:setMouseOverText(getText("UI_DJBooth_Rewind"))
    self.DJSoundboardOverlayBigButtonAImage:initialise()
    self.DJSoundboardOverlayBigButtonAImage:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButtonAImage)

    self.DJSoundboardOverlayBigButtonBImage = ISImage:new((self:getWidth() / 2) + 100, (self:getHeight() / 2) + 5, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButtonBImage.onMouseUp = DJSoundboardOverlay.onMouseUpBigButtonB
    ButtonBigBImage = self.DJSoundboardOverlayBigButtonBImage
    self.DJSoundboardOverlayBigButtonBImage:setMouseOverText(getText("UI_DJBooth_Woosh"))
    self.DJSoundboardOverlayBigButtonBImage:initialise()
    self.DJSoundboardOverlayBigButtonBImage:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButtonBImage)

    self.DJSoundboardOverlayBigButtonCImage = ISImage:new((self:getWidth() / 2) + 38, (self:getHeight() / 2) - 25, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButtonCImage.onMouseUp = DJSoundboardOverlay.onMouseUpBigButtonC
    ButtonBigCImage = self.DJSoundboardOverlayBigButtonCImage
    self.DJSoundboardOverlayBigButtonCImage:setMouseOverText(getText("UI_DJBooth_Impact"))
    self.DJSoundboardOverlayBigButtonCImage:initialise()
    self.DJSoundboardOverlayBigButtonCImage:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButtonCImage)

    self.DJSoundboardOverlayBigButtonDImage = ISImage:new((self:getWidth() / 2) + 68, (self:getHeight() / 2) - 25, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButtonDImage.onMouseUp = DJSoundboardOverlay.onMouseUpBigButtonD
    ButtonBigDImage = self.DJSoundboardOverlayBigButtonDImage
    self.DJSoundboardOverlayBigButtonDImage:setMouseOverText(getText("UI_DJBooth_Crowd"))
    self.DJSoundboardOverlayBigButtonDImage:initialise()
    self.DJSoundboardOverlayBigButtonDImage:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButtonDImage)

    self.DJSoundboardOverlayBigButtonEImage = ISImage:new((self:getWidth() / 2) + 98, (self:getHeight() / 2) - 25, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButtonEImage.onMouseUp = DJSoundboardOverlay.onMouseUpBigButtonE
    ButtonBigEImage = self.DJSoundboardOverlayBigButtonEImage
    self.DJSoundboardOverlayBigButtonEImage:setMouseOverText(getText("UI_DJBooth_War"))
    self.DJSoundboardOverlayBigButtonEImage:initialise()
    self.DJSoundboardOverlayBigButtonEImage:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButtonEImage)
    
    self.DJSoundboardOverlayBigButtonFImage = ISImage:new((self:getWidth() / 2) + 36, (self:getHeight() / 2) - 55, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButtonFImage.onMouseUp = DJSoundboardOverlay.onMouseUpBigButtonF
    ButtonBigFImage = self.DJSoundboardOverlayBigButtonFImage
    self.DJSoundboardOverlayBigButtonFImage:setMouseOverText(getText("UI_DJBooth_Synth"))
    self.DJSoundboardOverlayBigButtonFImage:initialise()
    self.DJSoundboardOverlayBigButtonFImage:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButtonFImage)
    
    self.DJSoundboardOverlayBigButtonGImage = ISImage:new((self:getWidth() / 2) + 66, (self:getHeight() / 2) - 55, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButtonGImage.onMouseUp = DJSoundboardOverlay.onMouseUpBigButtonG
    ButtonBigGImage = self.DJSoundboardOverlayBigButtonGImage
    self.DJSoundboardOverlayBigButtonGImage:setMouseOverText(getText("UI_DJBooth_Airhorn"))
    self.DJSoundboardOverlayBigButtonGImage:initialise()
    self.DJSoundboardOverlayBigButtonGImage:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButtonGImage)
    
    self.DJSoundboardOverlayBigButtonHImage = ISImage:new((self:getWidth() / 2) + 96, (self:getHeight() / 2) - 55, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButtonHImage.onMouseUp = DJSoundboardOverlay.onMouseUpBigButtonH
    ButtonBigHImage = self.DJSoundboardOverlayBigButtonHImage
    self.DJSoundboardOverlayBigButtonHImage:setMouseOverText(getText("UI_DJBooth_Sirens"))
    self.DJSoundboardOverlayBigButtonHImage:initialise()
    self.DJSoundboardOverlayBigButtonHImage:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButtonHImage)

    --BIG BUTTON LEFT
    self.DJSoundboardOverlayBigButton1Image = ISImage:new((self:getWidth() / 2) - 100, (self:getHeight() / 2) + 5, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButton1Image.onMouseUp = DJSoundboardOverlay.onMouseUpBigButton1
    self.DJSoundboardOverlayBigButton1Image.onRightMouseUp = DJSoundboardOverlay.onMouseUpSwitchBA
    ButtonBig1Image = self.DJSoundboardOverlayBigButton1Image
    self.DJSoundboardOverlayBigButton1Image:setMouseOverText(getText("UI_DJBooth_ElecKickdrum"))
    self.DJSoundboardOverlayBigButton1Image:initialise()
    self.DJSoundboardOverlayBigButton1Image:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButton1Image)

    self.DJSoundboardOverlayBigButton2Image = ISImage:new((self:getWidth() / 2) - 130, (self:getHeight() / 2) + 5, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButton2Image.onMouseUp = DJSoundboardOverlay.onMouseUpBigButton2
    self.DJSoundboardOverlayBigButton2Image.onRightMouseUp = DJSoundboardOverlay.onMouseUpSwitchBA
    ButtonBig2Image = self.DJSoundboardOverlayBigButton2Image
    self.DJSoundboardOverlayBigButton2Image:setMouseOverText(getText("UI_DJBooth_Kickdrum"))
    self.DJSoundboardOverlayBigButton2Image:initialise()
    self.DJSoundboardOverlayBigButton2Image:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButton2Image)

    self.DJSoundboardOverlayBigButton3Image = ISImage:new((self:getWidth() / 2) - 68, (self:getHeight() / 2) - 25, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButton3Image.onMouseUp = DJSoundboardOverlay.onMouseUpBigButton3
    self.DJSoundboardOverlayBigButton3Image.onRightMouseUp = DJSoundboardOverlay.onMouseUpSwitchBA
    ButtonBig3Image = self.DJSoundboardOverlayBigButton3Image
    self.DJSoundboardOverlayBigButton3Image:setMouseOverText(getText("UI_DJBooth_SafariKick"))
    self.DJSoundboardOverlayBigButton3Image:initialise()
    self.DJSoundboardOverlayBigButton3Image:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButton3Image)
    
    self.DJSoundboardOverlayBigButton4Image = ISImage:new((self:getWidth() / 2) - 98, (self:getHeight() / 2) - 25, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButton4Image.onMouseUp = DJSoundboardOverlay.onMouseUpBigButton4
    self.DJSoundboardOverlayBigButton4Image.onRightMouseUp = DJSoundboardOverlay.onMouseUpSwitchBA
    ButtonBig4Image = self.DJSoundboardOverlayBigButton4Image
    self.DJSoundboardOverlayBigButton4Image:setMouseOverText(getText("UI_DJBooth_ElecSnareDrum"))
    self.DJSoundboardOverlayBigButton4Image:initialise()
    self.DJSoundboardOverlayBigButton4Image:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButton4Image)
    
    self.DJSoundboardOverlayBigButton5Image = ISImage:new((self:getWidth() / 2) - 128, (self:getHeight() / 2) - 25, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButton5Image.onMouseUp = DJSoundboardOverlay.onMouseUpBigButton5
    self.DJSoundboardOverlayBigButton5Image.onRightMouseUp = DJSoundboardOverlay.onMouseUpSwitchBA
    ButtonBig5Image = self.DJSoundboardOverlayBigButton5Image
    self.DJSoundboardOverlayBigButton5Image:setMouseOverText(getText("UI_DJBooth_Snare"))
    self.DJSoundboardOverlayBigButton5Image:initialise()
    self.DJSoundboardOverlayBigButton5Image:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButton5Image)
    
    self.DJSoundboardOverlayBigButton6Image = ISImage:new((self:getWidth() / 2) - 66, (self:getHeight() / 2) - 55, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButton6Image.onMouseUp = DJSoundboardOverlay.onMouseUpBigButton6
    self.DJSoundboardOverlayBigButton6Image.onRightMouseUp = DJSoundboardOverlay.onMouseUpSwitchBA
    ButtonBig6Image = self.DJSoundboardOverlayBigButton6Image
    self.DJSoundboardOverlayBigButton6Image:setMouseOverText(getText("UI_DJBooth_Snap"))
    self.DJSoundboardOverlayBigButton6Image:initialise()
    self.DJSoundboardOverlayBigButton6Image:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButton6Image)
    
    self.DJSoundboardOverlayBigButton7Image = ISImage:new((self:getWidth() / 2) - 96, (self:getHeight() / 2) - 55, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButton7Image.onMouseUp = DJSoundboardOverlay.onMouseUpBigButton7
    self.DJSoundboardOverlayBigButton7Image.onRightMouseUp = DJSoundboardOverlay.onMouseUpSwitchBA
    ButtonBig7Image = self.DJSoundboardOverlayBigButton7Image
    self.DJSoundboardOverlayBigButton7Image:setMouseOverText(getText("UI_DJBooth_Clap"))
    self.DJSoundboardOverlayBigButton7Image:initialise()
    self.DJSoundboardOverlayBigButton7Image:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButton7Image)
    
    self.DJSoundboardOverlayBigButton8Image = ISImage:new((self:getWidth() / 2) - 126, (self:getHeight() / 2) - 55, 25, 25, BigButtonTexture)
    self.DJSoundboardOverlayBigButton8Image.onMouseUp = DJSoundboardOverlay.onMouseUpBigButton8
    self.DJSoundboardOverlayBigButton8Image.onRightMouseUp = DJSoundboardOverlay.onMouseUpSwitchBA
    ButtonBig8Image = self.DJSoundboardOverlayBigButton8Image
    self.DJSoundboardOverlayBigButton8Image:setMouseOverText(getText("UI_DJBooth_OpenHat"))
    self.DJSoundboardOverlayBigButton8Image:initialise()
    self.DJSoundboardOverlayBigButton8Image:instantiate()
    self:addChild(self.DJSoundboardOverlayBigButton8Image)

    --
    self.ok = ISButton:new((self:getWidth() / 2) - 19, self:getHeight() - 34, 30, 30, getText("UI_DJBooth_Close"), self, DJSoundboardOverlay.onClick);
    self.ok.internal = "Close";
    self.ok:initialise();
    self.ok:instantiate();
    self.ok.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.ok);

    --self:insertNewLineOfButtons(self.button1p, self.button2p, self.button3p, self.button4p)
    self:insertNewLineOfButtons(self.ok)
    
    LSKScheduler.register("dj-overlay-main", LSKScheduler.LANES.FAST, DJBoothEventListener)
    LSKScheduler.register("dj-overlay-recorder", LSKScheduler.LANES.FAST, DJBoothEventListenerRecorder)
    LSKScheduler.register("dj-overlay-player", LSKScheduler.LANES.FAST, DJBoothEventListenerPlayer)
end

function DJSoundboardOverlay:updateStatus()

     local specificPlayer = getSpecificPlayer(0)

    --RGB

    if specificPlayer:getModData().DJBoothBigButtonRGB == 0 then
        BigButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonBigPressed1.png")
        SmallButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonSmallPressed1.png")
        specificPlayer:getModData().DJBoothBigButtonRGB = 1
    elseif specificPlayer:getModData().DJBoothBigButtonRGB == 1 then
        BigButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonBigPressed2.png")
        SmallButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonSmallPressed2.png")
        specificPlayer:getModData().DJBoothBigButtonRGB = 2
    elseif specificPlayer:getModData().DJBoothBigButtonRGB == 2 then
        BigButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonBigPressed3.png")
        SmallButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonSmallPressed3.png")
        specificPlayer:getModData().DJBoothBigButtonRGB = 3
    elseif specificPlayer:getModData().DJBoothBigButtonRGB == 3 then
        BigButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonBigPressed4.png")
        SmallButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonSmallPressed4.png")
        specificPlayer:getModData().DJBoothBigButtonRGB = 4
    elseif specificPlayer:getModData().DJBoothBigButtonRGB == 4 then
        BigButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonBigPressed5.png")
        SmallButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonSmallPressed5.png")
        specificPlayer:getModData().DJBoothBigButtonRGB = 5
    elseif specificPlayer:getModData().DJBoothBigButtonRGB == 5 then
        BigButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonBigPressed6.png")
        SmallButtonPressed = getTexture("media/textures/DJBooth_OverlayButtonSmallPressed6.png")
        specificPlayer:getModData().DJBoothBigButtonRGB = 0
    end

    --VYNIL A
    if specificPlayer:getModData().VynilAScratched == true then
        if specificPlayer:getModData().VynilAScratchedTimes == 0 then
        VynilTextureA = getTexture("media/textures/DJBooth_VynilA1.png")
        elseif  specificPlayer:getModData().VynilAScratchedTimes == 1 then
        VynilTextureA = getTexture("media/textures/DJBooth_VynilA2.png")
        end
        VynilAImage.texture = VynilTextureA
        specificPlayer:getModData().VynilAScratched = false
    end
    --VYNIL B
    if specificPlayer:getModData().VynilBScratched == true then
        if specificPlayer:getModData().VynilBScratchedTimes == 0 then
        VynilTextureB = getTexture("media/textures/DJBooth_VynilB1.png")
        elseif  specificPlayer:getModData().VynilBScratchedTimes == 1 then
        VynilTextureB = getTexture("media/textures/DJBooth_VynilB2.png")
        end
        VynilBImage.texture = VynilTextureB
        specificPlayer:getModData().VynilBScratched = false
    end

    ---------------- SMALL BUTTONS
    --BUTTON CUSTOM LOOP
    if specificPlayer:getModData().DJBoothCustomLoopPlaying == true and ButtonSmallCustomLoopImage.texture == SmallButtonTexture then
        ButtonSmallCustomLoopImage.texture = SmallButtonPressed
    end
    --BUTTON A
    if specificPlayer:getModData().DJBoothSmallButtonAPressed == true then
        ButtonSmallAImage.texture = SmallButtonPressed
        ButtonSmallBImage.texture = SmallButtonTexture
        ButtonSmallCImage.texture = SmallButtonTexture
        ButtonSmallDImage.texture = SmallButtonTexture
        ButtonSmallEImage.texture = SmallButtonTexture
        ButtonSmallFImage.texture = SmallButtonTexture
        ButtonSmallGImage.texture = SmallButtonTexture
        ButtonSmallHImage.texture = SmallButtonTexture
        ButtonSmallIImage.texture = SmallButtonTexture
        ButtonSmallJImage.texture = SmallButtonTexture
        ButtonSmallKImage.texture = SmallButtonTexture
        ButtonSmallLImage.texture = SmallButtonTexture
        ButtonSmallMImage.texture = SmallButtonTexture
        ButtonSmallNImage.texture = SmallButtonTexture
        ButtonSmallOImage.texture = SmallButtonTexture
        ButtonSmallPImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonAPressed = false
    end
    --BUTTON B
    if specificPlayer:getModData().DJBoothSmallButtonBPressed == true then
        ButtonSmallBImage.texture = SmallButtonPressed
        ButtonSmallAImage.texture = SmallButtonTexture
        ButtonSmallCImage.texture = SmallButtonTexture
        ButtonSmallDImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonBPressed = false
    end
    --BUTTON C
    if specificPlayer:getModData().DJBoothSmallButtonCPressed == true then
        ButtonSmallCImage.texture = SmallButtonPressed
        ButtonSmallBImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        ButtonSmallDImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonCPressed = false
    end
    --BUTTON D
    if specificPlayer:getModData().DJBoothSmallButtonDPressed == true then
        ButtonSmallDImage.texture = SmallButtonPressed
        ButtonSmallBImage.texture = SmallButtonTexture
        ButtonSmallCImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonDPressed = false
    end
    --BUTTON E
    if specificPlayer:getModData().DJBoothSmallButtonEPressed == true then
        ButtonSmallEImage.texture = SmallButtonPressed
        ButtonSmallFImage.texture = SmallButtonTexture
        ButtonSmallGImage.texture = SmallButtonTexture
        ButtonSmallHImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonEPressed = false
    end
    --BUTTON F
    if specificPlayer:getModData().DJBoothSmallButtonFPressed == true then
        ButtonSmallFImage.texture = SmallButtonPressed
        ButtonSmallEImage.texture = SmallButtonTexture
        ButtonSmallGImage.texture = SmallButtonTexture
        ButtonSmallHImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonFPressed = false
    end
    --BUTTON G
    if specificPlayer:getModData().DJBoothSmallButtonGPressed == true then
        ButtonSmallGImage.texture = SmallButtonPressed
        ButtonSmallEImage.texture = SmallButtonTexture
        ButtonSmallFImage.texture = SmallButtonTexture
        ButtonSmallHImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonGPressed = false
    end
    --BUTTON H
    if specificPlayer:getModData().DJBoothSmallButtonHPressed == true then
        ButtonSmallHImage.texture = SmallButtonPressed
        ButtonSmallEImage.texture = SmallButtonTexture
        ButtonSmallFImage.texture = SmallButtonTexture
        ButtonSmallGImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonHPressed = false
    end
    --BUTTON I
    if specificPlayer:getModData().DJBoothSmallButtonIPressed == true then
        ButtonSmallIImage.texture = SmallButtonPressed
        ButtonSmallJImage.texture = SmallButtonTexture
        ButtonSmallKImage.texture = SmallButtonTexture
        ButtonSmallLImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonIPressed = false
    end
    --BUTTON J
    if specificPlayer:getModData().DJBoothSmallButtonJPressed == true then
        ButtonSmallJImage.texture = SmallButtonPressed
        ButtonSmallIImage.texture = SmallButtonTexture
        ButtonSmallKImage.texture = SmallButtonTexture
        ButtonSmallLImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonJPressed = false
    end
    --BUTTON K
    if specificPlayer:getModData().DJBoothSmallButtonKPressed == true then
        ButtonSmallKImage.texture = SmallButtonPressed
        ButtonSmallIImage.texture = SmallButtonTexture
        ButtonSmallJImage.texture = SmallButtonTexture
        ButtonSmallLImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonKPressed = false
    end
    --BUTTON L
    if specificPlayer:getModData().DJBoothSmallButtonLPressed == true then
        ButtonSmallLImage.texture = SmallButtonPressed
        ButtonSmallIImage.texture = SmallButtonTexture
        ButtonSmallJImage.texture = SmallButtonTexture
        ButtonSmallKImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonLPressed = false
    end
    --BUTTON M
    if specificPlayer:getModData().DJBoothSmallButtonMPressed == true then
        ButtonSmallMImage.texture = SmallButtonPressed
        ButtonSmallNImage.texture = SmallButtonTexture
        ButtonSmallOImage.texture = SmallButtonTexture
        ButtonSmallPImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonMPressed = false
    end
    --BUTTON N
    if specificPlayer:getModData().DJBoothSmallButtonNPressed == true then
        ButtonSmallNImage.texture = SmallButtonPressed
        ButtonSmallMImage.texture = SmallButtonTexture
        ButtonSmallOImage.texture = SmallButtonTexture
        ButtonSmallPImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonNPressed = false
    end
    --BUTTON O
    if specificPlayer:getModData().DJBoothSmallButtonOPressed == true then
        ButtonSmallOImage.texture = SmallButtonPressed
        ButtonSmallMImage.texture = SmallButtonTexture
        ButtonSmallNImage.texture = SmallButtonTexture
        ButtonSmallPImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonOPressed = false
    end
    --BUTTON P
    if specificPlayer:getModData().DJBoothSmallButtonPPressed == true then
        ButtonSmallPImage.texture = SmallButtonPressed
        ButtonSmallMImage.texture = SmallButtonTexture
        ButtonSmallNImage.texture = SmallButtonTexture
        ButtonSmallOImage.texture = SmallButtonTexture
        ButtonSmallAImage.texture = SmallButtonTexture
        specificPlayer:getModData().DJBoothSmallButtonPPressed = false
    end
    ---------------- BIG BUTTONS
    --BUTTON A
    if specificPlayer:getModData().DJBoothBigButtonAPressed == true then
        ButtonBigAImage.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButtonAPressed = false
    end

    --BUTTON B
    if specificPlayer:getModData().DJBoothBigButtonBPressed == true then
        ButtonBigBImage.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButtonBPressed = false
    end
    
    --BUTTON C
    if specificPlayer:getModData().DJBoothBigButtonCPressed == true then
        ButtonBigCImage.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButtonCPressed = false
    end
    
    --BUTTON D
    if specificPlayer:getModData().DJBoothBigButtonDPressed == true then
        ButtonBigDImage.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButtonDPressed = false
    end
    
    --BUTTON E
    if specificPlayer:getModData().DJBoothBigButtonEPressed == true then
        ButtonBigEImage.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButtonEPressed = false
    end
    
    --BUTTON F
    if specificPlayer:getModData().DJBoothBigButtonFPressed == true then
        ButtonBigFImage.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButtonFPressed = false
    end
    
    --BUTTON G
    if specificPlayer:getModData().DJBoothBigButtonGPressed == true then
        ButtonBigGImage.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButtonGPressed = false
    end
    
    --BUTTON H
    if specificPlayer:getModData().DJBoothBigButtonHPressed == true then
        ButtonBigHImage.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButtonHPressed = false
    end

    --BUTTON 1
    if specificPlayer:getModData().DJBoothBigButton1Pressed == true then
        ButtonBig1Image.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButton1Pressed = false
    end

    --BUTTON 2
    if specificPlayer:getModData().DJBoothBigButton2Pressed == true then
        ButtonBig2Image.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButton2Pressed = false
    end

    --BUTTON 3
    if specificPlayer:getModData().DJBoothBigButton3Pressed == true then
        ButtonBig3Image.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButton3Pressed = false
    end

    --BUTTON 4
    if specificPlayer:getModData().DJBoothBigButton4Pressed == true then
        ButtonBig4Image.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButton4Pressed = false
    end

    --BUTTON 5
    if specificPlayer:getModData().DJBoothBigButton5Pressed == true then
        ButtonBig5Image.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButton5Pressed = false
    end

    --BUTTON 6
    if specificPlayer:getModData().DJBoothBigButton6Pressed == true then
        ButtonBig6Image.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButton6Pressed = false
    end

    --BUTTON 7
    if specificPlayer:getModData().DJBoothBigButton7Pressed == true then
        ButtonBig7Image.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButton7Pressed = false
    end

    --BUTTON 8
    if specificPlayer:getModData().DJBoothBigButton8Pressed == true then
        ButtonBig8Image.texture = BigButtonPressed
        specificPlayer:getModData().DJBoothBigButton8Pressed = false
    end


end

function DJSoundboardOverlay:close()

    local specificPlayer = getSpecificPlayer(0)
    --specificPlayer:getModData().DJBoothBigButtonRGB = 0
    specificPlayer:getModData().DJBoothOverlayPanel = false
    
    specificPlayer:getModData().DJBoothSwitchAPressed = false
    specificPlayer:getModData().DJBoothSwitchBPressed = false
    specificPlayer:getModData().DJBoothSwitchCPressed = false
    specificPlayer:getModData().DJBoothSwitchDPressed = false
    specificPlayer:getModData().DJBoothSwitchBAPressed = false
    specificPlayer:getModData().DJBoothCustomLoopPlaying = false
    specificPlayer:getModData().DJBoothCustomLoop = false
    specificPlayer:getModData().DJBoothCustomLoopActive = 0

    UIManager.setShowPausedMessage(true);
    self:setVisible(false);
    self:removeFromUIManager();
    if UIManager.getSpeedControls() then
        UIManager.getSpeedControls():SetCurrentGameSpeed(1);
    end

end

function DJSoundboardOverlay:destroy()
    local specificPlayer = getSpecificPlayer(0)
    --specificPlayer:getModData().DJBoothBigButtonRGB = 0
    specificPlayer:getModData().DJBoothOverlayPanel = false
    
    specificPlayer:getModData().DJBoothSwitchAPressed = false
    specificPlayer:getModData().DJBoothSwitchBPressed = false
    specificPlayer:getModData().DJBoothSwitchCPressed = false
    specificPlayer:getModData().DJBoothSwitchDPressed = false
    specificPlayer:getModData().DJBoothSwitchBAPressed = false
    specificPlayer:getModData().DJBoothCustomLoopPlaying = false
    specificPlayer:getModData().DJBoothCustomLoop = false
    specificPlayer:getModData().DJBoothCustomLoopActive = 0

    UIManager.setShowPausedMessage(true);
    self:setVisible(false);
    self:removeFromUIManager();
    if UIManager.getSpeedControls() then
        UIManager.getSpeedControls():SetCurrentGameSpeed(1);
    end

end



function DJSoundboardOverlay:onClick(button)
    local specificPlayer = getSpecificPlayer(0)

    if button.internal == "Close" then
        self:destroy();
        if JoypadState.players[self.player+1] then
            setJoypadFocus(self.player, nil)
        end
    else

    end
    if specificPlayer:getModData().DJNotFailstate == true then
        if button.internal == "RIGHTLEFT" then    
            specificPlayer:getModData().DJKEYLEFTRIGHT = true
        end

        if button.internal == "UP" then    
            if specificPlayer:getModData().DJKEY == 4 then
            specificPlayer:getModData().DJKEYUP = true
            elseif specificPlayer:getModData().DJKEY == 1 and specificPlayer:getPerkLevel(Perks.Music) >= 3 then
            specificPlayer:getModData().DJKEYUP = true
            elseif specificPlayer:getModData().DJKEY >= 1 and specificPlayer:getPerkLevel(Perks.Music) >= 6 then
            specificPlayer:getModData().DJKEYUP = true
            else
            specificPlayer:getModData().DJKEYLEFTRIGHT = true
            end
        end
    
        if button.internal == "DOWN" then    
            specificPlayer:getModData().DJKEYDOWN = true
        end
    end
end

function DJSoundboardOverlay:prerender()
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

end

function DJSoundboardOverlay:render()

end

local function resetSwitchLightIndicatorTex(parent)
    for k, v in pairs(parent.switchLight) do
        if not v.active then
            v.light.texture = SmallSwitchIndicatorTexture
        end
    end
end

function DJSoundboardOverlay:update()
    if self.switchLightDelay > 0 then
        self.switchLightDelay = self.switchLightDelay-1
        if self.switchLightDelay <= 0 then
            resetSwitchLightIndicatorTex(self)
        end
    end
    ISPanelJoypad.update(self)
  
end

function DJSoundboardOverlay:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self.joypadIndexY = 1
    self.joypadIndex = 1
    self.joypadButtons = self.joypadButtonsY[self.joypadIndexY]
    self.joypadButtons[self.joypadIndex]:setJoypadFocused(true)
end

function DJSoundboardOverlay:onJoypadDown(button)
    ISPanelJoypad.onJoypadDown(self, button)
    if button == Joypad.BButton then
        self:onClick(self.ok)
    end
end

local function getDFMLight(object)
    local hasDF
    for x = object:getX()-8,object:getX()+8 do
        for y = object:getY()-8,object:getY()+8 do
            local square = getCell():getGridSquare(x,y,object:getZ());
            if square then
                for i = 0,square:getObjects():size()-1 do
                    local newObject = square:getObjects():get(i);
                    if newObject and instanceof(newObject, "IsoObject") then
                        if getCustomName(newObject, "Disco Floor") and newObject:getModData().IsMainDF then
                            hasDF = true
                            break
                        end
                    end
                end
            end
            if hasDF then break; end
        end
        if hasDF then break; end
    end
    return hasDF
end

function DJSoundboardOverlay:new(player, DJbooth)
    local x = 0
    local y = 0
    local width = 860
    local height = 320
    local o = ISPanelJoypad:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    local playerObj = player and getSpecificPlayer(player) or nil
    o.character = playerObj;
    o.name = nil;
    o.backgroundColor = {r=0, g=0, b=0, a=0.1};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    if y == 0 then
        o.y = getPlayerScreenTop(player) + (getPlayerScreenHeight(player) - height) / 2 + 420
        o:setY(o.y)
    end
    if x == 0 then
        o.x = getPlayerScreenLeft(player) + (getPlayerScreenWidth(player) - width) / 2
        o:setX(o.x)
    end
    o.width = width;
    o.height = height;
    o.anchorLeft = true;
    o.anchorRight = true;
    o.anchorTop = true;
    o.anchorBottom = true;
    o.target = target;
    o.onclick = onclick;
    o.player = player;
    o.djbooth = DJbooth
    o.djbooth:getModData().LightStyle = "None"
    --o.djbooth:transmitModData()
    sendClientCommand("LSK", "ModifyObjData", {{o.djbooth:getX(),o.djbooth:getY(),o.djbooth:getZ(),o.djbooth:getSprite():getName()}, false, o.djbooth:getModData()})
    o.playerX = getPlayer():getX()
    o.playerY = getPlayer():getY()
    o.DJSoundboardTexture = getTexture("DJBooth_Overlay0.png")
    o.switchLight = {a=false,b=false,c=false,d=false,e=false,f=false}
    o.switchLightTex = {onL="media/textures/DJBooth_SwitchCOn.png",offL="media/textures/DJBooth_SwitchCOff.png",onR="media/textures/DJBooth_SwitchDOn.png",offR="media/textures/DJBooth_SwitchDOff.png"}
    o.switchLightDelay = 0
    o.switchLightInteract = false
    if getDFMLight(o.djbooth) then o.switchLightInteract = true; end
    o:noBackground()
    o.new = new;
    return o;
end
