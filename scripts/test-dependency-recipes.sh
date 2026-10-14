#!/bin/sh
set -e

scripts="$(cd "$(dirname "$0")"; pwd)"
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

# Load the recipe helpers without bootstrapping toolchains or running builds.
sed -n '/^detect_legacy_open62541_version()/,/^### configuration parsing/p' "$scripts/compile.sh" > "$tmp/helpers.sh"
. "$tmp/helpers.sh"

depdir="$tmp/fbe/dependencies/recipes"
extradepdir="$tmp/project/dependencies/recipes"
FBE_FORTE_SOURCE_DIR="$tmp/forte"
prefix="$tmp/project/build/test"
config=test
rm() {
	for path in "$@"; do
		case "$path" in
			"$prefix"|"$prefix/etc/cget/recipes")
				case "$PWD/" in
					"$path/"*) echo "Cannot remove the current directory on Windows" >&2; return 1;;
				esac;;
		esac
	done
	command rm "$@"
}

mkdir -p "$depdir/open62541@1.4" "$depdir/open62541@1.5" "$depdir/libressl" "$depdir/forte" "$FBE_FORTE_SOURCE_DIR"
printf '%s\n' 'open62541/open62541@v1.4.0' > "$depdir/open62541@1.4/package.txt"
printf '%s\n' 'open62541/open62541@v1.5.4' > "$depdir/open62541@1.5/package.txt"
printf '%s\n' libressl > "$depdir/open62541@1.5/requirements.txt"
printf '%s\n' old > "$depdir/open62541@1.5/build.cmake"
printf '%s\n' libressl > "$depdir/libressl/package.txt"

select_version() {
	printf 'PackageName: open62541\nPackageVersion: %s\n' "$1" > "$FBE_FORTE_SOURCE_DIR/dependencies.spdx"
}

prepare() {
	prepare_recipe_dir "$prefix"
	reset_dependencies_if_changed
}

installed() {
	mkdir -p "$prefix/cget/pkg/open62541" "$prefix/cget/pkg/libressl" "$prefix/forte/build" "$prefix/lib"
	printf '%s\n' lib/old-open62541 > "$prefix/cget/pkg/open62541/install_manifest.txt"
	touch "$prefix/lib/old-open62541" "$prefix/forte/build/CMakeCache.txt"
}

assert_preserved() {
	[ -f "$prefix/lib/old-open62541" ]
	[ -f "$prefix/forte/build/CMakeCache.txt" ]
}

assert_reset() {
	[ ! -e "$prefix/lib/old-open62541" ]
	[ ! -d "$prefix/cget/pkg" ]
	[ ! -d "$prefix/forte" ]
	[ -f "$prefix/cget/recipes.cksum" ]
	[ -d "$prefix/etc/cget/recipes/open62541" ]
}

select_version 1.5.4
prepare
installed
prepare
assert_preserved

# Timestamps alone must not trigger a rebuild.
touch "$depdir/open62541@1.5/build.cmake"
prepare
assert_preserved

# Unselected recipes and the separately tracked FORTE recipe do not reset dependencies.
printf '%s\n' unused > "$depdir/open62541@1.4/build.cmake"
printf '%s\n' forte > "$depdir/forte/CMakeLists.txt"
prepare
assert_preserved

# A version change with an unchanged timestamp invalidates all installed state.
cp -p "$depdir/open62541@1.5/package.txt" "$tmp/old-package.txt"
printf '%s\n' 'open62541/open62541@v1.5.8' > "$depdir/open62541@1.5/package.txt"
touch -r "$tmp/old-package.txt" "$depdir/open62541@1.5/package.txt"
mkdir -p "$tmp/project/build/other"
touch "$tmp/project/build/other/keep"
prepare
assert_reset
[ -f "$tmp/project/build/other/keep" ]
installed
prepare
assert_preserved

# Changes to build scripts, support files, and requirements are also tracked.
for file in build.cmake inet_pton.h requirements.txt; do
	printf '%s\n' changed >> "$depdir/open62541@1.5/$file"
	prepare
	assert_reset
	installed
done
rm "$depdir/open62541@1.5/inet_pton.h"
prepare
assert_reset
installed

# SPDX selection must replace an existing alias, including on a downgrade.
select_version 1.4.0
prepare
assert_reset
cmp "$depdir/open62541@1.4/package.txt" "$prefix/etc/cget/recipes/open62541/package.txt"
installed
prepare
assert_preserved

# Old installations without a fingerprint get a one-time safe rebuild.
rm "$prefix/cget/recipes.cksum"
prepare
assert_reset
installed
prepare
assert_preserved

# The copy fallback must refresh both selected recipes and out-of-tree overrides.
ln() { return 1; }
prepare
assert_preserved
[ ! -L "$prefix/etc/cget/recipes/open62541" ]
mkdir -p "$extradepdir/open62541"
printf '%s\n' custom > "$extradepdir/open62541/package.txt"
prepare
assert_reset
cmp "$extradepdir/open62541/package.txt" "$prefix/etc/cget/recipes/open62541/package.txt"
installed
printf '%s\n' updated > "$extradepdir/open62541/package.txt"
prepare
assert_reset
installed
prepare
assert_preserved
rm -rf "$extradepdir/open62541"
rmdir "$extradepdir"
prepare
assert_reset
installed

# Legacy FORTE detection still selects and refreshes the matching recipe.
rm "$FBE_FORTE_SOURCE_DIR/dependencies.spdx"
mkdir -p "$FBE_FORTE_SOURCE_DIR/src/com/opc_ua"
printf '%s\n' __UA_Client_AsyncService > "$FBE_FORTE_SOURCE_DIR/src/com/opc_ua/opcua_client_information.cpp"
prepare
assert_preserved
printf '%s\n' legacy-change >> "$depdir/open62541@1.4/build.cmake"
prepare
assert_reset

echo "Dependency recipe tests passed."
