# PathsData Query Engine Documentation

Documentation for the PathsData Query Engine built with Sphinx and pydata-sphinx-theme.

## Local Development

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Build docs
sphinx-build -b html source build/html

# Serve locally
cd build/html && python -m http.server 8080
```

## Deployment

This documentation is deployed to Vercel. Any push to `main` triggers automatic deployment.

## Configuration

Key documentation files:
- `source/user-guide/configuration/index.md` - Configuration reference
- `source/user-guide/python/index.md` - Python API reference
- `source/user-guide/iceberg/index.md` - Iceberg user guide
