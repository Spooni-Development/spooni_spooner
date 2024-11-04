local resourcename = GetCurrentResourceName()
local version = GetResourceMetadata(resourcename, "version", 0)

Citizen.CreateThread(function()
    PerformHttpRequest("https://raw.githubusercontent.com/Spooni-Development/spooni_updates/main/scripts/spooni_spooner.json", function(err, text, headers)
        local text = json.decode(text)
        Wait(5000)
        if tonumber(version) == tonumber(text.version) then
            print("^2VERSION: ^4" .. resourcename .. "^2 IS UP TO DATE!^0")
        elseif tonumber(version) ~= tonumber(text.version) then
            print("^8VERSION: ^4" .. resourcename .. "^8 THERE IS A NEW VERSION AVAILABLE!^0")
            print("^8DOWNLOAD THE UPDATE HERE: ^4https://github.com/Spooni-Development/spooni_spooner^0")
        end
    end, 'GET')
end)

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
