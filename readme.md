# Focuser
Focuser is an addon that allows you to use typed commands to swap between active FFXI proceseses, rather than using alt-tab.  It relies on a simple helper DLL to simplify the process of enumerating active process windows.  The source for the DLL is in this repository.

### Commands

**/focuser**<br>
This will open the configuration panel.  From here, you can specify characters to be excluded from the keyword cycling, enable or disable printing to log when swapping windows, and edit the list of executables that will be recognized as FFXI processes.  By default, excluded characters are not saved and will need to be added each time you open the addon.  You can override this by using the 'Save to Settings' check box, and that will make your exclusions permanent.<br><br>

**/winfocus [required: character name or keyword]**<br>
**/focusxi [required: character name or keyword]**<br>
Either of these commands will focus a FFXI window that matches the specified character name.  You can also use the following keywords:<br>
*nextalpha - Next character, alphabetically.<br>
*prevalpha - Previous character, alphabetically.<br>
*nextpid - Next character, by process ID.<br>
*prevpid - Previous character, by process ID.<br>
Any characters listed in the blocked instances list in the config GUI will be ignored by keyword commands but can still be focused using their actual name.<br><br>

**/focusany [required: process filename] [optional: additional process filenames]**<br>
This will focus a specific process on your machine, if it can be found.  You must specify the exact process filename, case sensitive, such as 'chrome.exe'.