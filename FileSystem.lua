local FileSystem = {}

local HttpService = game:GetService("HttpService")

function FileSystem.getfile(name, defaultSettings)
    local contents = {}

    if isfolder and not isfolder("KartFiles") then
        makefolder("KartFiles")
    end

    local fileName = "KartFiles/" .. name .. ".txt"

    if writefile then
        if isfile(fileName) then
            contents = HttpService:JSONDecode(readfile(fileName))
        else
            contents = defaultSettings
            writefile(fileName, HttpService:JSONEncode(contents))
        end

        for i,v in pairs(defaultSettings) do
            if not contents[i] then
                contents[i] = v
                
                if writefile then
                    writefile(fileName, HttpService:JSONEncode(contents))
                end
            end
        end
    end
    
    local contentsProxy = setmetatable({},{
        __newindex = function(_self, key, value)
            contents[key] = value

            if writefile then
                writefile(fileName, HttpService:JSONEncode(contents))
            end
        end,
        __index = function(_self, index)
            return contents[index]
        end
    })    

    return contentsProxy
end

return FileSystem
