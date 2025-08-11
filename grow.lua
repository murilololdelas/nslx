(function()
    local KeyVerifyURL = "https://murilo.lol/verify_key"
    
    local key = _G.NSLX_KEY

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
    local HttpService = game:GetService("HttpService")

    if not key or key == "" then
        LocalPlayer:Kick("No key provided!\n\nDiscord: discord.gg/nslx")
        return
    end

    local function verifyKey(key)
        local requestFunc = syn and syn.request or http_request or request or (http and http.request)
        if requestFunc then
            local success, response = pcall(function()
                return requestFunc({
                    Url = KeyVerifyURL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = HttpService:JSONEncode({key = key})
                })
            end)
            
            if success and response and response.Body then
                local decoded = HttpService:JSONDecode(response.Body)
                return decoded.success, decoded
            end
        end
        return false, nil
    end

    local function showNotification(title, text, duration)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end

    local keyValid, keyResponse = verifyKey(key)
    
    if not keyValid then
        local errorMsg = keyResponse and keyResponse.error or "Invalid key"
        LocalPlayer:Kick("Access denied!\n\nReason: " .. errorMsg .. "\n\nDiscord: discord.gg/nslx")
        return
    end

    if keyResponse and keyResponse.key_info then
        local info = keyResponse.key_info
        showNotification("Grow Script Online", "User: " .. info.username .. "\nDays remaining: " .. info.days_remaining, 8)
        print("Valid key!")
        print("User: " .. info.username)
        print("Days remaining: " .. info.days_remaining)
        
        local success, error = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/murilololdelas/nslx/refs/heads/main/grow1.lua"))()
        end)
        
        if not success then
            warn("Erro ao executar o script: " .. tostring(error))
            showNotification("Erro", "Falha ao carregar o script", 5)
        else
            showNotification("Sucesso", "Script carregado com sucesso!", 3)
        end
    else
        showNotification("Grow Script Online", "Valid key - System active", 5)
        
        local success, error = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/murilololdelas/nslx/refs/heads/main/grow1.lua"))()
        end)
        
        if not success then
            warn("Erro ao executar o script: " .. tostring(error))
            showNotification("Erro", "Falha ao carregar o script", 5)
        else
            showNotification("Sucesso", "Script carregado com sucesso!", 3)
        end
    end
end)()
