#!/usr/bin/env bash

################################################################################
# This file is based on a template used by zproject, but isn't auto-generated. #
# Building of dependencies (our components and forks of third-party projects   #
# in correct order is buried into the Makefile.                                #
################################################################################

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

case "$BUILD_TYPE" in
default|"default-tgt:"*)
    LANG=C
    LC_ALL=C
    export LANG LC_ALL

    # Build and check this project; note that zprojects always have an autogen.sh
    [ -z "$CI_TIME" ] || echo "`date`: Starting build of currently tested project..."

    BUILD_TGT=all
    case "$BUILD_TYPE" in
        default-tgt:*) # Hook for matrix of custom distchecks primarily
            BUILD_TGT="`echo "$BUILD_TYPE" | sed 's,^default-tgt:,,'`" ;;
    esac

    echo "`date`: Starting the sequential build attempt for singular target $BUILD_TGT..."

    ( echo "`date`: Starting the quiet parallel build attempt..."; \
      $CI_TIME make VERBOSE=0 V=0 -k -j4 "$BUILD_TGT"; ) || \
    ( echo "==================== PARALLEL ATTEMPT FAILED ($?) =========="; \
      echo "`date`: Starting the sequential build attempt..."; \
      $CI_TIME make VERBOSE=1 "$BUILD_TGT" )

    echo "=== Are GitIgnores good after 'make $BUILD_TGT'? (should have no output below)"
    git status -s || true
    echo "==="
    if [ "$HAVE_CCACHE" = yes ]; then
        echo "CCache stats after build:"
        ccache -s
    fi
    echo "=== Exiting after the custom-build target 'make $BUILD_TGT' succeeded OK"
    exit 0
    ;;
bindings)
    pushd "./bindings/${BINDING}" && ./ci_build.sh
    ;;
*)
    pushd "./builds/${BUILD_TYPE}" && REPO_DIR="$(dirs -l +1)" ./ci_build.sh
    ;;
esac
