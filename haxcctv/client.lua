local timecycleModifier = "scanline_cam_cheap"
local camTable = {}
local menuPosition = "bottom-left"

-- Adjust the rotations to match the camera model orientation.
local rotOffsets = {
    -- [prop_name] = vec3(pitch, roll, yaw)
    ["prop_cctv_cam_01a"] = vec3(-30, 0, 215),
    ["prop_cctv_cam_01b"] = vec3(-30, 0, 145),
    ["prop_cctv_cam_02a"] = vec3(-20, 0, 210),
    ["prop_cctv_cam_03a"] = vec3(0, 0, 135),
    ["prop_cctv_cam_04a"] = vec3(0, 0, 180),
    ["prop_cctv_cam_04b"] = vec3(0, 0, 180),
    ["prop_cctv_cam_04c"] = vec3(-20, 0, 180),
    ["prop_cctv_cam_05a"] = vec3(-20, 0, 180),
    ["prop_cctv_cam_06a"] = vec3(-20, 0, 180),
    ["prop_cctv_cam_07a"] = vec3(0, 0, 180),
    ["ba_prop_battle_cctv_cam_01a"] = vec3(-45, 0, -90),
    ["ba_prop_battle_cctv_cam_01b"] = vec3(-45, 0, 90),
}

-- Adjust the camera view position to match model
local posOffsets = {
    -- [prop_name] = vec3(left/right, forward/backward, up/down)
    ["prop_cctv_cam_01a"] = vec3(0, -0.7, 0.2),
    ["prop_cctv_cam_01b"] = vec3(0, -0.7, 0.2),
    ["prop_cctv_cam_02a"] = vec3(0.15, -0.3, 0),
    ["prop_cctv_cam_03a"] = vec3(-0.4, -0.4, 0.35),
    ["prop_cctv_cam_04a"] = vec3(0, -0.75, 0.65),
    ["prop_cctv_cam_04b"] = vec3(0, -0.6, 0.5),
    ["prop_cctv_cam_04c"] = vec3(0, -0.25, -0.35),
    ["prop_cctv_cam_05a"] = vec3(0, -0.2, -0.4),
    ["prop_cctv_cam_06a"] = vec3(0, -0.1, -0.2),
    ["prop_cctv_cam_07a"] = vec3(0, 0, -0.2),
    ["ba_prop_battle_cctv_cam_01a"] = vec3(0.35, -0.35, 0),
    ["ba_prop_battle_cctv_cam_01b"] = vec3(-0.35, -0.35, 0),
}

-- These proptypes can be controlled
local canMove = {
    ["prop_cctv_cam_04a"] = true,
    ["prop_cctv_cam_04b"] = true,
    ["prop_cctv_cam_04c"] = true,
    ["prop_cctv_cam_07a"] = true,
}

-- Store menus in the table, so they can be called before definition, without having to make them global
local Menus = {}

--- Borrowed from https://stackoverflow.com/questions/15706270/sort-a-table-in-lua and slightly modified
function spairs(t)
    -- "Cameras" should be first
    local order = function(a, b)
        if a == "Cameras" then
            return true
        elseif b == "Cameras" then
            return false
        end
        return a < b
    end
    -- collect the keys
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end

    table.sort(keys, function(a, b)
        return order(a, b)
    end)

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function ResetUI()
    -- Make UI elements visible again
    TriggerEvent('esx_status:setDisplay', 0.5)
    ESX.UI.HUD.SetDisplay(1.0)
    DisplayRadar(true)

    -- Cleanup
    RenderScriptCams(false, false, 0, 1, 0)
    ClearTimecycleModifier(timecycleModifier)
    -- Resets the rendering focus back to follow player
    ClearFocus()
end

