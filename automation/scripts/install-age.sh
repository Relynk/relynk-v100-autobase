#!/bin/bash
set -e

echo "Installing Apache AGE extension..."

# Update package lists
apt-get update

# Install build prerequisites and server dev headers for PostgreSQL 17
apt-get install -y --no-install-recommends \
    git \
    build-essential \
    flex \
    bison \
    ca-certificates \
    postgresql-server-dev-17

# Clone AGE repository for PostgreSQL 17
echo "Cloning AGE repository (PG17 branch)..."
git clone -b PG17 https://github.com/apache/age.git /tmp/age

# Build and install AGE
echo "Building AGE extension..."
cd /tmp/age
make PG_CONFIG=/usr/bin/pg_config
make install PG_CONFIG=/usr/bin/pg_config

# Clean up
echo "Cleaning up..."
rm -rf /tmp/age
apt-get remove -y git build-essential flex bison
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "AGE extension installed successfully!"