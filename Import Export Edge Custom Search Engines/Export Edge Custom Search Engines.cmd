@echo off
setlocal EnableDelayedExpansion

set CURRENT_DRIVE=%~d0
set CURRENT_DIR=%~p0
set EDGE_PATH=%HOMEDRIVE%%HOMEPATH%\AppData\Local\Microsoft\Edge\User Data
set TEMP_SQL_SCRIPT=%TEMP%\sync_edge_sql_script
set TEMP_DB=%TEMP%\temp_web_data

if "%1"=="" (
    set BASE_DESTINATION=%CURRENT_DRIVE%%CURRENT_DIR%Edgekeywords
) else (
    set BASE_DESTINATION=%~f1
)

pushd
echo WARNING: You should close all Edge instances before running this script.
:: List available profiles
set profile_count=0
echo Available Edge profiles:
for /d %%P in ("%EDGE_PATH%\*") do (
    if exist "%%P\Web Data" (
        set /a profile_count+=1
        echo !profile_count!: %%~nxP
    )
)

:: Get user selection
:get_selection
set /p "selection=Enter profile numbers to export (comma-separated) or 'all' for all profiles: "

:: Validate selection
if "!selection!"=="" (
    echo Error: No selection entered. Please try again.
    goto get_selection
)

:: Remove spaces from selection for better parsing
set "selection=!selection: =!"

:: Process each profile
set profile_num=0
set selected_count=0
for /d %%P in ("%EDGE_PATH%\*") do (
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
            set /a selected_count+=1
            set "PROFILE_NAME=%%~nxP"
            
            :: Sanitize profile name for filename (replace problematic characters)
            set "SAFE_PROFILE_NAME=!PROFILE_NAME: =_!"
            set "SAFE_PROFILE_NAME=!SAFE_PROFILE_NAME:(=_!"
            set "SAFE_PROFILE_NAME=!SAFE_PROFILE_NAME:)=_!"
            set "SAFE_PROFILE_NAME=!SAFE_PROFILE_NAME:[=_!"
            set "SAFE_PROFILE_NAME=!SAFE_PROFILE_NAME:]=_!"
            
            set DESTINATION=%BASE_DESTINATION%_!SAFE_PROFILE_NAME!.sql
            set DESTINATION=!DESTINATION:\=/!
            
            echo Exporting Edge keywords from !PROFILE_NAME! to !DESTINATION!...
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

:: Validate that at least one profile was processed
if !selected_count! equ 0 (
    echo.
    echo Warning: No profiles were selected or found matching your selection.
    if not "!selection!"=="all" (
        echo Please ensure you entered valid profile numbers from 1 to !profile_count!.
    )
    echo.
    pause
    goto end
)

popd
echo.
echo Export complete. Processed !selected_count! profile(s).
:end
pause