#!/bin/sh
set -e

cd "$(dirname "$0")"/..

./scripts/test-dependency-recipes.sh

./clean.cmd --all
./scripts/compile-isolated.sh debug native-toolchain configurations/test/*.txt
./clean.cmd

./scripts/test-basic-execution.sh build/*
