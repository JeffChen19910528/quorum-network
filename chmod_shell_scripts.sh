#!/bin/bash

# Script to change permissions of all shell scripts in the current directory to 777

# Find all files with .sh extension in the current directory
# and change their permissions to 777
find . -maxdepth 1 -name "*.sh" -type f -exec chmod 777 {} +

echo "Permissions of all .sh files in the current directory have been changed to 777."
echo "Please be cautious, as this permission setting allows anyone to read, write, and execute these scripts."

# Optionally, list the files that were modified
echo "Modified files:"
ls -l *.sh