local resourcename = GetCurrentResourceName()
local version = GetResourceMetadata(resourcename, "version", 0)
local isMapping = false
local escrow = false

Citizen.CreateThread(function()
    Wait(5000)
    
    PerformHttpRequest('https://raw.githubusercontent.com/Spooni-Development/spooni_updates/refs/heads/main/scripts/spooni_spooner.json', function(err, text, headers)
        if err ~= 200 or not text then
            print('^8' .. resourcename .. ' ^3Unable to check for updates^0')
            return
        end
        
        local success, data = pcall(json.decode, text)
        if not success or not data then
            print('^8' .. resourcename .. ' ^3Error parsing version data^0')
            return
        end
        
        if tonumber(version) == tonumber(data.version) then
            if isMapping == true then
                print('^3' .. resourcename .. ' ^2is up to date!^0')
            else
                print('^4' .. resourcename .. ' ^2is up to date!^0')
            end
        else
            if isMapping == true then
                print('^3' .. resourcename .. ' ^8VERSION MISMATCH!^0')
            else
                print('^4' .. resourcename .. ' ^8VERSION MISMATCH!^0')
            end
            print('^8Current: ^3' .. version .. '^8 ^3|^8 Latest: ^3' .. data.version .. '^0')
            if escrow == true then
                print('^8Download: ^3https://keymaster.fivem.net^0')
            else
                print('^8Download: ^3https://github.com/Spooni-Development/spooni_spooner^0')
            end
        end
    end, 'GET')
end)

-- Color Codes Reference:
-- ^0 = White
-- ^1 = Red
-- ^2 = Green
-- ^3 = Yellow
-- ^4 = Blue
-- ^5 = Light Blue
-- ^6 = Purple
-- ^7 = White
-- ^8 = Dark Red
-- ^9 = Dark Blue

