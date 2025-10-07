#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sym.py - Symbolic link management tool
Port of sym.pl to Python 3.2.5 for Cygwin

Manages symbolic links in directory hierarchies: list, remove, and restore.
"""

import sys
import os
import argparse
import stat
from os.path import join, islink, exists, isdir, isfile


# Python 3.2 compatibility note:
# - Using os.walk instead of pathlib (pathlib added in 3.4)
# - Not using f-strings (added in 3.6)
# - Using format() instead of f-strings


def usage_error(message):
    """Print error message and usage, then exit."""
    sys.stderr.write("\nError: {}\n".format(message))
    sys.stderr.write("\nUse --help for usage information.\n\n")
    sys.exit(1)


def warning(message, *args):
    """Print warning message to stderr."""
    if args:
        message = message.format(*args)
    sys.stderr.write("warning: {}\n".format(message))


def fatal(message, *args):
    """Print error message to stderr and exit."""
    if args:
        message = message.format(*args)
    sys.stderr.write("error: {}\n".format(message))
    sys.exit(1)


def target_type(target):
    """
    Determine target type.
    Returns:
        'c' - corrupt (undefined or empty)
        'm' - missing (doesn't exist)
        'd' - directory
        'f' - file
    """
    if not target or len(target) == 0:
        return 'c'  # corrupt
    
    if not exists(target):
        return 'm'  # missing
    
    if isdir(target):
        return 'd'  # directory
    
    return 'f'  # file


def sym_list(config, dirs):
    """
    List all symbolic links in the specified directories.
    
    Args:
        config: Configuration dictionary with options
        dirs: List of directories to search
    """
    if not dirs:
        dirs = ['.']
    
    # Open output file or use stdout
    if config.get('output'):
        try:
            out = open(config['output'], 'w')
        except IOError as e:
            fatal("Unable to create/write output file '{}' - {}",
                  config['output'], str(e))
    else:
        out = sys.stdout
    
    try:
        for directory in dirs:
            for root, dirs_in_root, files in os.walk(directory):
                # Check all entries in the directory
                for name in dirs_in_root + files:
                    path = join(root, name)
                    
                    if islink(path):
                        try:
                            target = os.readlink(path)
                        except OSError as e:
                            warning("Unable to read symlink target value for '{}' - {}",
                                    path, str(e))
                            target = ''
                        
                        # Build output line
                        type_str = ''
                        if config.get('type'):
                            type_str = target_type(target) + ' : '
                        
                        out.write("{}{} : {}\n".format(type_str, path, target or ''))
    finally:
        if config.get('output'):
            out.close()
    
    return 0


def sym_restore(config, files):
    """
    Restore symbolic links from recorded files.
    
    Args:
        config: Configuration dictionary with options
        files: List of files containing symlink records
    """
    for file in files:
        sym_restore_worker(config, file)
    
    return 0


def sym_restore_worker(config, file):
    """Worker function to restore symlinks from a single file."""
    try:
        with open(file, 'r') as slist:
            for line in slist:
                line = line.strip()
                
                # Skip comments
                if line.startswith('#'):
                    continue
                
                # Parse line: [ <type> : ] <symlink> : <target>
                values = [v.strip() for v in line.split(' : ')]
                
                if len(values) > 2:
                    type_val = values[0]
                    symlink = values[1]
                    target = values[2]
                else:
                    type_val = None
                    symlink = values[0] if len(values) > 0 else None
                    target = values[1] if len(values) > 1 else None
                
                if not symlink:
                    continue
                
                # Check target type if requested
                if config.get('type') and type_val:
                    type_now = target_type(target)
                    if type_val != type_now:
                        warning("Target type mismatch, expected '{}', found '{}' for '{}'",
                                type_val, type_now, target or '')
                        continue
                
                # Check if symlink already exists
                if islink(symlink) or exists(symlink):
                    if not config.get('overwrite'):
                        continue
                    try:
                        os.unlink(symlink)
                    except OSError as e:
                        warning("Unable to remove existing symlink file '{}' - {}",
                                symlink, str(e))
                        continue
                
                # Create the symlink
                print("{} : '{}'".format(symlink, target or ''))
                try:
                    os.symlink(target, symlink)
                except OSError as e:
                    warning("Unable to create symlink '{}' for '{}' - {}",
                            symlink, target, str(e))
    
    except IOError as e:
        fatal("Unable to open symlink file '{}' - {}", file, str(e))
    
    return 0


def sym_remove(config, files):
    """
    Remove symbolic links recorded in files.
    
    Args:
        config: Configuration dictionary with options
        files: List of files containing symlink records
    """
    for file in files:
        sym_remove_worker(config, file)
    
    return 0


def sym_remove_worker(config, file):
    """Worker function to remove symlinks from a single file."""
    try:
        with open(file, 'r') as slist:
            for line in slist:
                line = line.strip()
                
                # Parse line: [ <type> : ] <symlink> : <target>
                values = [v.strip() for v in line.split(' : ')]
                
                if len(values) > 2:
                    type_val = values[0]
                    symlink = values[1]
                    target = values[2]
                else:
                    type_val = None
                    symlink = values[0] if len(values) > 0 else None
                    target = values[1] if len(values) > 1 else None
                
                if not symlink:
                    continue
                
                print("{} : '{}'".format(symlink, target or ''))
                
                if not islink(symlink):
                    warning("'{}' symlink file is missing", symlink)
                    continue
                
                try:
                    os.unlink(symlink)
                except OSError as e:
                    warning("Unable to remove existing symlink file '{}' - {}",
                            symlink, str(e))
    
    except IOError as e:
        fatal("Unable to open symlink file '{}' - {}", file, str(e))
    
    return 0


def create_parser():
    """Create and configure argument parser."""
    parser = argparse.ArgumentParser(
        description='List (record) or restore file symlinks for a directory hierarchy.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:

  # Save symlinks from the current directory downward:
  sym --list --out /tmp/symlinks.txt

  # Save symlinks from {src,build,lib} and downward:
  sym --list --out /tmp/symlinks.txt src build lib

  # Remove the recorded symlinks:
  sym --remove /tmp/symlinks.txt

  # Restore the recorded symlinks:
  sym --restore /tmp/symlinks.txt

  # Restore the recorded symlinks to the specified root:
  sym --restore --root /home/new-user /tmp/symlinks.txt

  # Also save owner and group info (note: not yet implemented):
  sym --list --owner --out /tmp/symlinks.txt

  # Restore with owner/group (note: not yet implemented):
  sym --restore --owner /tmp/symlinks.txt
        """
    )
    
    # Actions (mutually exclusive)
    action_group = parser.add_mutually_exclusive_group(required=True)
    action_group.add_argument('-l', '--list',
                              action='store_true',
                              help="List the file symlinks of '.' unless one or more other "
                                   "directories are specified.")
    action_group.add_argument('--remove',
                              action='store_true',
                              help="Remove the symlink files recorded in <file>.")
    action_group.add_argument('--restore',
                              action='store_true',
                              help="Restore the file symlinks in <file> to '.' unless another "
                                   "root is specified using '--root'.")
    
    # Options
    parser.add_argument('-v', '--verbose',
                        action='count',
                        default=0,
                        help="Print more verbose output, if any such is available.")
    parser.add_argument('-o', '--out',
                        dest='output',
                        metavar='FILE',
                        help="For LIST action, write symlinks to FILE.")
    parser.add_argument('--overwrite',
                        action='store_true',
                        help="Overwrite files found where a symlink belongs. "
                             "Only applicable for '--restore'.")
    parser.add_argument('--owner',
                        action='store_true',
                        help="list/extract - record link owner and group (not yet implemented). "
                             "restore - after create, assign owner and group to symlink itself "
                             "(not yet implemented).")
    parser.add_argument('-t', '--type',
                        action='store_true',
                        help="list/extract - record if target is a [d]irectory, a [f]ile, "
                             "[m]issing or [c]orrupt. "
                             "restore - if target type does not match, do not create symlink.")
    parser.add_argument('--root',
                        metavar='DIR',
                        help="Change to DIR before processing (restore action).")
    
    # Arguments
    parser.add_argument('args',
                        nargs='*',
                        metavar='PATH',
                        help="Directories to list (for --list) or files to process "
                             "(for --remove/--restore)")
    
    return parser


def main():
    """Main entry point."""
    parser = create_parser()
    args = parser.parse_args()
    
    # Build config dictionary
    config = {
        'verbose': args.verbose,
        'output': args.output,
        'overwrite': args.overwrite,
        'owner': args.owner,
        'type': args.type,
        'root': args.root or '.'
    }
    
    # Change to root directory if specified
    if config['root'] != '.':
        try:
            os.chdir(config['root'])
        except OSError as e:
            fatal("Unable to move to directory '{}' - {}", config['root'], str(e))
    
    # Determine action and execute
    if args.list:
        return sym_list(config, args.args)
    elif args.remove:
        if not args.args:
            usage_error("--remove requires at least one file argument")
        return sym_remove(config, args.args)
    elif args.restore:
        if not args.args:
            usage_error("--restore requires at least one file argument")
        return sym_restore(config, args.args)
    else:
        usage_error("No action specified")


if __name__ == '__main__':
    sys.exit(main())
