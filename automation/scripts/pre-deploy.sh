#!/bin/bash
set -e

echo "Running pre-deployment setup..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if AGE extension is already installed
if psql -U postgres -c "SELECT 1 FROM pg_available_extensions WHERE name = 'age';" | grep -q 1; then
    echo "AGE extension is already available, skipping installation."
else
    echo "AGE extension not found, installing..."
    
    # Run the AGE installation script
    if [ -f "$SCRIPT_DIR/install-age.sh" ]; then
        bash "$SCRIPT_DIR/install-age.sh"
    else
        echo "Error: install-age.sh not found in $SCRIPT_DIR"
        exit 1
    fi
fi

# Create AGE extension in the database if not exists
echo "Ensuring AGE extension is created in the database..."
psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS age CASCADE;"

echo "Pre-deployment setup completed successfully!"