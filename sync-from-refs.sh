#!/bin/bash

# Sync script to pull updates from refs/osmocom-bb into FreeRTOS/POSIX codebase
# This maintains the ability to sync with upstream osmocom-bb changes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REFS_DIR="$SCRIPT_DIR/refs/osmocom-bb"
SRC_DIR="$SCRIPT_DIR/src"

if [ ! -d "$REFS_DIR" ]; then
    echo "Error: refs/osmocom-bb directory not found"
    echo "Make sure you have the reference repository in refs/"
    exit 1
fi

echo "Syncing from $REFS_DIR to $SRC_DIR..."

# Function to sync a component
sync_component() {
    local src_path="$1"
    local dst_path="$2"
    local component_name="$3"
    
    if [ -d "$src_path" ]; then
        echo "Syncing $component_name..."
        
        # Backup any local changes
        if [ -d "$dst_path" ]; then
            echo "  Backing up existing $component_name..."
            mv "$dst_path" "${dst_path}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Copy new version
        mkdir -p "$(dirname "$dst_path")"
        cp -r "$src_path" "$dst_path"
        echo "  $component_name synced successfully"
    else
        echo "Warning: $src_path not found, skipping $component_name"
    fi
}

# Sync components
sync_component "$REFS_DIR/src/host/layer23" "$SRC_DIR/host/layer23" "Layer23 protocol stack"
sync_component "$REFS_DIR/src/host/trxcon" "$SRC_DIR/host/trxcon" "TRX connection"
sync_component "$REFS_DIR/src/host/virt_phy" "$SRC_DIR/host/virt_phy" "Virtual PHY"
sync_component "$REFS_DIR/src/host/osmocon" "$SRC_DIR/host/osmocon" "Osmocon utility"

# Sync include files
if [ -d "$REFS_DIR/include" ]; then
    echo "Syncing include files..."
    if [ -d "$SRC_DIR/include" ]; then
        mv "$SRC_DIR/include" "$SRC_DIR/include.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    mkdir -p "$SRC_DIR"
    cp -r "$REFS_DIR/include" "$SRC_DIR/"
    echo "  Include files synced successfully"
fi

# Sync shared files
if [ -f "$REFS_DIR/src/shared/l1gprs.c" ]; then
    echo "Syncing shared L1 GPRS..."
    cp "$REFS_DIR/src/shared/l1gprs.c" "$SRC_DIR/shared/"
    echo "  Shared L1 GPRS synced successfully"
fi

# Update libosmocore submodule
echo "Updating libosmocore submodule..."
cd "$SRC_DIR/shared/libosmocore"
git fetch origin
git checkout master
git pull origin master
cd "$SCRIPT_DIR"

echo ""
echo "Sync completed successfully!"
echo ""
echo "Next steps:"
echo "1. Review any .backup directories for local changes you want to preserve"
echo "2. Test the build: mkdir build && cd build && cmake .. && make"
echo "3. Commit the synced changes if everything works correctly"
echo ""
echo "Note: CMakeLists.txt files are preserved and not synced."
echo "Review them manually if the upstream build system changes."