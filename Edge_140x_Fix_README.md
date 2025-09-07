# Edge Search Engine Import Fix for Edge 140.x and Newer

## Problem
Modern Edge versions (140.x and newer) overwrite custom search engines after import due to enhanced sync mechanisms.

## Root Cause
Edge now uses more aggressive sync processes that override local database changes, treating imported search engines as "foreign" data.

## Enhanced Solution

### NEW Enhanced Scripts
- `Import Edge Custom Search Engines Enhanced.cmd` - Improved import with sync handling
- `Overwrite Chrome Custom Search Engines to Edge Enhanced.cmd` - Enhanced transfer with sync prevention

### Key Improvements
1. **Sync Disable Requirement**: Scripts now require users to disable Edge search engine sync first
2. **Backup Creation**: Automatic backup creation before import
3. **Sync Metadata Cleanup**: Clears sync-related metadata that causes overwrites
4. **Verification Steps**: Confirms successful import before completion
5. **Post-Import Instructions**: Clear guidance for maintaining imported search engines

### Usage Instructions

#### Before Running ANY Script:
1. **Close all Edge instances completely**
2. **Disable Edge sync for search engines:**
   - Open Edge Settings (`edge://settings/`)
   - Navigate to `Profiles > Sync`
   - Turn OFF the "Search engines" toggle
   - Wait 30 seconds for sync to complete
3. **Then run the enhanced script**

#### After Import:
1. Start Edge and verify search engines are present
2. Test a few search engines to ensure they work
3. **Only after successful verification**, consider re-enabling sync

### Technical Changes

#### Sync Prevention Measures:
- Clear existing sync GUIDs for custom search engines
- Update metadata timestamps to make Edge treat data as current
- Remove sync-related metadata entries
- Add sync disable markers

#### Database Operations:
```sql
-- Clear sync metadata for custom engines
DELETE FROM keywords WHERE id IN (
    SELECT id FROM keywords 
    WHERE sync_guid IS NOT NULL 
    AND keyword NOT IN ('@tabs', '@history', '@bookmarks')
);

-- Reset search provider ID
UPDATE meta SET value = '0' WHERE key = 'Default Search Provider ID';

-- Update timestamps
UPDATE meta SET value = datetime('now') WHERE key = 'keywords_last_known_change_time';

-- Clear sync metadata
DELETE FROM meta WHERE key LIKE '%sync%' AND key LIKE '%search%';
```

### Troubleshooting

#### If Search Engines Still Disappear:
1. Ensure sync is completely disabled (not just search engines)
2. Check if Edge is signed in to Microsoft account (sign out temporarily)
3. Clear Edge sync data completely
4. Use backup files to restore and retry

#### Backup Locations:
- Backups are automatically created in `%TEMP%` folder
- Named: `Web_Data_backup_[ProfileName].sqlite`
- Restore by copying back to profile folder

### Compatibility
- Tested with Edge 140.x and newer
- Backwards compatible with older Edge versions
- Works with multiple Edge profiles

### Original Scripts
The original scripts remain available for older Edge versions or if enhanced scripts cause issues.