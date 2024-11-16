#include <filesystem>
#include <stdint.h>
#include <string>
#include <vector>
#include <windows.h>

#include <psapi.h>
#pragma comment(lib, "psapi.lib")

struct ProcessInfo_t
{
    char WindowName[256];
    HWND HWND;
    uint32_t ProcessId;
};
struct ProcessInfoContainer_t
{
    uint32_t Count;
    ProcessInfo_t Entries[100];
};

std::vector<std::string> validExecutables;
bool ffxiOnly;
std::vector<DWORD> processIds;
ProcessInfoContainer_t output;
BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lparam)
{
    if (ffxiOnly)
    {
        char classNameBuffer[256];
        if (GetClassName(hwnd, classNameBuffer, 255) == 0)
            return true;

        if (strcmp(classNameBuffer, "FFXiClass") != 0)
            return true;
    }

    DWORD processId;
    if (GetWindowThreadProcessId(hwnd, &processId) == 0)
        return true;

    HANDLE processHandle = OpenProcess(PROCESS_VM_READ | PROCESS_QUERY_INFORMATION, false, processId);
    if (processHandle == nullptr)
        return true;

    char moduleNameBuffer[256];
    if (GetModuleFileNameEx(processHandle, nullptr, moduleNameBuffer, 256) == 0)
    {
        CloseHandle(processHandle);
        return true;
    }

    std::string fileName = std::filesystem::path(moduleNameBuffer).filename().string();
    if (std::find(validExecutables.begin(), validExecutables.end(), fileName) != validExecutables.end())
    {
        ProcessInfo_t info;
        info.HWND = hwnd;
        if (GetWindowText(hwnd, info.WindowName, 256) != 0)
        {
            info.ProcessId               = processId;
            output.Entries[output.Count] = info;
            output.Count++;
        }
    }

    CloseHandle(processHandle);
    return true;
}

ProcessInfoContainer_t QueryProcesses()
{
    output.Count = 0;
    processIds.clear();
    EnumWindows(&EnumWindowsProc, (LPARAM)0);
    return output;
}

void SplitProcessNames(std::string input)
{
    validExecutables.clear();
    size_t index = 0;
    std::string token;
    while ((index = input.find(":")) != std::string::npos)
    {
        validExecutables.push_back(input.substr(0, index));
        input.erase(0, index + 1);
    }
    validExecutables.push_back(input);
}

extern "C"
{
    extern __declspec(dllexport) ProcessInfoContainer_t GetActiveProcesses(const char* processes)
    {
        SplitProcessNames(processes);
        ffxiOnly = false;
        return QueryProcesses();
    }
    extern __declspec(dllexport) ProcessInfoContainer_t GetFFXIProcesses(const char* processes)
    {
        SplitProcessNames(processes);
        ffxiOnly = true;
        return QueryProcesses();
    }
}
