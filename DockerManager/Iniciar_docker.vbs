Set WinScriptHost = CreateObject("WScript.Shell")
WinScriptHost.Run "cmd.exe /c wsl -u root sh -c ""service docker start; sleep infinity""", 0, False
