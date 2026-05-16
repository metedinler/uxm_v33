# UXM English command set V13

## Core

```powershell
tool_en\help.bat
tool_en\memory_test.bat
tool_en\fast_scan.bat
tool_en\failed_test.bat -k -D
tool_en\all_test.bat -k -n 100
tool_en\report_show.bat
tool_en\workspace_clean.bat -u -b
tool_en\vscode_install.bat
```

## Stage-17 fix

```powershell
tool_en\stage17_fix.bat
tool_en\stage17_check.bat -k
```

## Stage-18 finish

```powershell
tool_en\stage18_fix.bat
tool_en\stage18_check.bat -k
tool_en\stage18_finish.bat -k
```

## Stage-19 start and finish

```powershell
tool_en\stage19_start.bat -k
tool_en\stage19_test.bat -k
tool_en\stage19_finish.bat -k
```

## Short options

- `-k`: no build
- `-D`: stop on first failure
- `-n N`: run at most N tests
- `-s N`: start from index N
- `-a TEXT`: filter by name
- `-u`: apply
- `-b`: retire build folder
- `-h`: help
