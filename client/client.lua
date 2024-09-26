PHOTOMODE = {}
PHOTOMODE.IsActive = false
PHOTOMODE.CameraName = "photoModeCam"
PHOTOMODE.FOV = 0

function PHOTOMODE.Start()
    local gameplayCamPos = GetFinalRenderedCamCoord()
    local gameplayCamRot = GetGameplayCamRot(2)
    local gameplayCamFov = GetGameplayCamFov()
    PHOTOMODE.FOV = gameplayCamFov

    Cam.Create(PHOTOMODE.CameraName)
    Cam.SetPosition(PHOTOMODE.CameraName, gameplayCamPos)
    Cam.SetRotation(PHOTOMODE.CameraName, gameplayCamRot, 2)
    Cam.SetFov(PHOTOMODE.CameraName, gameplayCamFov)
    Cam.SetActive(PHOTOMODE.CameraName, true, false, 0)
    SetTimeScale(0.0)
    
    PHOTOMODE.IsActive = true
    Citizen.CreateThread(function()
        while PHOTOMODE.IsActive do
            PHOTOMODE.BlockMouvementsControls()
            local pPed = PlayerPedId()
            Cam.HandleSmartDof(PHOTOMODE.CameraName, pPed, 1.0)
    
            if IsControlJustPressed(0, 241) then
                local scaleFactor = gameplayCamFov / 20.0
                gameplayCamFov = math.max(gameplayCamFov - scaleFactor, 1.0)
                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            elseif IsControlJustPressed(0, 242) then
                local scaleFactor = gameplayCamFov / 20.0
                gameplayCamFov = math.min(gameplayCamFov + scaleFactor, 120.0)
                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            end
    
            PHOTOMODE.FOV = Utils.CalculateNextScalablePosition(gameplayCamFov, PHOTOMODE.FOV, 0.1)
            Cam.SetFov(PHOTOMODE.CameraName, PHOTOMODE.FOV)
    
            local mouseX = GetControlNormal(0, 1)
            local mouseY = GetControlNormal(0, 2)
    
            local currentFov = GetCamFov(Cam.Cache[PHOTOMODE.CameraName])
    
            local scaleFactor = currentFov / 40.0
    
            if IsDisabledControlPressed(0, 24) then
                local camPos = GetCamCoord(Cam.Cache[PHOTOMODE.CameraName])
                local camRot = GetCamRot(Cam.Cache[PHOTOMODE.CameraName], 2)
                local forwardVector = RotationToDirection(camRot)
                local rightVector = RotationToDirection(vector3(camRot.x, camRot.y, camRot.z + 90.0))
                camPos = camPos + forwardVector * (-mouseY * 0.1) + rightVector * (mouseX * 0.1)
                Cam.SetPosition(PHOTOMODE.CameraName, camPos)
            else
                local camRot = GetCamRot(Cam.Cache[PHOTOMODE.CameraName], 2)
                camRot = vector3(camRot.x - mouseY * 5.0 * scaleFactor, camRot.y, camRot.z - mouseX * 5.0 * scaleFactor)
                Cam.SetRotation(PHOTOMODE.CameraName, camRot, 2)
            end
    
            Wait(1)
        end
        SetTimeScale(1.0)
        PHOTOMODE.IsActive = false
    end)
end

function RotationToDirection(rotation)
    local radZ = math.rad(rotation.z)
    local radX = math.rad(rotation.x)
    local num = math.abs(math.cos(radX))
    return vector3(-math.sin(radZ) * num, math.cos(radZ) * num, math.sin(radX))
end

function PHOTOMODE.BlockMouvementsControls()
    if PHOTOMODE.IsActive then
        DisableControlAction(0, 30, true) -- INPUT_MOVE_LR
        DisableControlAction(0, 31, true) -- INPUT_MOVE_UD
        DisableControlAction(0, 32, true) -- INPUT_MOVE_UP_ONLY
        DisableControlAction(0, 33, true) -- INPUT_MOVE_DOWN_ONLY
        DisableControlAction(0, 34, true) -- INPUT_MOVE_LEFT_ONLY
        DisableControlAction(0, 35, true) -- INPUT_MOVE_RIGHT_ONLY

        -- Also block attacks controls
        DisableControlAction(0, 24, true) -- INPUT_ATTACK
        DisableControlAction(0, 25, true) -- INPUT_AIM
    end
end

function PHOTOMODE.Stop()
    PHOTOMODE.IsActive = false
    Cam.SetActive(PHOTOMODE.CameraName, false, true, 1000)
    Wait(1000)
    Cam.Destroy(PHOTOMODE.CameraName)
end


-- Commands
RegisterCommand("photomode", function()
    if not PHOTOMODE.IsActive then
        PHOTOMODE.Start()
    else
        PHOTOMODE.Stop()
    end
end, false)

PHOTOMODE.Start()