local function DisplayCamera(idx)
    local cctv = Cameras[idx]

    --- Easy debugging for each camera type
    -- local cctv = Cameras[6] -- 01a
    -- local cctv = Cameras[5] -- 01b
    -- local cctv = Cameras[31] -- 02a
    -- local cctv = Cameras[53] -- 03a
    -- local cctv = Cameras[143] -- 04a
    -- local cctv = Cameras[385] -- 04b
    -- local cctv = Cameras[100] -- 04c
    -- local cctv = Cameras[89] -- 05a
    -- local cctv = Cameras[20] -- 06a
    -- local cctv = Cameras[438] -- 07a
    -- local cctv = Cameras[1324] -- ba_prop_battle_cctv_cam_01a
    -- local cctv = Cameras[1325] -- ba_prop_battle_cctv_cam_01b

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    -- Game loads graphics in this position
    SetFocusPosAndVel(cctv.Pos, 0.0, 0.0, 0.0)

    local object = 0
    while object == 0 do
        object = GetClosestObjectOfType(cctv.Pos, 5.0, GetHashKey(cctv.Prop), false, false, false)
        if object == 0 then
            Citizen.Wait(50)
        end
    end

    -- Offset is in relation to the object, no matter which way it is rotated
    local coordsWithOffset = GetOffsetFromEntityInWorldCoords(object, posOffsets[cctv.Prop])
    local rotation = GetEntityRotation(object, 2) + rotOffsets[cctv.Prop]
    SetCamRot(cam, rotation, 2)
    SetCamCoord(cam, coordsWithOffset)
    RenderScriptCams(true, false, 0, 1, 0)

    -- Makes the screen look like "cheap cctv"
    SetTimecycleModifier(timecycleModifier)
    SetTimecycleModifierStrength(2.0)

    -- Hide minimap on other UI elements
    DisplayRadar(false)
    ESX.UI.HUD.SetDisplay(0.0)
    TriggerEvent('esx_status:setDisplay', 0.0)

    -- Camera controls for movable cameras
    if canMove[cctv.Prop] then
        local step = 0.5
        local delay = 5
        Citizen.CreateThread(function()
            while DoesCamExist(cam) do
                if IsDisabledControlPressed(0, 34) then
                    -- A for left
                    rotation = rotation + vec(0, 0, step)
                    SetCamRot(cam, rotation, 2)
                end
                Citizen.Wait(delay)
            end
        end)
        Citizen.CreateThread(function()
            while DoesCamExist(cam) do
                if IsDisabledControlPressed(0, 35) then
                    -- D for right
                    rotation = rotation + vec(0, 0, -step)
                    SetCamRot(cam, rotation, 2)
                end
                Citizen.Wait(delay)
            end
        end)
        Citizen.CreateThread(function()
            while DoesCamExist(cam) do
                if IsDisabledControlPressed(0, 32) then
                    -- W for up
                    if rotation.x < rotOffsets[cctv.Prop].x then
                        rotation = rotation + vec(step, 0, 0)
                        SetCamRot(cam, rotation, 2)
                    end
                end
                Citizen.Wait(delay)
            end
        end)
        Citizen.CreateThread(function()
            while DoesCamExist(cam) do
                if IsDisabledControlPressed(0, 33) then
                    -- S for down
                    if rotation.x > -90 then
                        rotation = rotation + vec(-step, 0, 0)
                        SetCamRot(cam, rotation, 2)
                    end
                end
                Citizen.Wait(delay)
            end
        end)
    end

    -- Disable movement while watching camera. Back out from camera with ESC/backspace/rmb
    while not IsDisabledControlJustReleased(0, 177) do
        local msg = 'Press ~INPUT_CELLPHONE_CANCEL~ to go back.'
        if canMove[cctv.Prop] then
            msg = msg .. " Move camera with ~INPUT_MOVE_UP_ONLY~ ~INPUT_MOVE_LEFT_ONLY~ ~INPUT_MOVE_DOWN_ONLY~ ~INPUT_MOVE_RIGHT_ONLY~"
        end
        ESX.ShowHelpNotification(msg, true, false)
        DisableAllControlActions(0)
        Citizen.Wait(0)
    end

    DestroyCam(cam, false)
    ResetUI()
    -- SetEntityCoords(PlayerPedId(), coordsWithOffset) -- For debugging orientations
end

Menus.OpenCamerasMenu = function(cameras, street, zone)
    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open(
            'default',
            GetCurrentResourceName(),
            'camera',
            {
                title = "Choose camera",
                align = menuPosition,
                elements = cameras,
            }, function(data, menu)
                DisplayCamera(data.current.value)
            end, function(data, menu)
                menu.close()
                Menus.OpenChooseCrossingOrCameraMenu(street, zone)
            end
    )
