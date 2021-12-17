--Variables to check the status of the configuration/Variables para comprobar el estado de la configuración/Переменные для проверки статуса конфигурации
local checkStatusCrouched = Config.statusCrouched
local checkStatusRagdolling = Config.statusRagdolling
local checkStatusCrossArms = Config.statusCrossArms
local checkStatusHandsUp = Config.statusHandsUp
local checkStatusFingerPoint = Config.statusFingerPoint
local checkStatusKeyR = Config.statusDisableKeyR

--Crouched/Agacharse/сгибать
Citizen.CreateThread( function()
    while(checkStatusCrouched == true)do
        local crouched = false
        while true do 
            Citizen.Wait( 1 )
            local ped = PlayerPedId()
            if ( DoesEntityExist( ped ) and not IsEntityDead( ped ) ) then 
                DisableControlAction( 0, Config.crouched, true ) -- INPUT_DUCK  
    
                if ( not IsPauseMenuActive() ) then 
                    if ( IsDisabledControlJustPressed( 0, Config.crouched ) ) then 
                        RequestAnimSet( "move_ped_crouched" )
    
                        while ( not HasAnimSetLoaded( "move_ped_crouched" ) ) do 
                            Citizen.Wait( 100 )
                        end 
    
                        if ( crouched == true ) then 
                            ResetPedMovementClipset( ped, 0 )
                            crouched = false 
                        elseif ( crouched == false ) then
                            SetPedMovementClipset( ped, "move_ped_crouched", 0.25 )
                            crouched = true 
                        end 
                    end
                end 
            end 
        end
    end
end )

--Ragdolling/Desmayarse/Слабый
Citizen.CreateThread(function()
    while(checkStatusRagdolling== true)do
        local isRagdolling = 0
        while true do
            Citizen.Wait(0)
            if IsControlJustReleased(1, Config.fainting) then
                isRagdolling = (isRagdolling + 1) % 2
           end
            if isRagdolling == 1 then
               SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
            end
        end
    end
end)

--Crossed arms/Brazos Cruzados/Скрещенные руки
Citizen.CreateThread(function()
    while(checkStatusCrossArms == true)do
        local dict = "amb@world_human_hang_out_street@female_arms_crossed@base"
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(100)
        end
        local crossArms = false
        while true do
            Citizen.Wait(0)
            if IsControlJustPressed(1, Config.crossArms) then
                if not crossArms then
                    TaskPlayAnim(PlayerPedId(), dict, "base", 8.0, 8.0, -1, 50, 0, false, false, false)
                    crossArms = true
                else
                    crossArms = false
                    ClearPedTasks(PlayerPedId())
                end
            end
        end
    end
end)

--Hands Up /Manos arriba/Руки вверх
Citizen.CreateThread(function()
    while(checkStatusHandsUp == true)do
        local dict = "missminuteman_1ig_2"
        
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(100)
        end
        local handsup = false
        while true do
            Citizen.Wait(0)
            if IsControlJustPressed(1, Config.handsup) then --Start holding X
                if not handsup then
                    TaskPlayAnim(PlayerPedId(), dict, "handsup_enter", 8.0, 8.0, -1, 50, 0, false, false, false)
                    handsup = true
                else
                    handsup = false
                    ClearPedTasks(PlayerPedId())
                end
            end
        end
    end
end)

--Point/Señalar/Точка
local mp_pointing = false
local keyPressed = false

local function startPointing()
    local ped = PlayerPedId()
    RequestAnimDict("anim@mp_point")

    while not HasAnimDictLoaded("anim@mp_point") do
        Wait(0)
    end

    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
    SetPedConfigFlag(ped, 36, 1)
    Citizen.InvokeNative(0x2D537BA194896636, ped, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
    RemoveAnimDict("anim@mp_point")
end
local function stopPointing()
    local ped = PlayerPedId()
    Citizen.InvokeNative(0xD01015C7316AE176, ped, "Stop")

    if not IsPedInjured(ped) then
        ClearPedSecondaryTask(ped)
    end

    if not IsPedInAnyVehicle(ped, 1) then
        SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
    end
    SetPedConfigFlag(ped, 36, 0)
    ClearPedSecondaryTask(PlayerPedId())
end

local once = true
local oldval = false
local oldvalped = false

Citizen.CreateThread(function()
    while (checkStatusFingerPoint == true) do
        while true do
            Wait(0)
            if once then
                once = false
            end

            if not keyPressed then
                if IsControlPressed(0, Config.point) and not mp_pointing and IsPedOnFoot(PlayerPedId()) then
                    Wait(200)
                    if not IsControlPressed(0, Config.point) then
                        keyPressed = true
                        startPointing()
                        mp_pointing = true
                    else
                        keyPressed = true
                        while IsControlPressed(0, Config.point) do
                            Wait(50)
                        end
                    end
                elseif (IsControlPressed(0, Config.point) and mp_pointing) or (not IsPedOnFoot(PlayerPedId()) and mp_pointing) then
                    keyPressed = true
                    mp_pointing = false
                    stopPointing()
                end
            end

            if keyPressed then
                if not IsControlPressed(0, Config.point) then
                    keyPressed = false
                end
            end

            if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) and not mp_pointing then
                stopPointing()
            end

            if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) then
                if not IsPedOnFoot(PlayerPedId()) then
                    stopPointing()
                else
                    local ped = PlayerPedId()
                    local camPitch = GetGameplayCamRelativePitch()

                    if camPitch < -70.0 then
                        camPitch = -70.0
                    elseif camPitch > 42.0 then
                        camPitch = 42.0
                    end
                    camPitch = (camPitch + 70.0) / 112.0
    
                    local camHeading = GetGameplayCamRelativeHeading()
                    local cosCamHeading = Cos(camHeading)
                    local sinCamHeading = Sin(camHeading)
                    if camHeading < -180.0 then
                        camHeading = -180.0
                    elseif camHeading > 180.0 then
                        camHeading = 180.0
                    end
                    camHeading = (camHeading + 180.0) / 360.0
    
                    local blocked = 0
                    local nn = 0
    
                    local coords = GetOffsetFromEntityInWorldCoords(ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
                    local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7);
                    nn,blocked,coords,coords = GetRaycastResult(ray)
    
                    Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Pitch", camPitch)
                    Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Heading", camHeading * -1.0 + 1.0)
                    Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isBlocked", blocked)
                    Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isFirstPerson", Citizen.InvokeNative(0xEE778F8C7E1142E2, Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)
                end
            end
        end
    end
end)

--DisableKeyR/Anticulatazo/Отключить клавишу R
Citizen.CreateThread(function()
    while (checkStatusKeyR == true) do
        while true do
            Citizen.Wait(0)
            DisableControlAction(1, 140, true)
            if IsPlayerFreeAiming(PlayerId()) then
                DisableControlAction(1, 141, true)
                DisableControlAction(1, 142, true)
            end
        end
    end    
end)