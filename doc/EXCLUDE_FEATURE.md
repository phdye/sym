# sym.py Exclude Feature Implementation

## Summary

Successfully added `-e` / `--exclude` option to `sym.py` to allow users to exclude specific paths from directory traversal, in addition to the mandatory exclusion of `/dev` and `/proc`.

## Changes Made

### 1. Updated `should_skip_directory()` Function
- Added optional `exclude_paths` parameter
- Enhanced to check user-specified exclusion paths
- Supports both normalized and absolute path matching
- Checks if current path matches or is a subdirectory of excluded paths

### 2. Modified `sym_list()` Function
- Extracts `exclude_paths` from config
- Passes exclude paths to `should_skip_directory()` calls
- Updated warning message to be more generic ("excluded directory" vs "system directory")
- Updated docstring to mention the --exclude option

### 3. Enhanced Argument Parser
- Added `-e PATH` / `--exclude PATH` option
- Uses `action='append'` to allow multiple exclusions
- Added helpful description noting that /dev and /proc are always excluded
- Updated examples to demonstrate exclude usage

### 4. Updated Configuration Dictionary
- Added `'exclude': args.exclude or []` to config dict in `main()`
- Ensures empty list default if no exclusions specified

### 5. Enhanced Help Documentation
- Added new example showing exclude usage with `.git` and `node_modules`
- Added note at end: "Note: /dev and /proc are always excluded from traversal."

## Usage Examples

```bash
# Exclude single directory
sym --list --exclude .git --out symlinks.txt

# Exclude multiple directories
sym --list --exclude .git --exclude node_modules --out symlinks.txt

# Short form
sym -l -e .git -e build -e __pycache__ -o symlinks.txt
```

## Features

- **Multiple exclusions**: Can specify `-e` multiple times
- **Path flexibility**: Works with relative and absolute paths
- **Mandatory exclusions**: `/dev` and `/proc` are always excluded
- **Subdirectory handling**: Excludes entire directory trees
- **Warning messages**: Notifies when directories are skipped

## Testing

Verified functionality:
- ✅ Help text displays new option correctly
- ✅ Option accepts multiple values via repeated `-e` flags
- ✅ Default behavior (no exclusions) works correctly
- ✅ /dev and /proc always excluded regardless of user options

## Compatibility

- Python 3.2+ compatible (no modern syntax used)
- Works in both Windows/Cygwin and pure Unix environments
- Cross-platform path handling (handles both `/` and `\` separators)
