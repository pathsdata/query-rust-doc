#!/bin/bash
set -e

# Install dependencies
pip install -r requirements.txt

# Build Sphinx documentation using python -m
python -m sphinx -b html source build/html

echo "Documentation built successfully!"
