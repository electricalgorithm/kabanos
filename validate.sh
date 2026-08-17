#!/bin/bash
set -e

echo "=== Kabanos Yocto Validation ==="
echo ""

# Check if we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: Not in a git repository. Run 'git init' first."
    exit 1
fi

# Check required directories
echo "Checking project structure..."
for dir in openembedded-core meta-yocto bitbake meta-virtualization meta-openembedded meta-kabanos; do
    if [ ! -d "$dir" ]; then
        echo "ERROR: Missing directory: $dir"
        echo "Run 'bash build.sh' first to clone dependencies."
        exit 1
    fi
done
echo "✓ All required directories present"
echo ""

# Check build directory
if [ ! -d "build/conf" ]; then
    echo "ERROR: Missing build/conf directory."
    echo "Run 'bash build.sh' first to initialize build environment."
    exit 1
fi
echo "✓ Build configuration present"
echo ""

# Source build environment
echo "Sourcing build environment..."
cd openembedded-core
source oe-init-build-env ../build
cd ..
echo "✓ Build environment sourced"
echo ""

# Check layers
echo "Checking layers..."
bitbake-layers show-layers > /dev/null
echo "✓ Layers configured"
echo ""

# Parse recipes (fast, no build)
echo "Parsing recipes (this may take a few minutes)..."
if bitbake --parse-only kabanos-image; then
    echo "✓ Recipe parsing succeeded"
else
    echo "✗ Recipe parsing failed"
    exit 1
fi
echo ""

# Check kernel recipe is available
echo "Checking kernel recipe..."
if bitbake -s > /tmp/bitbake-s-output.txt && grep -q "linux-stable" /tmp/bitbake-s-output.txt; then
    echo "✓ linux-stable kernel recipe found"
else
    echo "✗ linux-stable kernel recipe not found"
    exit 1
fi
echo ""

# Dry run task queue (no execution)
echo "Generating task queue (dry run)..."
if bitbake -n kabanos-image > /dev/null 2>&1; then
    echo "✓ Task queue generated successfully"
else
    echo "✗ Task queue generation failed"
    exit 1
fi
echo ""

# Summary
echo "=== Validation Complete ==="
echo "All checks passed. Safe to push to GitHub Actions."
echo ""
echo "Next steps:"
echo "  1. git add -A && git commit -m 'message'"
echo "  2. git push origin main"
echo "  3. Monitor: gh run list --repo electricalgorithm/kabanos --limit 1"
