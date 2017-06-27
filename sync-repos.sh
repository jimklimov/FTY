#!/bin/bash

# Check if any new "fty-*" repos appeared since we last looked
# Register them, sync them, reference developer's fork if possible
# Copyright (C) 2017 by Jim Klimov <EvgenyKlimov@eaton.com>

set -o pipefail

# Github ORG name to query
GITHUB_ORG="42ity"

# Repo names we know we do not want added to tracking
REPOS_EXCLUDE="FTY 42ity.github.io 42ity-org-website" # czmq

LANG=C
LC_ALL=C
TZ=UTC
export LANG LC_ALL TZ

die() {
    echo "FATAL: $*" >&2
    exit 1
}

list_tracked() {
    git submodule foreach -q --recursive 'printf "%s|%s|%s\n" "$(basename `pwd` .git)" "$(git config -f $toplevel/.gitmodules submodule.$name.url)" "$(git config -f $toplevel/.gitmodules submodule.$name.branch || echo master)"'
}

list_remote() {
    # Can also "curl"...
    ( wget -O - "https://api.github.com/orgs/${GITHUB_ORG}/repos" && echo "" ) \
    | egrep '("clone_url".*:.*"http.*/'"${GITHUB_ORG}"'/|"default_branch")' \
    | sed -e 's,^.*"\(http[^"]*/'"${GITHUB_ORG}"'/[^"]*\)".*$,\1,' \
          -e 's,^.*"default_branch".*:.*"\([^"]*\)".*$,\1,' \
    | ( URL="" ; BRN="" ; while read LINE ; do
        case "$LINE" in
            http*|"") if [ -n "$URL$BRN" ] ; then printf "%s|%s|%s\n" "$(basename "$URL" .git)" "$URL" "$BRN" ; fi
                URL="$LINE"; BRN="" ;;
            *)  BRN="$LINE" ;;
        esac; done )
}

do_work() {
    echo "INFO: Parsing list of locally tracked repos..." >&2
    REPOS_TRACKED="$(list_tracked | sort)" && [ -n "$REPOS_TRACKED" ] || die "Can not get local list of repos, wrong dir?"
    echo "INFO: Parsing list of remotely defined repos..." >&2
    REPOS_UPSTREAM="$(list_remote | sort)" && [ -n "$REPOS_UPSTREAM" ] || die "Can not get remote list of repos, no internet?"

    echo "INFO: Looking for new remotely defined repos that are not yet tracked locally..." >&2
    echo "$REPOS_UPSTREAM" | while IFS='|' read REPO_REMOTE URL_REMOTE BRANCH_REMOTE ; do
        [ -n "$REPO_REMOTE" ] && [ -n "$URL_REMOTE" ] || { echo "INVALID: Could not parse data, skipping the line" >&2 ; continue; }
        [ -n "$BRANCH_REMOTE" ] || { echo "WARNING: default branch spec not found for '$URL_REMOTE', falling back to 'master'"; BRANCH_REMOTE="master"; }

        ( for REPO_EXCLUDE in $REPOS_EXCLUDE ; do
            if [ "$REPO_REMOTE" = "$REPO_EXCLUDE" ]; then
                echo "SKIP: '$REPO_REMOTE' is explicitly excluded from tracking" >&2
                exit 0
            fi
        done ; exit 1 ) && continue

        echo "$REPOS_TRACKED" | ( while IFS='|' read REPO_LOCAL URL_LOCAL BRANCH_LOCAL ; do
            if [ "$REPO_REMOTE" = "$REPO_LOCAL" ]; then
                echo "SKIP: '$REPO_REMOTE' is already tracked" >&2
                exit 0
            fi
            URL_REMOTE="$(echo "$URL_REMOTE" | sed 's,\.git$,,')"
            URL_LOCAL="$(echo "$URL_LOCAL" | sed 's,\.git$,,')"
            if [ "$URL_REMOTE" = "$URL_LOCAL" ] ; then
                echo "SKIP: '$URL_REMOTE' is already tracked as '$REPO_LOCAL'" >&2
                exit 0
            fi
        done ; exit 1 ) && continue

        echo "FOUND: new remote repo '$REPO_REMOTE' at '$URL_REMOTE' - registering with default branch '$BRANCH_REMOTE'..." >&2
        git submodule add -b "$BRANCH_REMOTE" "$URL_REMOTE" "$REPO_REMOTE" || die "Can not register remote repo"
        git add "$REPO_REMOTE" && git commit -m "Begin tracking '$REPO_REMOTE' since `date -u`"

        echo "TRY to link developer fork of '$REPO_REMOTE', if available..." >&2
        ./git-myorigin "$REPO_REMOTE"
    done

    echo "SYNCING currently registered remote repositories to local workspace..." >&2
    ./sync.sh
}

case "$1" in
    list_tracked|list-tracked) list_tracked ;;
    list_remote|list-remote) list_remote ;;
    *) do_work ;;
esac
