@echo off
setlocal EnableDelayedExpansion

set CURRENT_DRIVE=%~d0
set CURRENT_DIR=%~p0
set CHROME_PATH=%HOMEDRIVE%%HOMEPATH%\AppData\Local\Google\Chrome\User Data
set TEMP_SQL_SCRIPT=%TEMP%\sync_chrome_sql_script
set TEMP_DB=%TEMP%\temp_web_data

if "%1"=="" (
    set BASE_SOURCE=%CURRENT_DRIVE%%CURRENT_DIR%Chromekeywords
) else (
    set BASE_SOURCE=%~f1
)

pushd
echo WARNING: You should close all Chrome instances before running this script.
echo This script will import Chrome custom search engines (overwriting existing ones) from the exported SQL files.
:: List available profiles
set profile_count=0
echo Available Chrome profiles:
for /d %%P in ("%CHROME_PATH%\*") do (
    if exist "%%P\Web Data" (
        set /a profile_count+=1
        echo !profile_count!: %%~nxP
    )
)

:: Get user selection
:get_selection
set /p "selection=Enter profile numbers to import (comma-separated) or 'all' for all profiles: "

:: Validate selection
if "!selection!"=="" (
    echo Error: No selection entered. Please try again.
    goto get_selection
)

:: Remove spaces from selection for better parsing
set "selection=!selection: =!"

:: Process each profile
set profile_num=0
set processed_count=0
for /d %%P in ("%CHROME_PATH%\*") do (
    if exist "%%P\Web Data" (
        set /a profile_num+=1
        set "import_profile="
        
        :: Check if this profile should be imported
        if /i "!selection!"=="all" (
            set "import_profile=yes"
        ) else (
            for %%n in (!selection!) do (
                if %%n==!profile_num! set "import_profile=yes"
            )
        )
        
        if defined import_profile (
            set "PROFILE_NAME=%%~nxP"
            
            :: Sanitize profile name for filename (replace problematic characters)
            set "SAFE_PROFILE_NAME=!PROFILE_NAME: =_!"
            set "SAFE_PROFILE_NAME=!SAFE_PROFILE_NAME:(=_!"
            set "SAFE_PROFILE_NAME=!SAFE_PROFILE_NAME:)=_!"
            set "SAFE_PROFILE_NAME=!SAFE_PROFILE_NAME:[=_!"
            set "SAFE_PROFILE_NAME=!SAFE_PROFILE_NAME:]=_!"
            
            set SOURCE=%BASE_SOURCE%_!SAFE_PROFILE_NAME!.sql
            set SOURCE=!SOURCE:\=/!
            
            if exist "!SOURCE!" (
                set /a processed_count+=1
                echo Importing Chrome keywords to !PROFILE_NAME! from !SOURCE!...
                cd /D "%%P"
                
                rem Copy database to temp location to avoid locks
                copy /Y "Web Data" "%TEMP_DB%" >nul
                
                echo .read "!SOURCE!" > %TEMP_SQL_SCRIPT%
                "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" -init %TEMP_SQL_SCRIPT% "%TEMP_DB%" .exit
                
                rem Replace the original database with the modified one
                copy /Y "%TEMP_DB%" "Web Data" >nul
                
                if %ERRORLEVEL%==0 (
                    echo Successfully imported to !PROFILE_NAME!
                ) else (
                    echo Failed to import to !PROFILE_NAME!
                    pause
                )
                
                rem Clean up temp files
                del %TEMP_SQL_SCRIPT% 2>nul
                del %TEMP_DB% 2>nul
            ) else (
                echo Source file for !PROFILE_NAME! not found: !SOURCE!
                pause
            )
        )
    )
)

:: Validate that at least one profile was processed
if !processed_count! equ 0 (
    echo.
    echo Warning: No profiles were imported. This could be because:
    echo 1. No valid profile numbers were selected
    echo 2. No source files were found for the selected profiles
    if not "!selection!"=="all" (
        echo Please ensure you entered valid profile numbers from 1 to !profile_count!.
    )
    echo.
    pause
    goto end
)

popd
echo.
echo Import complete. Processed !processed_count! profile(s).
:end
pause