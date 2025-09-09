@echo off
echo ================================================================================
echo Edge Enhanced Scripts - SQL Operations Test
echo ================================================================================
echo This script tests the SQL operations used by the enhanced scripts.
echo.

set CURRENT_DRIVE=%~d0
set CURRENT_DIR=%~p0
set TEST_DB=%TEMP%\test_web_data.sqlite
set TEMP_SQL_SCRIPT=%TEMP%\test_sql_script

:: Create a test database with sample data
echo Creating test database...
echo CREATE TABLE keywords (id INTEGER PRIMARY KEY, keyword TEXT, short_name TEXT, sync_guid TEXT); > %TEMP_SQL_SCRIPT%
echo CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT); >> %TEMP_SQL_SCRIPT%
echo INSERT INTO keywords VALUES (1, '@tabs', 'Tab Search', NULL); >> %TEMP_SQL_SCRIPT%
echo INSERT INTO keywords VALUES (2, '@history', 'History Search', NULL); >> %TEMP_SQL_SCRIPT%
echo INSERT INTO keywords VALUES (3, 'google', 'Google', 'guid123'); >> %TEMP_SQL_SCRIPT%
echo INSERT INTO keywords VALUES (4, 'bing', 'Bing', 'guid456'); >> %TEMP_SQL_SCRIPT%
echo INSERT INTO meta VALUES ('Default Search Provider ID', '1'); >> %TEMP_SQL_SCRIPT%
echo INSERT INTO meta VALUES ('keywords_last_known_change_time', '2024-01-01'); >> %TEMP_SQL_SCRIPT%

"%CURRENT_DRIVE%%CURRENT_DIR%\Import Export Edge Custom Search Engines\sqlite3.exe" "%TEST_DB%" < %TEMP_SQL_SCRIPT%

echo Test database created. Initial state:
echo.
echo Keywords table:
echo SELECT keyword, short_name, sync_guid FROM keywords; > %TEMP_SQL_SCRIPT%
"%CURRENT_DRIVE%%CURRENT_DIR%\Import Export Edge Custom Search Engines\sqlite3.exe" -header -column "%TEST_DB%" < %TEMP_SQL_SCRIPT%

echo.
echo Meta table:
echo SELECT key, value FROM meta; > %TEMP_SQL_SCRIPT%
"%CURRENT_DRIVE%%CURRENT_DIR%\Import Export Edge Custom Search Engines\sqlite3.exe" -header -column "%TEST_DB%" < %TEMP_SQL_SCRIPT%

echo.
echo ================================================================================
echo Testing Enhanced Script SQL Operations...
echo ================================================================================

:: Test the sync cleanup operations
echo.
echo 1. Testing sync GUID cleanup...
echo DELETE FROM keywords WHERE id IN (SELECT id FROM keywords WHERE sync_guid IS NOT NULL AND keyword NOT IN ('@tabs', '@history', '@bookmarks')); > %TEMP_SQL_SCRIPT%
"%CURRENT_DRIVE%%CURRENT_DIR%\Import Export Edge Custom Search Engines\sqlite3.exe" "%TEST_DB%" < %TEMP_SQL_SCRIPT%

echo After sync GUID cleanup:
echo SELECT keyword, short_name, sync_guid FROM keywords; > %TEMP_SQL_SCRIPT%
"%CURRENT_DRIVE%%CURRENT_DIR%\Import Export Edge Custom Search Engines\sqlite3.exe" -header -column "%TEST_DB%" < %TEMP_SQL_SCRIPT%

echo.
echo 2. Testing meta table updates...
echo UPDATE meta SET value = '0' WHERE key = 'Default Search Provider ID'; > %TEMP_SQL_SCRIPT%
echo UPDATE meta SET value = datetime('now') WHERE key = 'keywords_last_known_change_time'; >> %TEMP_SQL_SCRIPT%
"%CURRENT_DRIVE%%CURRENT_DIR%\Import Export Edge Custom Search Engines\sqlite3.exe" "%TEST_DB%" < %TEMP_SQL_SCRIPT%

echo After meta updates:
echo SELECT key, value FROM meta; > %TEMP_SQL_SCRIPT%
"%CURRENT_DRIVE%%CURRENT_DIR%\Import Export Edge Custom Search Engines\sqlite3.exe" -header -column "%TEST_DB%" < %TEMP_SQL_SCRIPT%

echo.
echo 3. Testing custom search engine count...
echo SELECT COUNT(*) as 'Custom Search Engines' FROM keywords WHERE keyword NOT IN ('@tabs', '@history', '@bookmarks'); > %TEMP_SQL_SCRIPT%
"%CURRENT_DRIVE%%CURRENT_DIR%\Import Export Edge Custom Search Engines\sqlite3.exe" -header -column "%TEST_DB%" < %TEMP_SQL_SCRIPT%

echo.
echo ================================================================================
echo SQL Operations Test Complete!
echo ================================================================================
echo.
echo The enhanced scripts use these SQL operations to:
echo 1. Remove custom search engines with sync GUIDs (prevents conflicts)
echo 2. Reset the default search provider ID
echo 3. Update the last change timestamp
echo 4. Verify the number of imported custom search engines
echo.
echo If you see the expected results above, the enhanced scripts should work correctly.
echo.

:: Cleanup
del %TEMP_SQL_SCRIPT% 2>nul
del %TEST_DB% 2>nul

pause