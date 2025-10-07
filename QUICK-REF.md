# sym.py Quick Reference

## Common Use Cases

### Backup symlinks before system changes
```bash
cd /important/directory
python3.2 sym.py --list --type --out ~/symlinks-backup.txt
```

### Move directory tree and restore symlinks
```bash
# Before move - save symlinks
python3.2 sym.py --list --out /tmp/links.txt

# After move - restore symlinks
cd /new/location
python3.2 sym.py --restore /tmp/links.txt
```

### Clean up broken symlinks
```bash
# List with type info
python3.2 sym.py --list --type --out /tmp/all-links.txt

# Review file - find 'm' (missing) targets
grep "^m :" /tmp/all-links.txt

# Remove only those broken links (edit file first)
python3.2 sym.py --remove /tmp/broken-links.txt
```

### Archive directory structure
```bash
# Save symlinks separately
python3.2 sym.py --list --type --out symlinks.txt

# Archive without following symlinks
tar czf archive.tar.gz --exclude=symlinks.txt .

# Later: extract and restore symlinks
tar xzf archive.tar.gz
python3.2 sym.py --restore symlinks.txt
```

### Migrate user home directory
```bash
# Old location
cd /home/olduser
python3.2 sym.py --list --type --out ~/migration-links.txt

# New location
cd /home/newuser
python3.2 sym.py --restore --overwrite ~/migration-links.txt
```

## Options Quick Reference

| Option | Description |
|--------|-------------|
| `--list` | List symlinks (action) |
| `--remove` | Remove symlinks (action) |
| `--restore` | Restore symlinks (action) |
| `-t, --type` | Track/validate target types |
| `-o FILE, --out FILE` | Output file for list |
| `--overwrite` | Replace existing files |
| `--root DIR` | Change to DIR first |
| `-v, --verbose` | More output (accepted, not used) |
| `--owner` | Owner/group (not implemented) |
| `-h, --help` | Show help |

## Target Types

When using `--type`:

- `d` = Directory
- `f` = File  
- `m` = Missing (target doesn't exist)
- `c` = Corrupt (empty or undefined)

## File Format

```
[type :] symlink-path : target-path
```

Examples:
```
d : ./link-to-dir : /usr/local/share
f : ./config : /etc/app.conf
m : ./broken : /no/such/path
```

## Tips

1. **Always use `--type`** when you want to validate targets during restore
2. **Use `--overwrite` carefully** - it removes existing files without backup
3. **Relative paths** in symlinks may show as missing if evaluated from wrong context
4. **Test first** - try operations on a test directory before production use
5. **Keep records safe** - symlink files are your backup, protect them

## Troubleshooting

### "Permission denied" when creating symlinks
- On Windows: Run as Administrator or enable Developer Mode
- On Unix: Check directory permissions

### Symlinks not recreated during restore
- Check if file exists (use `--overwrite` to replace)
- Verify target type matches (if using `--type`)

### Relative symlinks show as missing
- This is normal if the relative path doesn't work from current directory
- Symlinks will still be created correctly

## Return Codes

- `0` = Success
- `1` = Error (with error message to stderr)
