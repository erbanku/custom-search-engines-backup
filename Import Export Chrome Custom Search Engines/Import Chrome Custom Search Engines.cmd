@echo off

tasklist /FI "IMAGENAME eq chrome.exe" 2>NUL | find /I /N "chrome.exe">NUL
if "%ERRORLEVEL%"=="0" (
	echo Close Chrome and try again...
	pause
	exit /B 1
)

set /P PROCEED=This will overwrite your Google Chrome search engines! Are you sure?  
if "%PROCEED%"=="Y" goto DoIt
if "%PROCEED%"=="y" goto DoIt
if "%PROCEED%"=="YES" goto DoIt
if "%PROCEED%"=="Yes" goto DoIt
if "%PROCEED%"=="yes" goto DoIt
echo Cancelled operation.
pause
exit /B 2

:DoIt
set CURRENT_DRIVE=%~d0
set CURRENT_DIR=%~p0
if "%1"=="" (
	set SOURCE=%CURRENT_DRIVE%%CURRENT_DIR%Chromekeywords.sql
) else (
	set SOURCE=%~f1
)

set SOURCE=%SOURCE:\=/%
set TEMP_SQL_SCRIPT=%TEMP%\sync_chrome_sql_script

pushd
echo Importing Chrome keywords from %SOURCE%...
cd /D "%HOMEDRIVE%%HOMEPATH%\AppData\Local\Google\Chrome\User Data\Default"
echo DROP TABLE IF EXISTS keywords;> %TEMP_SQL_SCRIPT%
echo .read "%SOURCE%">> %TEMP_SQL_SCRIPT%
copy "Web Data" "Web Data.backup"
"%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" -init %TEMP_SQL_SCRIPT% "Web Data" .exit
del %TEMP_SQL_SCRIPT%
popd

if errorlevel 1 pause
