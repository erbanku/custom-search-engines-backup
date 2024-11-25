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
set /p "selection=Enter profile numbers to import (comma-separated) or 'all' for all profiles: "

:: Process each profile
set profile_num=0
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
            set SOURCE=%BASE_SOURCE%_!PROFILE_NAME!.sql
            set SOURCE=!SOURCE:\=/!
            
            if exist "!SOURCE!" (
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

popd
echo Import complete.
pause