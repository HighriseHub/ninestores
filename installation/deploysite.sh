#!/bin/bash

# Deployment script to sync public assets from repository to Nginx public root
# Does NOT delete existing files in the destination

# Source paths
SRC_BASE=/home/ubuntu/ninestores/site/public
SRC_JS="$SRC_BASE/js"
SRC_CSS="$SRC_BASE/css"
SRC_CSV="$SRC_BASE/csv"
SRC_IMG="$SRC_BASE/img"
SRC_HTML="$SRC_BASE/index.html"

# Destination path
DEST_BASE=/data/www/ninestores.in/public

# Create destination directories if not present
mkdir -p "$DEST_BASE/js"
mkdir -p "$DEST_BASE/css"
mkdir -p "$DEST_BASE/csv"
mkdir -p "$DEST_BASE/img"

echo "Copying web root files..."
rsync -av "$SRC_BASE/" "$DEST_BASE/"

echo "Copying JS files..."
rsync -av "$SRC_JS/" "$DEST_BASE/js/"

echo "Copying CSS files..."
rsync -av "$SRC_CSS/" "$DEST_BASE/css/"

echo "Copying CSV files..."
rsync -av "$SRC_CSV/" "$DEST_BASE/csv/"

echo "Copying IMG files..."
rsync -av "$SRC_IMG/" "$DEST_BASE/img/"

echo "Copying index.html..."
cp -v "$SRC_HTML" "$DEST_BASE/"

echo "✅ Deployment complete."

