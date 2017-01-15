#!/bin/sh

# Initially fetch or subsequently update the components
# referred to as "git submodule"'s

git pull --all
git submodule sync --recursive && \
git submodule update --recursive && \
git status -s

