@echo off

set CURRENT_DRIVE=%~d0
set CURRENT_DIR=%~p0
if "%1"=="" (
	set DESTINATION=%CURRENT_DRIVE%%CURRENT_DIR%Chromekeywords.sql
) else (
	set DESTINATION=%~f1
)

set DESTINATION=%DESTINATION:\=/%
set TEMP_SQL_SCRIPT=%TEMP%\sync_chrome_sql_script

pushd
echo Exporting Chrome keywords to %DESTINATION%...
cd /D "%HOMEDRIVE%%HOMEPATH%\AppData\Local\Google\Chrome\User Data\Default"
echo .output "%DESTINATION%" > %TEMP_SQL_SCRIPT%
echo .dump keywords >> %TEMP_SQL_SCRIPT%
"%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" -init %TEMP_SQL_SCRIPT% "Web Data" .exit
del %TEMP_SQL_SCRIPT%
popd

if errorlevel 1 pause
