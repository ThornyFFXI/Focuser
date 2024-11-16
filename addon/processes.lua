local ffi = require('ffi');
require('win32types');
local scanner = ffi.load(string.format('%saddons\\focuser\\focuserhelper.dll', AshitaCore:GetInstallPath()));
ffi.cdef[[
    typedef struct {
        char WindowName[256];
        HWND HWND;
        uint32_t ProcessId;
    } ProcessInfo_t;
    typedef struct {
        uint32_t Count;
        ProcessInfo_t Entries[100];
    } ProcessInfoContainer_t;

    ProcessInfoContainer_t GetActiveProcesses(const char* executables);
    ProcessInfoContainer_t GetFFXIProcesses(const char* executables);
    
    HWND GetForegroundWindow();
    DWORD GetCurrentProcessId();
    DWORD GetWindowThreadProcessId(HWND hWnd, uint32_t lpdwProcessId);
    DWORD GetCurrentThreadId();
    BOOL AttachThreadInput(DWORD idAttach, DWORD idAttachTo, BOOL fAttach);
    BOOL SetForegroundWindow(HWND hWnd);
    BOOL BringWindowToTop(HWND hWnD);
    BOOL IsIconic(HWND hWnD);
    BOOL ShowWindow(HWND hWnd, int nCmdShow);
]]

local exports = {};

exports.GetProcesses = function(self, executables, ffxiOnly)
    local executableString = '';
    for _,executable in ipairs(executables) do
        if (executableString ~= '') then
            executableString = executableString .. ':';
        end
        executableString = executableString .. executable;
    end

    local results = ffxiOnly and scanner.GetFFXIProcesses(executableString) or scanner.GetActiveProcesses(executableString);
    local output = T{};
    local index = 0;
    while (index < results.Count) do
        local entry = results.Entries[index];
        output:append({
            WindowName = ffi.string(entry.WindowName),
            HWND = entry.HWND,
            ProcessId = entry.ProcessId,
        });
        index = index + 1;
    end
    return output;
end

exports.FocusWindow = function(self, HWND)
    local C = ffi.C;

    local foregroundHandle = C.GetForegroundWindow();
    if foregroundHandle == HWND then
        return;
    end

    local foregroundThread = C.GetWindowThreadProcessId(foregroundHandle, 0);
    local currentThread = C.GetCurrentThreadId();
    local attach = (foregroundThread ~= currentThread);

    if attach then
        C.AttachThreadInput(foregroundThread, currentThread, true);
    end

    C.SetForegroundWindow(HWND);
    C.BringWindowToTop(HWND);
    C.ShowWindow(HWND, C.IsIconic(HWND) and 1 or 5);
    
    if attach then
        C.AttachThreadInput(foregroundThread, currentThread, false);
    end
end

return exports;