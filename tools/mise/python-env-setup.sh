#!/bin/bash
set -e

# Create mise.toml configuration for Python environment setup
cat >> mise.toml << 'EOF'
[env]
# Install seed packages (pip, setuptools, and wheel) into the virtual environment.
_.python.venv = { path = ".venv", create = true, uv_create_args = ["--seed"] }

[tools]
python = "latest"

[tasks.install]
alias = "i"
run = "pip install -r requirements.txt"
EOF

# Create requirements.txt if it doesn't exist
touch requirements.txt

echo "Python environment configuration created successfully!"
