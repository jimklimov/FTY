#!/bin/sh

echo "=================="
echo "WARNING : this will reset the workspaces to their"
echo "   primary branches, and will push to git origins"
echo "=================="

echo "Sleeping 5sec for a CTRL+C..."
sleep 5

gmake emerge -j && \
./sync-repos.sh && \
git push origin && \
git submodule foreach "git push origin || true"
