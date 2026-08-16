#!/bin/bash
set -e

echo "=== Kabanos Git Workflow ==="
echo ""

BRANCH="${1:-$(git branch --show-current)}"

echo "Branch: $BRANCH"
echo ""

echo "=== Status ==="
git status --short
echo ""

echo "=== Recent commits ==="
git log --oneline -5
echo ""

echo "=== Tracked project files ==="
git ls-files | grep -E '^(meta-kabanos|build/conf|Dockerfile|docker-compose|build\.sh|README\.md|\.gitignore|\.github)' | head -20 || true
echo ""

echo "=== Ignored build/download dirs ==="
grep -E '^(openembedded-core|meta-yocto|bitbake|meta-openembedded|meta-virtualization|build/|downloads|sstate-cache)' .gitignore || true
echo ""

echo "=== Workflow ==="
echo "1. Edit project files: meta-kabanos/, build/conf/, Dockerfile, build.sh"
echo "2. Stage: git add <files>"
echo "3. Commit: git commit -m 'message'"
echo "4. Push: git push origin $BRANCH"
echo ""
echo "Build commands:"
echo "  docker compose build"
echo "  docker compose up -d"
echo "  docker compose exec yocto-builder bash build.sh"
echo "  docker compose exec yocto-builder bash -c 'source openembedded-core/oe-init-build-env build && bitbake kabanos-image'"
echo ""
echo "Branches:"
echo "  main        - stable, ready-to-build state"
echo "  feature/*   - experimental changes"
echo "  wip/*       - work in progress"
echo ""
echo "Do NOT commit:"
echo "  - openembedded-core/, meta-yocto/, bitbake/"
echo "  - meta-openembedded/, meta-virtualization/"
echo "  - build/, downloads/, sstate-cache/"
