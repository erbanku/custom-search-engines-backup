@echo off
setlocal EnableDelayedExpansion

:: Enhanced Overwrite Script for Edge 140.x and newer
echo ================================================================================
echo Enhanced Chrome to Edge Search Engine Transfer (v2.0)
echo Compatible with Edge 140.x and newer versions
echo ================================================================================
echo.
echo CRITICAL STEPS - DO NOT SKIP:
echo 1. Close ALL Chrome and Edge instances completely
echo 2. In Edge: Disable search engine sync (edge://settings/ ^> Profiles ^> Sync)
echo 3. Wait 30 seconds after disabling sync
echo 4. Only then proceed with this script
echo.
echo This script will transfer search engines and prevent Edge from overwriting them.
echo ================================================================================
echo.

set /p "sync_confirm=Have you disabled Edge search engine sync? (y/N): "
if /i not "!sync_confirm!"=="y" (
    echo.
    echo Please disable Edge sync first:
    echo 1. Open Edge and go to edge://settings/
    echo 2. Navigate to Profiles ^> Sync
    echo 3. Turn OFF "Search engines" toggle
    echo 4. Wait 30 seconds, then rerun this script
    pause
    exit /b 1
)

set CURRENT_DRIVE=%~d0
set CURRENT_DIR=%~p0
set CHROME_PATH=%HOMEDRIVE%%HOMEPATH%\AppData\Local\Google\Chrome\User Data
set EDGE_PATH=%HOMEDRIVE%%HOMEPATH%\AppData\Local\Microsoft\Edge\User Data
set TEMP_SQL_SCRIPT=%TEMP%\sync_sql_script
set TEMP_DB=%TEMP%\temp_web_data

if "%1"=="" (
    set BASE_DESTINATION=%CURRENT_DRIVE%%CURRENT_DIR%Chromekeywords
) else (
    set BASE_DESTINATION=%~f1
)

pushd

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

if !chrome_profile_count! EQU 0 (
    echo No Chrome profiles found. Please ensure Chrome is installed.
    pause
    exit /b 1
)

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

if !edge_profile_count! EQU 0 (
    echo No Edge profiles found. Please ensure Edge is installed.
    pause
    exit /b 1
)

:: Enhanced profile transfer process
:select_profiles
echo.
echo ============================================================
set /p "chrome_selection=Enter Chrome profile number to export (or 'done' to finish): "
if /i "!chrome_selection!"=="done" goto end

if !chrome_selection! LEQ 0 if !chrome_selection! GTR !chrome_profile_count! (
    echo Invalid Chrome profile number. Please try again.
    goto select_profiles
)

set /p "edge_selection=Enter Edge profile number to import to: "
if !edge_selection! LEQ 0 if !edge_selection! GTR !edge_profile_count! (
    echo Invalid Edge profile number. Please try again.
    goto select_profiles
)

:: Process the selected profiles
set "chrome_profile=!chrome_profile_%chrome_selection%!"
set "edge_profile=!edge_profile_%edge_selection%!"

set DESTINATION=%BASE_DESTINATION%_!chrome_profile!.sql
set DESTINATION=!DESTINATION:\=/!

echo.
echo ============================================================
echo Transferring from Chrome profile: !chrome_profile!
echo To Edge profile: !edge_profile!
echo ============================================================

echo Step 1: Exporting Chrome keywords...
cd /D "%CHROME_PATH%\!chrome_profile!"

rem Copy database to temp location to avoid locks
copy /Y "Web Data" "%TEMP_DB%" >nul

echo .output "!DESTINATION!" > %TEMP_SQL_SCRIPT%
echo .dump keywords >> %TEMP_SQL_SCRIPT%
"%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" -init %TEMP_SQL_SCRIPT% "%TEMP_DB%" .exit

if exist "!DESTINATION!" (
    for %%F in ("!DESTINATION!") do if %%~zF gtr 0 (
        echo ✓ Successfully exported !chrome_profile!
    ) else (
        echo ✗ Failed to export !chrome_profile! - empty file
        pause
        goto select_profiles
    )
) else (
    echo ✗ Failed to export !chrome_profile! - file not created
    pause
    goto select_profiles
)

rem Clean up temp files
del %TEMP_SQL_SCRIPT% 2>nul
del %TEMP_DB% 2>nul

echo Step 2: Preparing Edge profile for import...
set SOURCE=%BASE_DESTINATION%_!chrome_profile!.sql
set SOURCE=!SOURCE:\=/!

if exist "!SOURCE!" (
    cd /D "%EDGE_PATH%\!edge_profile!"
    
    :: Create backup
    set BACKUP_DB="%TEMP%\Edge_Web_Data_backup_!edge_profile!.sqlite"
    copy /Y "Web Data" !BACKUP_DB! >nul
    echo ✓ Created backup at !BACKUP_DB!
    
    rem Copy database to temp location to avoid locks
    copy /Y "Web Data" "%TEMP_DB%" >nul
    
    echo Step 3: Clearing existing custom search engines and sync data...
    :: Enhanced cleanup for modern Edge
    echo BEGIN TRANSACTION; > %TEMP_SQL_SCRIPT%
    echo DELETE FROM keywords WHERE id NOT IN (SELECT id FROM keywords WHERE keyword IN ('@tabs', '@history', '@bookmarks')); >> %TEMP_SQL_SCRIPT%
    echo UPDATE meta SET value = '0' WHERE key = 'Default Search Provider ID'; >> %TEMP_SQL_SCRIPT%
    echo DELETE FROM meta WHERE key LIKE '%%sync%%' AND key LIKE '%%search%%'; >> %TEMP_SQL_SCRIPT%
    echo UPDATE meta SET value = datetime('now') WHERE key = 'keywords_last_known_change_time'; >> %TEMP_SQL_SCRIPT%
    echo COMMIT; >> %TEMP_SQL_SCRIPT%
    
    "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" "%TEMP_DB%" < %TEMP_SQL_SCRIPT%
    
    echo Step 4: Importing Chrome search engines...
    "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" "%TEMP_DB%" < "!SOURCE!"
    
    echo Step 5: Finalizing import and preventing sync override...
    :: Additional sync prevention measures
    echo BEGIN TRANSACTION; > %TEMP_SQL_SCRIPT%
    echo UPDATE meta SET value = datetime('now') WHERE key = 'keywords_last_known_change_time'; >> %TEMP_SQL_SCRIPT%
    echo INSERT OR REPLACE INTO meta (key, value) VALUES ('search_engine_sync_disabled', '1'); >> %TEMP_SQL_SCRIPT%
    echo COMMIT; >> %TEMP_SQL_SCRIPT%
    
    "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" "%TEMP_DB%" < %TEMP_SQL_SCRIPT%
    
    rem Replace the original database with the updated one
    copy /Y "%TEMP_DB%" "Web Data" >nul
    
    :: Verify import
    echo Step 6: Verifying import...
    echo SELECT COUNT(*) FROM keywords WHERE keyword NOT IN ('@tabs', '@history', '@bookmarks'); > %TEMP_SQL_SCRIPT%
    "%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" "Web Data" < %TEMP_SQL_SCRIPT% > "%TEMP%\verify_result"
    set /p keyword_count=<"%TEMP%\verify_result"
    
    if !keyword_count! GTR 0 (
        echo ✓ Successfully imported !keyword_count! search engines to !edge_profile!
        echo.
        echo IMPORTANT: Start Edge now and verify your search engines BEFORE re-enabling sync!
    ) else (
        echo ✗ WARNING: No custom search engines found after import
        echo   Backup available at !BACKUP_DB!
    )
    
    rem Clean up temp files
    del %TEMP_DB% 2>nul
    del "%TEMP%\verify_result" 2>nul
    
) else (
    echo ✗ Source file not found: !SOURCE!
    pause
)

rem Clean up export files
del %TEMP_SQL_SCRIPT% 2>nul
del "!SOURCE!" 2>nul

echo.
echo Profile transfer complete!
echo ============================================================
goto select_profiles

:end
popd
echo.
echo ================================================================================
echo All transfers complete!
echo ================================================================================
echo.
echo NEXT STEPS:
echo 1. Start Edge and verify your search engines are present
echo 2. Test a few search engines to ensure they work
echo 3. Only after successful verification, consider re-enabling sync
echo.
echo If search engines disappear after Edge restart:
echo - Keep sync disabled
echo - Restore from backup if needed
echo - Contact support with your Edge version details
echo.
echo Backup files are stored in: %TEMP%
echo ================================================================================
pause