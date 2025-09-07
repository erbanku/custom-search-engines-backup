@echo off
setlocal EnableDelayedExpansion

echo ================================================================================
echo Edge Search Engine Import Diagnostic Tool
echo ================================================================================
echo This tool helps diagnose why search engines may be disappearing after import.
echo.

set CURRENT_DRIVE=%~d0
set CURRENT_DIR=%~p0
set EDGE_PATH=%HOMEDRIVE%%HOMEPATH%\AppData\Local\Microsoft\Edge\User Data
set TEMP_SQL_SCRIPT=%TEMP%\diagnostic_sql_script

:: Check if Edge is running
echo 1. Checking if Edge is running...
tasklist /FI "IMAGENAME eq msedge.exe" 2>NUL | find /I /N "msedge.exe">NUL
if %ERRORLEVEL% EQU 0 (
    echo   ⚠️  WARNING: Edge is currently running!
    echo   📋 Please close all Edge windows and tabs before proceeding.
    echo.
) else (
    echo   ✓ Edge is not running - Good!
    echo.
)

:: Check Edge profiles
echo 2. Checking Edge profiles...
set profile_count=0
for /d %%P in ("%EDGE_PATH%\*") do (
    if exist "%%P\Web Data" (
        set /a profile_count+=1
        echo   Profile !profile_count!: %%~nxP
        
        :: Check database size
        for %%F in ("%%P\Web Data") do (
            echo     Database size: %%~zF bytes
        )
        
        :: Check search engines count
        echo SELECT COUNT(*) FROM keywords WHERE keyword NOT IN ('@tabs', '@history', '@bookmarks'); > %TEMP_SQL_SCRIPT%
        "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" "%%P\Web Data" < %TEMP_SQL_SCRIPT% > "%TEMP%\count_result" 2>nul
        if exist "%TEMP%\count_result" (
            set /p custom_count=<"%TEMP%\count_result"
            echo     Custom search engines: !custom_count!
            del "%TEMP%\count_result" 2>nul
        ) else (
            echo     ❌ Cannot read database (may be locked)
        )
        
        :: Check sync-related entries
        echo SELECT COUNT(*) FROM meta WHERE key LIKE '%%sync%%'; > %TEMP_SQL_SCRIPT%
        "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" "%%P\Web Data" < %TEMP_SQL_SCRIPT% > "%TEMP%\sync_result" 2>nul
        if exist "%TEMP%\sync_result" (
            set /p sync_count=<"%TEMP%\sync_result"
            echo     Sync metadata entries: !sync_count!
            del "%TEMP%\sync_result" 2>nul
        )
        echo.
    )
)

if !profile_count! EQU 0 (
    echo   ❌ No Edge profiles found!
    echo   📋 Please ensure Edge is properly installed.
    echo.
)

:: Check for common sync issues
echo 3. Checking Edge sync status...
echo   📋 Manual check required:
echo   1. Open Edge and go to edge://settings/profiles/sync
echo   2. Check if "Search engines" sync is enabled
echo   3. If enabled, this may cause imported search engines to be overwritten
echo.

:: Check Edge version
echo 4. Checking Edge version...
set "edge_exe=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not exist "%edge_exe%" set "edge_exe=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"

if exist "%edge_exe%" (
    for /f "tokens=2 delims= " %%v in ('powershell -command "(Get-ItemProperty '%edge_exe%').VersionInfo.FileVersion"') do (
        echo   Edge version: %%v
        
        :: Check if version is 140 or higher
        for /f "tokens=1 delims=." %%a in ("%%v") do (
            if %%a GEQ 140 (
                echo   ⚠️  This version may have enhanced sync that overwrites imports
                echo   📋 Use the Enhanced scripts for better compatibility
            ) else (
                echo   ✓ Version should work with standard scripts
            )
        )
    )
) else (
    echo   ❌ Edge executable not found
)
echo.

:: Check for backup files
echo 5. Checking for backup files...
set backup_count=0
for %%F in ("%TEMP%\*Web_Data_backup*.sqlite") do (
    set /a backup_count+=1
    echo   Backup !backup_count!: %%~nF (%%~zF bytes)
)

if !backup_count! EQU 0 (
    echo   No backup files found in %TEMP%
) else (
    echo   📋 !backup_count! backup file(s) available for restore if needed
)
echo.

:: Recommendations
echo 6. Recommendations:
echo.
if !profile_count! GTR 0 (
    echo   ✓ Edge profiles detected
) else (
    echo   ❌ Install Edge and create at least one profile
)

echo.
echo   For Edge 140.x and newer:
echo   1. Use 'Import Edge Custom Search Engines Enhanced.cmd'
echo   2. Or 'Overwrite Chrome Custom Search Engines to Edge Enhanced.cmd'
echo   3. Disable Edge sync for search engines BEFORE import
echo   4. Verify import success BEFORE re-enabling sync
echo.
echo   For older Edge versions:
echo   1. Standard scripts should work fine
echo   2. Still recommended to disable sync during import
echo.

:: Cleanup
del %TEMP_SQL_SCRIPT% 2>nul

echo ================================================================================
echo Diagnostic complete! Press any key to exit.
pause >nul