#!/usr/bin/env bash
set -euo pipefail

# Builds a self-contained app-image for the CURRENT OS.
# Output: build/jpackage/Google (folder) or platform-specific app layout.

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

patch_macos_plist() {
	# Ensures the app bundle Info.plist permits loading local dev servers in a JavaFX WebView.
	# - ATS: allow insecure HTTP for localhost/127.0.0.1
	# - Web content: some WebKit stacks read NSAllowsArbitraryLoadsInWebContent
	# - Local network privacy: include a usage description so macOS can prompt instead of silently denying
	[[ "$(uname -s 2>/dev/null || true)" == "Darwin" ]] || return 0
	local buddy="/usr/libexec/PlistBuddy"
	[[ -x "$buddy" ]] || return 0

	local plist
	for plist in \
		"$ROOT_DIR/build/jpackage/AnonyChat.app/Contents/Info.plist" \
		"$ROOT_DIR/bin/macos/AnonyChat.app/Contents/Info.plist"
	do
		[[ -f "$plist" ]] || continue

		if ! "$buddy" -c "Print :NSAppTransportSecurity" "$plist" >/dev/null 2>&1; then
			"$buddy" -c "Add :NSAppTransportSecurity dict" "$plist" >/dev/null
		fi

		for key in NSAllowsArbitraryLoads NSAllowsArbitraryLoadsInWebContent; do
			if "$buddy" -c "Print :NSAppTransportSecurity:${key}" "$plist" >/dev/null 2>&1; then
				"$buddy" -c "Set :NSAppTransportSecurity:${key} true" "$plist" >/dev/null
			else
				"$buddy" -c "Add :NSAppTransportSecurity:${key} bool true" "$plist" >/dev/null
			fi
		done

		if ! "$buddy" -c "Print :NSAppTransportSecurity:NSExceptionDomains" "$plist" >/dev/null 2>&1; then
			"$buddy" -c "Add :NSAppTransportSecurity:NSExceptionDomains dict" "$plist" >/dev/null
		fi

		for domain in localhost 127.0.0.1; do
			if ! "$buddy" -c "Print :NSAppTransportSecurity:NSExceptionDomains:${domain}" "$plist" >/dev/null 2>&1; then
				"$buddy" -c "Add :NSAppTransportSecurity:NSExceptionDomains:${domain} dict" "$plist" >/dev/null
			fi

			for k in NSExceptionAllowsInsecureHTTPLoads NSIncludesSubdomains; do
				if "$buddy" -c "Print :NSAppTransportSecurity:NSExceptionDomains:${domain}:${k}" "$plist" >/dev/null 2>&1; then
					"$buddy" -c "Set :NSAppTransportSecurity:NSExceptionDomains:${domain}:${k} true" "$plist" >/dev/null
				else
					"$buddy" -c "Add :NSAppTransportSecurity:NSExceptionDomains:${domain}:${k} bool true" "$plist" >/dev/null
				fi
			done
		done

		if "$buddy" -c "Print :NSLocalNetworkUsageDescription" "$plist" >/dev/null 2>&1; then
			:
		else
			"$buddy" -c "Add :NSLocalNetworkUsageDescription string AnonyChat needs access to your local network to connect to local servers (e.g., localhost)." "$plist" >/dev/null
		fi
	done
}

# Ensure wrapper is executable (common after copying from shares/zips).
chmod +x ./gradlew 2>/dev/null || true

# Gradle 8.7 does not support running on Java 25 (classfile major 69).
# Prefer a compatible JDK when present.
if command -v java >/dev/null 2>&1; then
	JAVA_MAJOR="$(java -version 2>&1 | sed -nE 's/.*version "([0-9]+)\..*/\1/p' | head -n 1)"
	UNAME_S="$(uname -s 2>/dev/null || true)"

	# Prefer running Gradle with JDK 22 (fixes classfile major 66 cache issues when switching JDKs).
	if [[ "${UNAME_S}" == "Darwin" ]]; then
		if command -v /usr/libexec/java_home >/dev/null 2>&1; then
			JDK22_HOME="$(/usr/libexec/java_home -v 22 2>/dev/null || true)"
			if [[ -n "${JDK22_HOME}" && -x "${JDK22_HOME}/bin/java" ]]; then
				export JAVA_HOME="${JDK22_HOME}"
				export PATH="${JAVA_HOME}/bin:${PATH}"
				echo "Using JAVA_HOME=${JAVA_HOME} for Gradle."
			fi
		fi
	else
		JDK22_HOME="/usr/lib/jvm/java-22-openjdk-amd64"
		if [[ -x "${JDK22_HOME}/bin/java" ]]; then
			export JAVA_HOME="${JDK22_HOME}"
			export PATH="${JAVA_HOME}/bin:${PATH}"
			echo "Using JAVA_HOME=${JAVA_HOME} for Gradle."
		fi
	fi

	if [[ -n "${JAVA_MAJOR}" && "${JAVA_MAJOR}" -ge 23 ]]; then
		if [[ "${UNAME_S}" == "Darwin" ]]; then
			if command -v /usr/libexec/java_home >/dev/null 2>&1; then
				JDK21_HOME="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
				if [[ -n "${JDK21_HOME}" && -x "${JDK21_HOME}/bin/java" ]]; then
					export JAVA_HOME="${JDK21_HOME}"
					export PATH="${JAVA_HOME}/bin:${PATH}"
					echo "Using JAVA_HOME=${JAVA_HOME} for Gradle compatibility."
				fi
			fi
		else
			JDK21_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
			if [[ -x "${JDK21_HOME}/bin/java" ]]; then
				export JAVA_HOME="${JDK21_HOME}"
				export PATH="${JAVA_HOME}/bin:${PATH}"
				echo "Using JAVA_HOME=${JAVA_HOME} for Gradle compatibility."
			fi
		fi
	fi
fi

# jlink/jpackage require a full JDK (javac present), not a JRE.
if [[ -n "${JAVA_HOME:-}" && ! -x "${JAVA_HOME}/bin/javac" ]]; then
	echo "JAVA_HOME is set but javac is missing: ${JAVA_HOME}"
	echo "Install a full JDK (e.g. openjdk-22-jdk or openjdk-21-jdk) or point JAVA_HOME to a JDK."
	exit 1
fi

./gradlew --no-daemon clean jpackage

patch_macos_plist || true

# Copy the built image into bin/<platform> so Program.java picks it up.
UNAME_S="$(uname -s 2>/dev/null || true)"
if [[ "${UNAME_S}" == "Linux" ]]; then
	rm -rf "$ROOT_DIR/bin/linux"
	mkdir -p "$ROOT_DIR/bin/linux"
	cp -r "$ROOT_DIR/build/jpackage/AnonyChat/"* "$ROOT_DIR/bin/linux/"
elif [[ "${UNAME_S}" == "Darwin" ]]; then
	rm -rf "$ROOT_DIR/bin/macos"
	mkdir -p "$ROOT_DIR/bin/macos"
	cp -r "$ROOT_DIR/build/jpackage/AnonyChat.app" "$ROOT_DIR/bin/macos/"
fi

echo
echo "Built app-image under: $ROOT_DIR/build/jpackage"
