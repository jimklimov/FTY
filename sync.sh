#!/bin/sh

# Initially fetch or subsequently update the components
# referred to as "git submodule"'s
# Copyright (C) 2017 by Jim Klimov <EvgenyKlimov@eaton.com>

# See also
# https://git-scm.com/book/en/v2/Git-Tools-Submodules
# http://stackoverflow.com/questions/5828324/update-git-submodule-to-latest-commit-on-origin
# http://stackoverflow.com/questions/1979167/git-submodule-update/1979194#1979194

set -e

# Set this to enable verbose profiling
[ -n "${CI_TIME-}" ] || CI_TIME=""
case "$CI_TIME" in
    [Yy][Ee][Ss]|[Oo][Nn]|[Tt][Rr][Uu][Ee])
        CI_TIME="time -p " ;;
    [Nn][Oo]|[Oo][Ff][Ff]|[Ff][Aa][Ll][Ss][Ee])
        CI_TIME="" ;;
esac

# Set this to enable verbose tracing
[ -n "${CI_TRACE-}" ] || CI_TRACE="no"
case "$CI_TRACE" in
    [Nn][Oo]|[Oo][Ff][Ff]|[Ff][Aa][Ll][Ss][Ee])
        set +x ;;
    [Yy][Ee][Ss]|[Oo][Nn]|[Tt][Rr][Uu][Ee])
        set -x ;;
esac

# Update dispatcher repo
$CI_TIME git pull --all

# Update component repos
# NOTE: sync is toxic to established workspaces, as it "resyncs the URL" and
# so overwrites locally defined "origin" URL (e.g. pointing to a developers'
# fork) back to the upstream project URL. For daily usage, "update" suffices.
# git submodule init --recursive && \
# git submodule sync --recursive && \
$CI_TIME git submodule init && \
$CI_TIME git submodule foreach "git pull --all" && \
$CI_TIME git submodule update --recursive --remote --merge && \
$CI_TIME git status -s

[ x"${DO_BUMP-}" = xno ] || \
git status -s | while read STATUS OBJNAME ; do
    DO_BUMP=no
    if [ -n "$OBJNAME" ]; then
        case "$STATUS" in
            M) DO_BUMP=yes ; break ;;
        esac
    fi
done

if [ x"${DO_BUMP-}" = xyes ]; then
    echo "Adding changed objects to git commit..."
    $CI_TIME git commit -a -m 'Updated references to git submodule HEADs at '"`date -u`"
fi
