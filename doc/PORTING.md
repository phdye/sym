# Perl to Python Port - Technical Mapping

## Overview

This document describes how the Perl script `sym.pl` was ported to Python `sym.py`.

## Language Feature Mapping

### Command Line Argument Parsing

**Perl (Manual parsing):**
```perl
while ( ( @argv > 0 ) && ( $argv[0] =~ /^[-]./ ) ) {
    my $option = shift @argv ;
    if ( $option =~ /^(-o|--out)$/ ) {
        $config->{output} = shift @argv ;
    }
}
```

**Python (argparse):**
```python
parser = argparse.ArgumentParser(...)
parser.add_argument('-o', '--out', dest='output', metavar='FILE')
args = parser.parse_args()
```

### File Traversal

**Perl (File::Find):**
```perl
use File::Find ;
sub sym_list_wanted {
    return unless ( defined($_) && ( -l $_ ) ) ;
    # process symlink
}
find ( \&sym_list_wanted, $dir ) ;
```

**Python (os.walk):**
```python
for root, dirs_in_root, files in os.walk(directory):
    for name in dirs_in_root + files:
        path = join(root, name)
        if islink(path):
            # process symlink
```

### File Operations

**Perl:**
```perl
# Reading symlinks
my $target = readlink($_);

# Creating symlinks
symlink($target, $symlink);

# Removing files
unlink($symlink);
```

**Python:**
```python
# Reading symlinks
target = os.readlink(path)

# Creating symlinks
os.symlink(target, symlink)

