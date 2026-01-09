#!/bin/bash
set -e

# Install dependencies
pip install -r requirements.txt

# Build Sphinx documentation
sphinx-build -b html source build/html

echo "Documentation built successfully!"
