@echo off
setlocal EnableDelayedExpansion

set CURRENT_DRIVE=%~d0
set CURRENT_DIR=%~p0
set CHROME_PATH=%HOMEDRIVE%%HOMEPATH%\AppData\Local\Google\Chrome\User Data
set TEMP_SQL_SCRIPT=%TEMP%\sync_chrome_sql_script
set TEMP_DB=%TEMP%\temp_web_data

if "%1"=="" (
    set BASE_DESTINATION=%CURRENT_DRIVE%%CURRENT_DIR%Chromekeywords
) else (
    set BASE_DESTINATION=%~f1
)

pushd
echo WARNING: You should close all Chrome instances before running this script.
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
set /p "selection=Enter profile numbers to export (comma-separated) or 'all' for all profiles: "

:: Process each profile
set profile_num=0
for /d %%P in ("%CHROME_PATH%\*") do (
    if exist "%%P\Web Data" (
        set /a profile_num+=1
        set "export_profile="
        
        :: Check if this profile should be exported
        if /i "!selection!"=="all" (
            set "export_profile=yes"
        ) else (
            for %%n in (!selection!) do (
                if %%n==!profile_num! set "export_profile=yes"
            )
        )
        
        if defined export_profile (
            set "PROFILE_NAME=%%~nxP"
            set DESTINATION=%BASE_DESTINATION%_!PROFILE_NAME!.sql
            set DESTINATION=!DESTINATION:\=/!
            
            echo Exporting Chrome keywords from !PROFILE_NAME! to !DESTINATION!...
            cd /D "%%P"
            
            rem Copy database to temp location to avoid locks
            copy /Y "Web Data" "%TEMP_DB%" >nul
            
            echo .output "!DESTINATION!" > %TEMP_SQL_SCRIPT%
            echo .dump keywords >> %TEMP_SQL_SCRIPT%
            "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" -init %TEMP_SQL_SCRIPT% "%TEMP_DB%" .exit
            
            if exist "!DESTINATION!" (
                for %%F in ("!DESTINATION!") do if %%~zF gtr 0 (
                    echo Successfully exported !PROFILE_NAME!
                ) else (
                    echo Failed to export !PROFILE_NAME! - empty file
                    pause
                )
            ) else (
                echo Failed to export !PROFILE_NAME! - file not created
                pause
            )
            
            rem Clean up temp files
            del %TEMP_SQL_SCRIPT% 2>nul
            del %TEMP_DB% 2>nul
        )
    )
)

popd
echo Export complete.
pause