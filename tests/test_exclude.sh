#!/bin/bash
# Test script for sym.py exclude functionality

echo "Testing sym.py exclude functionality..."
echo

# Test 1: Show help with exclude option
echo "=== Test 1: Show help (verify --exclude is listed) ==="
python3 sym.py --help | grep -A 2 "exclude"
echo

# Test 2: Try to list with exclude option
echo "=== Test 2: List current directory excluding .git ==="
python3 sym.py --list --exclude .git --exclude .claudeflow 2>&1 | head -10
echo

echo "Tests complete!"
