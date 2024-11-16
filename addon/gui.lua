local header = { 1.0, 0.75, 0.55, 1.0 };
local imgui = require('imgui');
local instances;
local is_open = { false };
local processes = require('processes');
local text_buffer = { 'pol.exe' };

local function Save()
    local buffer = settings.Blocked_Instances;
    if (settings.Save_Blocked_Instances == false) then
        settings.Blocked_Instances = T{};
    end
    settingsLib.save();
    settings.Blocked_Instances = buffer;
end

ashita.events.register('d3d_present', 'd3d_present_gui', function ()
    if (is_open[1]) then
        if (imgui.Begin(string.format('%s v%s', addon.name, addon.version), is_open, ImGuiWindowFlags_AlwaysAutoResize)) then
            imgui.BeginGroup();
            imgui.TextColored(header, 'Blocked Instances');
            if imgui.Checkbox('Save to Settings', { settings.Save_Blocked_Instances }) then
                settings.Save_Blocked_Instances = not settings.Save_Blocked_Instances;
                Save();
            end
            for _,entry in ipairs(instances) do
                local active = settings.Blocked_Instances:contains(entry.WindowName);
                if (imgui.Checkbox(entry.WindowName, { active })) then
                    if active then
                        settings.Blocked_Instances = settings.Blocked_Instances:filteri(function(a) return a ~= entry.WindowName; end);
                        if settings.Save_Blocked_Instances then
                            Save();
                        end
                    else
                        settings.Blocked_Instances:append(entry.WindowName);
                        if settings.Save_Blocked_Instances then
                            Save();
                        end
                    end
                end
            end
            if (imgui.Button('Reload List')) then
                instances = processes:GetProcesses(settings.FFXI_Executables, true);
                table.sort(instances, function(a,b) return a.WindowName < b.WindowName; end);
            end
            imgui.EndGroup();
            imgui.SameLine();
            imgui.BeginGroup();
            imgui.TextColored(header, 'Display Window Swaps');
            if imgui.Checkbox('Enabled', { settings.Show_Swaps }) then
                settings.Show_Swaps = not settings.Show_Swaps;
                Save();
            end
            imgui.TextColored(header, 'FFXI Executable Files');
            imgui.ShowHelp('Double click to delete an entry.');
            
            local remove;
            for _,entry in ipairs(settings.FFXI_Executables) do
                imgui.Text(entry);
                if (imgui.IsItemHovered()) and (imgui.IsMouseDoubleClicked(0)) then
                    remove = entry;
                end
            end
            if remove then
                settings.FFXI_Executables = settings.FFXI_Executables:filteri(function(a) return a ~= remove end);
                Save();
            end
            imgui.InputText('##Focuser_Enter_Process_Name', text_buffer, 1024);
            imgui.SameLine();
            imgui.Separator();
            if imgui.Button('Add') then
                if not settings.FFXI_Executables:contains(text_buffer[1]) then
                    settings.FFXI_Executables:append(text_buffer[1]);
                    table.sort(settings.FFXI_Executables);
                    Save();
                end
            end
            imgui.EndGroup();

            imgui.End();
        end        
    end
end);


local exports = T{};

function exports:Show()
    is_open[1] = true;
    instances = processes:GetProcesses(settings.FFXI_Executables, true);
    table.sort(instances, function(a,b) return a.WindowName < b.WindowName; end);
end

return exports;