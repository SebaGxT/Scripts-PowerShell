Set WinScriptHost = CreateObject("WScript.Shell")
WinScriptHost.Run "wsl.exe -u root service docker start", 0