end

Menus.OpenChooseCrossingOrCameraMenu = function(street, zone)
    ESX.UI.Menu.CloseAll()

    local elements = {}
    for k, v in spairs(street) do
        elements[#elements + 1] = { label = k, value = v }
    end

    ESX.UI.Menu.Open(
            'default',
            GetCurrentResourceName(),
            'crossing',
            {
                title = "Choose Crossing or cameras",
                align = menuPosition,
                elements = elements,
            }, function(data, menu)
                if data.current.label == "Cameras" then
                    -- Show cameras without crossing name
                    Menus.OpenCamerasMenu(data.current.value, street, zone)
                else
                    -- Show cameras for the selected crossing
                    Menus.OpenCamerasMenu(data.current.value.Cameras, street, zone)
                end
            end, function(data, menu)
                menu.close()
                Menus.OpenChooseStreetMenu(zone)
            end
    )
end

Menus.OpenChooseStreetMenu = function(zone)
    ESX.UI.Menu.CloseAll()

    local elements = {}
    for k, v in spairs(zone) do
        elements[#elements + 1] = { label = k, value = v }
    end

    ESX.UI.Menu.Open(
            'default',
            GetCurrentResourceName(),
            'street',
            {
                title = "Choose Street",
                align = menuPosition,
                elements = elements,
            }, function(data, menu)
                Menus.OpenChooseCrossingOrCameraMenu(data.current.value, zone)
            end, function(data, menu)
                menu.close()
                Menus.OpenChooseZoneMenu()
            end
    )
end

Menus.OpenChooseZoneMenu = function()
    ESX.UI.Menu.CloseAll()

    local elements = {}

    for k, v in spairs(camTable) do
        elements[#elements + 1] = { label = k, value = v }
    end

    ESX.UI.Menu.Open(
            'default',
            GetCurrentResourceName(),
            'zone',
            {
                title = "Choose Zone",
                align = menuPosition,
                elements = elements,
            }, function(data, menu)
                Menus.OpenChooseStreetMenu(data.current.value)
            end, function(data, menu)
                menu.close()
            end
    )
end

local function SetupTables()
    for i = 1, #Cameras do
        local cctv = Cameras[i]
        local zoneNameAbbrv = GetNameOfZone(cctv.Pos)
        local zoneName = Zones[zoneNameAbbrv]
        if ExcludeZones[zoneName] then
            goto skip
        end
        if not camTable[zoneName] then
            camTable[zoneName] = {}
        end
        local streetNameHash, crossingRoadHash = GetStreetNameAtCoord(cctv.Pos.x, cctv.Pos.y, cctv.Pos.z)
        local streetName = GetStreetNameFromHashKey(streetNameHash)
        local crossName = GetStreetNameFromHashKey(crossingRoadHash)

        if not camTable[zoneName][streetName] then
            camTable[zoneName][streetName] = {}
        end

        if crossName ~= "" then
            if not camTable[zoneName][streetName][crossName] then
                camTable[zoneName][streetName][crossName] = { Cameras = {} }
            end
            local crossingCameras = camTable[zoneName][streetName][crossName].Cameras
            local idx = #crossingCameras + 1
            crossingCameras[idx] = { label = "Camera " .. tostring(idx), value = i }
        else
            if not camTable[zoneName][streetName].Cameras then
                camTable[zoneName][streetName].Cameras = {}
            end
            local streetCameras = camTable[zoneName][streetName].Cameras
            local idx = #streetCameras + 1
            streetCameras[idx] = { label = "Camera " .. tostring(idx), value = i }
        end
    end
    :: skip ::
end

exports('OpenCCTVMenu', function()
    if not camTable then
        print("Cameras not initialized yet!")
        return
    end
    Menus.OpenChooseZoneMenu()
end)

--[[RegisterCommand('camdev', function()
    exports.haxcctv:OpenCCTVMenu()
end)]]

-- Runs the script on resource start
AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    Citizen.CreateThread(function()
        while not ESX.IsPlayerLoaded() do
            Citizen.Wait(100)
        end

        SetupTables()
    end)
end)

-- Runs the script on resource start
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end
    ResetUI()
end)
