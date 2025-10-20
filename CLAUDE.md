# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Custom Search Engines Backup & Sync Toolkit for Google Chrome and Microsoft Edge browsers. The project enables users to export, import, and synchronize custom search engine configurations between browsers using Windows batch scripts and SQLite database manipulation.

## Architecture

### Core Technology Stack
- **Language**: Windows Batch Script (.cmd files)
- **Database**: SQLite 3.x (direct database file manipulation)
- **Binary Dependency**: `sqlite3.exe` (bundled in each directory)

### Directory Structure

The project is organized into four independent tools:

1. **Import Export Chrome Custom Search Engines/** - Standalone export/import for Chrome
2. **Import Export Edge Custom Search Engines/** - Standalone export/import for Edge
3. **Overwrite Chrome Custom Search Engines to Edge/** - Direct Chrome → Edge sync
4. **Overwrite Edge Custom Search Engines to Chrome/** - Direct Edge → Chrome sync

### Browser Data Architecture

Both Chrome and Edge store custom search engines in a SQLite database:
- **Database file**: `Web Data` (located in browser profile directories)
- **Table**: `keywords` (contains search engine definitions)
- **Chrome profiles**: `%HOMEDRIVE%%HOMEPATH%\AppData\Local\Google\Chrome\User Data`
- **Edge profiles**: `%HOMEDRIVE%%HOMEPATH%\AppData\Local\Microsoft\Edge\User Data`

### Technical Implementation Patterns

All tools follow these common patterns:
- **Database locking prevention**: Create temporary copies of `Web Data` to avoid conflicts with running browsers
- **Export method**: Use `sqlite3.exe .dump keywords` to generate SQL dump files
- **Import method**: Execute SQL dumps to replace the entire `keywords` table
- **Profile detection**: Scan browser profile directories for profiles containing `Web Data` files
- **Filename sanitization**: Replace spaces, parentheses, and brackets with underscores
- **Temporary file cleanup**: All operations clean up temporary files in `%TEMP%` after execution

## Working with This Codebase

### Testing Tools Locally

**To test export tools**:
```batch
cd "Import Export Chrome Custom Search Engines"
"Export Chrome Custom Search Engines.cmd"
```
or
```batch
cd "Import Export Edge Custom Search Engines"
"Export Edge Custom Search Engines.cmd"
```

**To test import tools**:
```batch
cd "Import Export Chrome Custom Search Engines"
"Import Chrome Custom Search Engines.cmd"
```
or
```batch
cd "Import Export Edge Custom Search Engines"
"Import Edge Custom Search Engines.cmd"
```

**To test synchronization tools**:
```batch
cd "Overwrite Chrome Custom Search Engines to Edge"
"Overwrite Chrome Custom Search Engines to Edge.cmd"
```
or
```batch
cd "Overwrite Edge Custom Search Engines to Chrome"
"Overwrite Edge Custom Search Engines to Chrome.cmd"
```

**Note**: Users should close all browser instances before running these tools to prevent database locking issues.

### Modifying Export/Import Logic

When modifying the database operations:

1. **Export logic** is in the section where `sqlite3.exe` is called with `.dump keywords`
2. **Import logic** is in the section where SQL files are piped into `sqlite3.exe`
3. **Profile detection** logic scans for directories containing `Web Data` files
4. **Temporary database handling** uses `%TEMP%\WebData_temp_%RANDOM%` pattern

### Database Schema

The `keywords` table structure (common to both browsers):
- Core fields: `id`, `short_name`, `keyword`, `favicon_url`, `url`
- Metadata: `safe_for_autoreplace`, `usage_count`, `date_created`, `sync_guid`
- Search features: `suggest_url`, `image_url`, various POST parameters
- Edge-specific fields (140.x+): Additional columns for enhanced search features

### Key Variables and Environment

Batch scripts use these environment variables:
- `HOMEDRIVE` / `HOMEPATH` - User's home directory
- `TEMP` - Windows temporary directory
- `CURRENT_DRIVE` / `CURRENT_DIR` - Script location for accessing `sqlite3.exe`

### Known Edge Cases

1. **Edge 140.x schema changes**: Edge version 140.x introduced new columns to the `keywords` table. When importing older exports to newer Edge versions, the import process needs to handle schema compatibility.

2. **Profile name sanitization**: Profile names with special characters (spaces, parentheses, brackets) are sanitized for filename safety by replacing them with underscores.

3. **Browser locking**: Browsers lock the `Web Data` database when running. Scripts create temporary copies to read/modify without conflicts.

4. **Multiple profile scenarios**: Both tools support selecting individual profiles or processing "all" profiles in batch.

## File Naming Conventions

- **Export files**: `Chromekeywords_[ProfileName].sql` or `Edgekeywords_[ProfileName].sql`
- **Temporary databases**: `WebData_temp_%RANDOM%` (in `%TEMP%`)
- **Backup databases**: Original `Web Data` is temporarily renamed during import operations

## Version Control Notes

- **Do not commit** user-specific `.sql` export files (these contain personal search engine configurations)
- **Do commit** sample `.sql` files that demonstrate the data structure
- **Do commit** `sqlite3.exe` binaries in each tool directory (these are required for functionality)

## Debugging

When troubleshooting issues:

1. Check if browser is fully closed (`tasklist | findstr chrome.exe` or `tasklist | findstr msedge.exe`)
2. Verify profile paths exist and contain `Web Data` files
3. Check `%TEMP%` directory for leftover temporary files
4. Test SQLite operations directly: `sqlite3.exe "Web Data" ".dump keywords"`
5. Examine generated `.sql` files to verify correct export structure
