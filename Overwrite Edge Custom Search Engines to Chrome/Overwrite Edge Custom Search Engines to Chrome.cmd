@echo off
setlocal EnableDelayedExpansion

:: Welcome message
echo WARNING: You should close all Edge and Chrome instances before running this script.
echo This script will overwrite custom search engines in Chrome profiles with those exported ones from Edge profiles.
echo.

set CURRENT_DRIVE=%~d0
set CURRENT_DIR=%~p0
set CHROME_PATH=%HOMEDRIVE%%HOMEPATH%\AppData\Local\Google\Chrome\User Data
set EDGE_PATH=%HOMEDRIVE%%HOMEPATH%\AppData\Local\Microsoft\Edge\User Data
set TEMP_SQL_SCRIPT=%TEMP%\sync_sql_script
set TEMP_DB=%TEMP%\temp_web_data

if "%1"=="" (
    set BASE_DESTINATION=%CURRENT_DRIVE%%CURRENT_DIR%Edgekeywords
) else (
    set BASE_DESTINATION=%~f1
)

pushd

:: List available Edge profiles
set edge_profile_count=0
echo Available Edge profiles:
for /d %%P in ("%EDGE_PATH%\*") do (
    if exist "%%P\Web Data" (
        set /a edge_profile_count+=1
        echo !edge_profile_count!: %%~nxP
        set "edge_profile_!edge_profile_count!=%%~nxP"
    )
)

:: List available Chrome profiles
set chrome_profile_count=0
echo Available Chrome profiles:
for /d %%P in ("%CHROME_PATH%\*") do (
    if exist "%%P\Web Data" (
        set /a chrome_profile_count+=1
        echo !chrome_profile_count!: %%~nxP
        set "chrome_profile_!chrome_profile_count!=%%~nxP"
    )
)

:: Get user selection for Edge and Chrome profile pairs
:select_profiles
set /p "edge_selection=Enter Edge profile number to export (or 'done' to finish after overwrite complete): "
if /i "!edge_selection!"=="done" goto end
set /p "chrome_selection=Enter Chrome profile number to import to: "

:: Process the selected profiles
set "edge_profile=!edge_profile_%edge_selection%!"
set "chrome_profile=!chrome_profile_%chrome_selection%!"

set DESTINATION=%BASE_DESTINATION%_!edge_profile!.sql
set DESTINATION=!DESTINATION:\=/!

echo Exporting Edge keywords from !edge_profile! to !DESTINATION!...
cd /D "%EDGE_PATH%\!edge_profile!"

rem Copy database to temp location to avoid locks
copy /Y "Web Data" "%TEMP_DB%" >nul

echo .output "!DESTINATION!" > %TEMP_SQL_SCRIPT%
echo .dump keywords >> %TEMP_SQL_SCRIPT%
"%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" -init %TEMP_SQL_SCRIPT% "%TEMP_DB%" .exit

if exist "!DESTINATION!" (
    for %%F in ("!DESTINATION!") do if %%~zF gtr 0 (
        echo Successfully exported !edge_profile!
    ) else (
        echo Failed to export !edge_profile! - empty file
        pause
    )
) else (
    echo Failed to export !edge_profile! - file not created
    pause
)

rem Clean up temp files
del %TEMP_SQL_SCRIPT% 2>nul
del %TEMP_DB% 2>nul

set SOURCE=%BASE_DESTINATION%_!edge_profile!.sql
set SOURCE=!SOURCE:\=/!

if exist "!SOURCE!" (
    echo Importing Chrome keywords to !chrome_profile! from !SOURCE!...
    cd /D "%CHROME_PATH%\!chrome_profile!"
    
    rem Copy database to temp location to avoid locks
    copy /Y "Web Data" "%TEMP_DB%" >nul
    
    "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" "%TEMP_DB%" < "!SOURCE!"
    
    rem Replace the original database with the updated one
    copy /Y "%TEMP_DB%" "Web Data" >nul
    
    echo Successfully imported keywords to !chrome_profile!
    
    rem Clean up temp files
    del %TEMP_DB% 2>nul
) else (
    echo Source file for !chrome_profile! not found: !SOURCE!
    pause
)

goto select_profiles

:end
popd
echo Operation complete.
pause