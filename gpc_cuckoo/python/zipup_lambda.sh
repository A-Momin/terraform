#!/bin/bash

# Create a directory to put things in
echo "Creating 'setup' directory"
mkdir setup

# Move the relevant files into setup directory
echo "Moving function file(s) to setup dir"
cp python/cuckoo.py setup/
cd ./setup

# Install requirements 
echo "pip installing requirements from requirements file in target directory"
pip install -r ../python/requirements.txt -t .

cd ..