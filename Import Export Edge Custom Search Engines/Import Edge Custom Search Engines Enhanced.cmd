@echo off
setlocal EnableDelayedExpansion

set CURRENT_DRIVE=%~d0
set CURRENT_DIR=%~p0
set EDGE_PATH=%HOMEDRIVE%%HOMEPATH%\AppData\Local\Microsoft\Edge\User Data
set TEMP_SQL_SCRIPT=%TEMP%\sync_edge_sql_script
set TEMP_DB=%TEMP%\temp_web_data

if "%1"=="" (
    set BASE_SOURCE=%CURRENT_DRIVE%%CURRENT_DIR%Edgekeywords
) else (
    set BASE_SOURCE=%~f1
)

pushd

:: Enhanced warning for sync issues
echo ================================================================================
echo IMPORTANT: Enhanced Import Process for Edge 140.x and newer
echo ================================================================================
echo.
echo Before running this script, you MUST:
echo 1. Close ALL Edge instances completely
echo 2. Disable Edge sync for search engines:
echo    - Open Edge Settings (edge://settings/)
echo    - Go to Profiles ^> Sync
echo    - Turn OFF "Search engines" sync
echo    - Wait 30 seconds for sync to complete
echo 3. Only then run this script
echo.
echo After import, you can re-enable sync if desired.
echo ================================================================================
echo.

set /p "confirm=Have you completed all the above steps? (y/N): "
if /i not "!confirm!"=="y" (
    echo Script cancelled. Please complete the required steps first.
    pause
    exit /b 1
)

:: List available profiles
set profile_count=0
echo Available Edge profiles:
for /d %%P in ("%EDGE_PATH%\*") do (
    if exist "%%P\Web Data" (
        set /a profile_count+=1
        echo !profile_count!: %%~nxP
    )
)

if !profile_count! EQU 0 (
    echo No Edge profiles found with Web Data. Please ensure Edge is properly installed.
    pause
    exit /b 1
)

:: Get user selection
set /p "selection=Enter profile numbers to import (comma-separated) or 'all' for all profiles: "

:: Process each profile
set profile_num=0
for /d %%P in ("%EDGE_PATH%\*") do (
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
                echo.
                echo ============================================================
                echo Processing profile: !PROFILE_NAME!
                echo ============================================================
                echo Importing Edge keywords to !PROFILE_NAME! from !SOURCE!...
                cd /D "%%P"
                
                :: Create backup of current database
                set BACKUP_DB="%TEMP%\Web_Data_backup_!PROFILE_NAME!.sqlite"
                copy /Y "Web Data" !BACKUP_DB! >nul
                echo Created backup at !BACKUP_DB!
                
                :: Copy database to temp location to avoid locks
                copy /Y "Web Data" "%TEMP_DB%" >nul
                
                :: Enhanced import process with sync table cleanup
                echo Clearing sync metadata to prevent override...
                echo DELETE FROM keywords WHERE id IN (SELECT id FROM keywords WHERE sync_guid IS NOT NULL AND keyword NOT IN ('@tabs', '@history', '@bookmarks')); > %TEMP_SQL_SCRIPT%
                echo UPDATE meta SET value = '0' WHERE key = 'Default Search Provider ID'; >> %TEMP_SQL_SCRIPT%
                
                "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" "%TEMP_DB%" < %TEMP_SQL_SCRIPT%
                
                :: Import the keywords
                echo Importing custom search engines...
                "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" "%TEMP_DB%" < "!SOURCE!"
                
                :: Clear additional sync-related metadata
                echo Updating sync metadata...
                echo UPDATE meta SET value = datetime('now') WHERE key = 'keywords_last_known_change_time'; > %TEMP_SQL_SCRIPT%
                echo DELETE FROM meta WHERE key LIKE '%%sync%%' AND key LIKE '%%search%%'; >> %TEMP_SQL_SCRIPT%
                
                "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" "%TEMP_DB%" < %TEMP_SQL_SCRIPT%
                
                :: Replace the original database with the updated one
                copy /Y "%TEMP_DB%" "Web Data" >nul
                
                :: Verify import
                echo Verifying import...
                echo SELECT COUNT(*) FROM keywords WHERE keyword NOT IN ('@tabs', '@history', '@bookmarks'); > %TEMP_SQL_SCRIPT%
                "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" "Web Data" < %TEMP_SQL_SCRIPT% > "%TEMP%\verify_result"
                set /p keyword_count=<"%TEMP%\verify_result"
                
                if !keyword_count! GTR 0 (
                    echo Successfully imported !keyword_count! custom search engines to !PROFILE_NAME!
                ) else (
                    echo WARNING: No custom search engines found after import to !PROFILE_NAME!
                    echo Backup available at !BACKUP_DB!
                )
                
                :: Clean up temp files
                del %TEMP_SQL_SCRIPT% 2>nul
                del %TEMP_DB% 2>nul
                del "%TEMP%\verify_result" 2>nul
                
                echo.
                echo Profile !PROFILE_NAME! processing complete.
                
            ) else (
                echo Source file for !PROFILE_NAME! not found: !SOURCE!
                echo Please ensure you have exported keywords for this profile first.
                pause
            )
        )
    )
)

popd
echo.
echo ================================================================================
echo Import process complete!
echo ================================================================================
echo.
echo IMPORTANT POST-IMPORT STEPS:
echo 1. Start Edge and verify your custom search engines are present
echo 2. If search engines are missing, DO NOT restart Edge yet
echo 3. Check Edge Settings ^> Search engine to confirm import
echo 4. Only after verification, you may re-enable search engine sync if desired
echo.
echo If you encounter issues:
echo - Backups were created in %TEMP% folder
echo - Disable Edge sync completely and retry
echo - Contact support with your Edge version details
echo.
pause