#!/usr/bin/env bash
set -euo pipefail

# Builds libuniversaljni.dylib for macOS.
# Requires: JDK installed and JAVA_HOME set.

cd "$(dirname "$0")"

: "${JAVA_HOME:?JAVA_HOME must be set to your JDK home}"

clang -dynamiclib \
  -I"$JAVA_HOME/include" \
  -I"$JAVA_HOME/include/darwin" \
  -o libuniversaljni.dylib \
  universaljni.c

echo "Built: $(pwd)/libuniversaljni.dylib"
