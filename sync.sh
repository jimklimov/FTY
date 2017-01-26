#!/bin/sh

# Initially fetch or subsequently update the components
# referred to as "git submodule"'s
# Copyright (C) 2017 by Jim Klimov <EvgenyKlimov@eaton.com>

# See also
# https://git-scm.com/book/en/v2/Git-Tools-Submodules
# http://stackoverflow.com/questions/5828324/update-git-submodule-to-latest-commit-on-origin
# http://stackoverflow.com/questions/1979167/git-submodule-update/1979194#1979194

# Update dispatcher repo
git pull --all

# Update component repos
# NOTE: sync is toxic to established workspaces, as it "resyncs the URL" and
# so overwrites locally defined "origin" URL (e.g. pointing to a developers'
# fork) back to the upstream project URL. For daily usage, "update" suffices.
# git submodule init --recursive && \
# git submodule sync --recursive && \
git submodule init && \
git submodule update --recursive --remote --merge && \
git status -s

git status -s | while read STATUS OBJNAME ; do
    DO_BUMP=no
    if [ -n "$OBJNAME" ]; then
        case "$STATUS" in
            M) DO_BUMP=yes ; break ;;
        esac
    fi
done

if [ "$DO_BUMP" = yes ]; then
    echo "Adding changed objects to git commit..."
    git commit -a -m 'Updated references to git submodule HEADs at '"`date -u`"
fi
