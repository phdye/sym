# sym.py - Symbolic Link Management Tool

## Overview

`sym.py` is a Python 3 port of the original Perl script `sym.pl`. It manages symbolic links in directory hierarchies by providing functionality to list, remove, and restore symlinks.

## Port Information

- **Original**: `ref/sym.pl` (Perl)
- **Port**: `sym.py` (Python 3.2.5+ compatible)
- **Tested on**: Python 3.12.5 on Windows 11 with Cygwin
- **Port Date**: 2025-10-07

## Features

### Implemented

- ✅ **List** (`--list`): Discover and record all symbolic links in a directory hierarchy
- ✅ **Remove** (`--remove`): Delete symbolic links recorded in a file
- ✅ **Restore** (`--restore`): Recreate symbolic links from a recorded file
- ✅ **Type tracking** (`--type`): Record and validate target types (directory, file, missing, corrupt)
- ✅ **Overwrite** (`--overwrite`): Replace existing files when restoring symlinks
- ✅ **Root directory** (`--root`): Change working directory before processing
- ✅ **Output to file** (`--out`): Save symlink list to a specified file

### Not Yet Implemented

The following features from the original Perl script are marked for future implementation:

- ⏳ **Owner/Group** (`--owner`): Record and restore ownership information
- ⏳ **Native NTFS symlinks** (`--native`): Create native Windows symlinks instead of Cygwin symlinks
- ⏳ **Depth limit** (`--depth`): Limit recursion depth
- ⏳ **Dry run** (`--dry-run`): Show what would be done without making changes
- ⏳ **Extract** (`--extract`): Extract Cygwin symlinks from plain files

## Usage

### Basic Commands

```bash
# Display help
python sym.py --help

# List all symlinks in current directory
python sym.py --list

# List symlinks from specific directories
python sym.py --list src build lib

# Save symlinks to a file
python sym.py --list --out /tmp/symlinks.txt

# Save with type information
python sym.py --list --type --out /tmp/symlinks.txt

# Remove recorded symlinks
python sym.py --remove /tmp/symlinks.txt

# Restore symlinks
python sym.py --restore /tmp/symlinks.txt

# Restore to a different root directory
python sym.py --restore --root /home/new-user /tmp/symlinks.txt

# Restore with overwrite
python sym.py --restore --overwrite /tmp/symlinks.txt

# Restore with type validation
python sym.py --restore --type /tmp/symlinks.txt
```

## File Format

The symlink record file uses a simple text format:

```
# Without type information
<symlink-path> : <target-path>

# With type information (--type flag)
<type> : <symlink-path> : <target-path>
```

Where `<type>` is:
- `d` - target is a directory
- `f` - target is a file
- `m` - target is missing (doesn't exist)
- `c` - target is corrupt (undefined or empty)

### Example

```
d : ./bin/scripts : /usr/local/scripts
f : ./data/config.txt : /etc/app/config.txt
m : ./old-link : /path/that/no/longer/exists
```

## Testing

A test was performed in the `test-symlinks/` directory:

```bash
# Create test structure
mkdir test-symlinks
cd test-symlinks
mkdir target
echo "test content" > target/testfile.txt

# Create a symlink
New-Item -ItemType SymbolicLink -Path "link-to-target" -Target "target"

# List symlinks with type info
python ../sym.py --list --type --out symlinks.txt

# Remove the symlink
python ../sym.py --remove symlinks.txt

# Restore the symlink
python ../sym.py --restore symlinks.txt
```

All operations completed successfully.

## Python Version Compatibility

The code is written to be compatible with Python 3.2.5+:
- No f-strings (uses `.format()` instead)
- No pathlib (uses `os.path` instead)
- Uses `argparse` for command-line parsing
- Standard library only, no external dependencies

However, it has been tested and works perfectly with Python 3.12.5.

## Differences from Original Perl Script

### Behavior
- The Python version uses `argparse` for more robust argument parsing
- Error messages are slightly different but convey the same information
- The Python version is more explicit about mutually exclusive actions

### Implementation
- Uses Python's `os.walk()` instead of Perl's `File::Find`
- Uses context managers (`with` statements) for file handling
- More structured exception handling

### Features Not Yet Ported
- Owner/group tracking and restoration
- Native NTFS symlink creation
- Depth limiting
- Dry-run mode
- Extract mode for Cygwin symlinks from plain files

## Platform Notes

### Windows with Cygwin
- The script works well in Cygwin environments on Windows
- Symlinks are handled as Cygwin-style symbolic links
- Absolute paths in Windows format are converted properly

### Permissions
- On Windows, creating symlinks may require Administrator privileges
- Consider using Developer Mode in Windows 10/11 for unprivileged symlink creation

## Future Enhancements

Priority items for future development:
1. Implement `--owner` flag for ownership tracking
2. Add `--depth` to limit recursion
3. Implement `--dry-run` for preview mode
4. Add `--extract` for Cygwin symlink recovery from archives
5. Support native NTFS symlinks with `--native`
6. Add progress indicators for large directory trees
7. Implement filters for selective symlink operations

## License

This is a port of the original Perl script. Refer to the original script's license terms.

## Contributing

When contributing enhancements, please maintain Python 3.2.5+ compatibility and avoid external dependencies where possible.

## See Also

- Original Perl script: `ref/sym.pl`
- Python documentation on `os.symlink()`: https://docs.python.org/3/library/os.html#os.symlink
