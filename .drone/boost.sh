#!/bin/bash

set -ex
export TRAVIS_BUILD_DIR=$(pwd)
export TRAVIS_BRANCH=$DRONE_BRANCH
export TRAVIS_OS_NAME=${DRONE_JOB_OS_NAME:-linux}
export VCS_COMMIT_ID=$DRONE_COMMIT
export GIT_COMMIT=$DRONE_COMMIT
export DRONE_CURRENT_BUILD_DIR=$(pwd)
export PATH=~/.local/bin:/usr/local/bin:$PATH

echo '==================================> BEFORE_INSTALL'

. .drone/before-install.sh

echo '==================================> INSTALL'

GIT_FETCH_JOBS=8
BOOST_BRANCH=develop
if [ "$TRAVIS_BRANCH" = "master" ]; then BOOST_BRANCH=master; fi
cd ..
git clone -b $BOOST_BRANCH --depth 1 https://github.com/boostorg/boost.git boost-root
cd boost-root
git submodule init tools/build
git submodule init tools/boost_install
git submodule init libs/headers
git submodule init libs/assert
git submodule init libs/config
git submodule init libs/core
git submodule init libs/io
git submodule init libs/preprocessor
git submodule init libs/static_assert
git submodule init libs/throw_exception
git submodule init libs/type_traits
git submodule init libs/container_hash
git submodule init libs/integer
git submodule init libs/detail
git submodule update --jobs $GIT_FETCH_JOBS
cp -r $TRAVIS_BUILD_DIR/* libs/utility
./bootstrap.sh
./b2 headers

echo '==================================> BEFORE_SCRIPT'

. $DRONE_CURRENT_BUILD_DIR/.drone/before-script.sh

echo '==================================> SCRIPT'

echo "using $TOOLSET : : $COMPILER ;" > ~/user-config.jam
BUILD_JOBS=`(nproc || sysctl -n hw.ncpu) 2> /dev/null`
./b2 -j $BUILD_JOBS libs/utility/test toolset=$TOOLSET cxxstd=$CXXSTD ${CXXFLAGS:+cxxflags="$CXXFLAGS"} ${LINKFLAGS:+linkflags="$LINKFLAGS"}

echo '==================================> AFTER_SUCCESS'

. $DRONE_CURRENT_BUILD_DIR/.drone/after-success.sh
