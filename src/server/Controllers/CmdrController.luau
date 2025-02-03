local Controller = {}

local Cmdr, CmdrFolders
function Controller:Init()
    Cmdr = shared.Import "Cmdr"
    CmdrFolders = shared.Import "CmdrFolders"

    Cmdr:RegisterDefaultCommands()

    -- register hooks
    Cmdr:RegisterHooksIn(CmdrFolders.Hooks)

    -- register types
    Cmdr:RegisterTypesIn(CmdrFolders.Types)

    -- register commands
    Cmdr:RegisterCommandsIn(CmdrFolders.Commands)
end

return Controller