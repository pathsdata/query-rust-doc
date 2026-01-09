#!/bin/bash
set -e

# Fix locale for Sphinx
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Install dependencies
pip install -r requirements.txt

# Build Sphinx documentation using python -m
python -m sphinx -b html source build/html

echo "Documentation built successfully!"
