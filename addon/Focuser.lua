addon.name      = 'Focuser';
addon.author    = 'Thorny';
addon.version   = '1.00';
addon.desc      = 'Allows you to swap window focus using typed commands.';
addon.link      = 'https://github.com/ThornyFFXI/Focuser/';

require('common');
local chat = require('chat');
local ffi = require('ffi');
local processes = require('processes');
local default_settings = T{
    Blocked_Instances = T{ },
    FFXI_Executables = T{ 'Edenxi.exe', 'horizon-loader.exe', 'pol.exe', 'xiloader.exe' },
    Save_Blocked_Instances = false,
    Show_Swaps = true,
};
settingsLib = require('settings');
settings = settingsLib.load(default_settings);
local gui = require('gui');

local function Error(text)
    local color = ('\30%c'):format(68);
    local highlighted = color .. string.gsub(text, '$H', '\30\01\30\02');
    highlighted = string.gsub(highlighted, '$R', '\30\01' .. color);
    print(chat.header(addon.name) .. highlighted .. '\30\01');
end

local function Message(text)
    local stripped = string.gsub(text, '$H', ''):gsub('$R', '');
    local color = ('\30%c'):format(106);
    local highlighted = color .. string.gsub(text, '$H', '\30\01\30\02');
    highlighted = string.gsub(highlighted, '$R', '\30\01' .. color);
    print(chat.header(addon.name) .. highlighted .. '\30\01');
end

local function HandleCommand(command)
    local args = command:args();

    if (string.lower(args[1]) == '/winfocus') or (string.lower(args[1]) == '/focusxi') then
        if (args[2] == nil) then
            Error('You must specify a character name or keyword to use $H/winfocus$R or $H/focusxi$R.');
            return;
        end

        --Query open FFXI instances and search for an exact title match..
        local query = processes:GetProcesses(settings.FFXI_Executables, true);
        local title = string.lower(args[2]);
        for _,entry in ipairs(query) do
            if (string.lower(entry.WindowName) == title) then
                if settings.Show_Swaps then
                    Message(string.format('Swapping to process: $H%s$R[$H%u$R]', entry.WindowName, entry.ProcessId));                
                end
                processes:FocusWindow(entry.HWND);
                return;
            end
        end
        
        --Remove any instances in blocklist..
        query = query:filteri(function(entry) return settings.Blocked_Instances:contains(entry.WindowName) == false; end);

        local usedKeyword = true;
        if (title == '*nextalpha') then
            table.sort(query, function(a,b) return a.WindowName < b.WindowName; end);
        elseif (title == '*prevalpha') then
            table.sort(query, function(a,b) return a.WindowName > b.WindowName; end);
        elseif (title == '*nextpid') then
            table.sort(query, function(a,b) return a.ProcessId < b.ProcessId; end);
        elseif (title == '*prevpid') then
            table.sort(query, function(a,b) return a.ProcessId > b.ProcessId end);
        else
            usedKeyword = false;
        end

        if usedKeyword then
            if (#query == 1) then
                Error('Only 1 FFXI process was detected.  Keyword swap failed.');
                return;
            end

            local currentPID = ffi.C.GetCurrentProcessId();
            local currentIndex;
            for index,entry in ipairs(query) do
                if (entry.ProcessId == currentPID) then
                    currentIndex = index;
                end
            end

            if currentIndex == nil then
                Error('Could not locate current process id in list.  Keyword swap failed.');
                return;
            end

            local entry = (currentIndex == #query) and query[1] or query[currentIndex + 1];
            if settings.Show_Swaps then
                Message(string.format('Swapping to process: $H%s$R[$H%u$R]', entry.WindowName, entry.ProcessId));
            end
            processes:FocusWindow(entry.HWND);            
        else
            Error(string.format('A FFXI instance or keyword named $H%s$R was not found.', args[2]));
            return;
        end
    end
    
    if (string.lower(args[1]) == '/focusany') then
        local executables = T{};
        for i=2,#args do
            executables:append(args[i]);
        end
        if #executables == 0 then
            Error('You must provide at least one filename to use /focusany.');
            return;            
        end

        local query = processes:GetProcesses(executables, false);
        if (#query == 0) then
            Error('No running process was found using the listed executables.');
            return;
        end

        table.sort(query, function(a,b) return a.ProcessId < b.ProcessId end);
        local entry = query[1];
        if settings.Show_Swaps then
            Message(string.format('Swapping to process: $H%s$R[$H%u$R]', entry.WindowName, entry.ProcessId));
        end
        processes:FocusWindow(entry.HWND);
    end
end


--[[
    The pendingCommand entry is used to ensure that any window swapping only occurs during the render callback.
    Do not try to move this code directly to the command handler, the game will crash if you try to move focus.
]]--
local pendingCommand;
ashita.events.register('d3d_present', 'd3d_present_delayedcommand', function ()
    if pendingCommand then
        HandleCommand(pendingCommand);
        pendingCommand = nil;
    end
end);

local handledCommands = T{
    '/winfocus',
    '/focusxi',
    '/focusany',
};
ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command args..
    local args = e.command:args();
    if (args[1]) then
        if (handledCommands:contains(string.lower(args[1]))) then
            pendingCommand = e.command;
            e.blocked = true;
        end

        if (string.lower(args[1]) == '/focuser') then
            gui:Show();
            e.blocked = true;
        end
    end
end);
