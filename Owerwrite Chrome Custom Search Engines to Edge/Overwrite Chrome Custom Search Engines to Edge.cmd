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


@echo off

set CURRENT_DRIVE=%~d0
set CURRENT_DIR=%~p0
if "%1"=="" (
	set DESTINATION=%CURRENT_DRIVE%%CURRENT_DIR%Edgekeywordsbackup.sql
) else (
	set DESTINATION=%~f1
)

set DESTINATION=%DESTINATION:\=/%
set TEMP_SQL_SCRIPT=%TEMP%\sync_edge_sql_script

pushd
echo Exporting Edge keywords to %DESTINATION%...
cd /D "%HOMEDRIVE%%HOMEPATH%\AppData\Local\Microsoft\Edge\User Data\Profile 1"
echo .output "%DESTINATION%" > %TEMP_SQL_SCRIPT%
echo .dump keywords >> %TEMP_SQL_SCRIPT%
"%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" -init %TEMP_SQL_SCRIPT% "Web Data" .exit
del %TEMP_SQL_SCRIPT%
popd

if errorlevel 1 pause


@echo off

tasklist /FI "IMAGENAME eq edge.exe" 2>NUL | find /I /N "edge.exe">NUL
if "%ERRORLEVEL%"=="0" (
	echo Close Edge and try again...
	pause
	exit /B 1
)

set /P PROCEED=This will overwrite your Microsoft Edge search engines! Are you sure?  
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
set TEMP_SQL_SCRIPT=%TEMP%\sync_edge_sql_script

pushd
echo Importing Chrome keywords from %SOURCE%...
cd /D "%HOMEDRIVE%%HOMEPATH%\AppData\Local\Microsoft\Edge\User Data\Profile 1"
echo DROP TABLE IF EXISTS keywords;> %TEMP_SQL_SCRIPT%
echo .read "%SOURCE%">> %TEMP_SQL_SCRIPT%
copy "Web Data" "Web Data.backup"
"%CURRENT_DRIVE%%CURRENT_DIR%\sqlite3.exe" -init %TEMP_SQL_SCRIPT% "Web Data" .exit
del %TEMP_SQL_SCRIPT%
popd

if errorlevel 1 pause
