#!/usr/bin/env bash
set -euo pipefail

# Builds libuniversaljni.so for Linux.
# Requires: JDK installed and JAVA_HOME set.

cd "$(dirname "$0")"

: "${JAVA_HOME:?JAVA_HOME must be set to your JDK home}"

cc -fPIC -shared \
  -I"$JAVA_HOME/include" \
  -I"$JAVA_HOME/include/linux" \
  -o libuniversaljni.so \
  universaljni.c

echo "Built: $(pwd)/libuniversaljni.so"
