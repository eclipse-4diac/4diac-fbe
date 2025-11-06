#!/bin/sh
#********************************************************************************
# Copyright (c) 2018, 2024 OFFIS e.V.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#    Jörg Walter - initial implementation
# *******************************************************************************/
#

################################################################################
### low-level bootstrap/helper functions
################################################################################

set -e
exe="$0"
die() { trap "" EXIT; echo "### ${exe##*/}: $*" >&2; exit 1; }
trap '[ "$?" = 0 ] || die "Exiting due to error"' EXIT

find_fbemaindir() {
	fbemaindir="$(cd "$(dirname "$0")"; pwd)"
	[ -d "$fbemaindir/scripts" ] || fbemaindir="${fbemaindir%/scripts}"
	[ -d "$fbemaindir/toolchains" ] || exec "$(readlink -f "$exe")" "$@"
}

find_subdirs() {
	fberootdir="$PWD"
	[ -d "$FBE_FORTE_SOURCE_DIR" ] || FBE_FORTE_SOURCE_DIR="$fberootdir/4diac-forte/"
	[ -d "$FBE_FORTE_SOURCE_DIR" ] || FBE_FORTE_SOURCE_DIR="$fberootdir/forte/"
	[ -d "$FBE_FORTE_SOURCE_DIR" ] || FBE_FORTE_SOURCE_DIR="$fbemaindir/forte/"
	export FBE_FORTE_SOURCE_DIR

	builddir="$fberootdir/build"

	depdir="$fbemaindir/dependencies/recipes"
	extradepdir="$fberootdir/dependencies/recipes/"
}

cleanup_execution_environment() {
	if [ "$PATH" != "$fbemaindir/toolchains/bin" ]; then
		PATH="$fbemaindir/toolchains/bin"
		exec "$fbemaindir/toolchains/bin/sh" "$0" "$@"
	fi

	export LANG=C
	export LC_ALL=C
	# make python-based code generators deterministic (e.g. open62541)
	export PYTHONHASHSEED=0
	export CGET_CACHE_DIR="$fbemaindir/toolchains/download-cache"
	export CURL_CA_BUNDLE="$fbemaindir/toolchains/etc/ssl/curl-ca-bundle.crt"
	unset PYTHONHOME PYTHONPATH MAKEFLAGS
	export CLICOLOR_FORCE=1
}

find_fbemaindir
find_subdirs
cleanup_execution_environment "$@"

################################################################################
### helper functions
################################################################################

replace() { # replace varname "foo" "bar"
	eval "while [ -n \"\${$1}\" -a -z \"\${$1##*\"\$2\"*}\" ]; do $1=\"\${$1%%\"\$2\"*}\"\$3\"\${$1#*\"\$2\"}\"; done";
}

if [ "$(uname -s)" = "Windows_NT" ]; then
	# don't even try on Windows
	ln() { false; }
fi

compile_commands=
create_compile_commands_json() {
	# skip this on anything but the native "debug" build configuration
	[ "$1" = "debug" -o "$compile_commands" = "1" ] || return 0

	python -I -m compdb -p "$prefix/forte/build" list > "$builddir/../compile_commands.json" 2>/dev/null
}

detect_legacy_open62541_version() {
	local version=""

	if grep -q __UA_Client_AsyncService "$FBE_FORTE_SOURCE_DIR"/src/com/opc_ua/opcua_client_information.cpp; then
		version=1.4
	elif grep -q paUaServerConfig.customHostname "$FBE_FORTE_SOURCE_DIR"/src/com/opc_ua/opcua_local_handler.cpp; then
		version=1.3
	elif grep -q UA_Client_connectUsername "$FBE_FORTE_SOURCE_DIR"/src/com/opc_ua/opcua_client_information.cpp; then
		version=1.1
	elif [ -d "$FBE_FORTE_SOURCE_DIR"/src/com/opc_ua ] || grep -q opcua_local_handler "$FBE_FORTE_SOURCE_DIR"/src/modules/opc_ua/CMakeLists.txt; then
		version=1.0
	elif grep -q UA_ServerConfig_new_minimal "$FBE_FORTE_SOURCE_DIR"/src/modules/opc_ua/opcua_handler.cpp; then
		# this is a bit fuzzy: there were gradual changes in FORTE and open62541, so it might break depending on the exact version
		version=0.3
	else
		# There is older open62541 support before March 2017, commit
		# 843ca27be7dffddb3f0c724fa4afb3d34382bc95. 4diac-fbe did not exist back
		# then and so does not have recipes for that.
		version=0.2
	fi

	rm -rf open62541
	[ -z "$version" ] || ln -sf "open62541@$version" "open62541" || cp -r "open62541@$version" "open62541"
}

prepare_recipe_dir() {
	local prefix="$1"
	local recipes="$prefix/etc/cget/recipes"
	mkdir -p "$recipes"

	# try to symlink, but if that fails (windows), copy instead -- and copy every time to keep recipes up to date
	if [ -d "$extradepdir" ]; then
		cd "$extradepdir"
		for i in */; do
			ln -sf "$extradepdir/$i" "$recipes/" || cp -r "$extradepdir/$i" "$recipes/"
		done
	fi
	cd "$depdir"
	for i in */; do
		[ -d "$recipes/$i" ] || ln -sf "$PWD/$i" "$recipes/" || cp -r "$i" "$recipes/"
	done

	[ -d "$FBE_FORTE_SOURCE_DIR" ] || die "ERROR: 4diac FORTE source directory not accessible: $FBE_FORTE_SOURCE_DIR"

	# for all versioned recipes: select correct package version based on SPDX file
	cd "$recipes"
	local spdx="$FBE_FORTE_SOURCE_DIR/dependencies.spdx"
	if [ ! -f "$spdx" ]; then
		detect_legacy_open62541_version
		return
	fi

	for i in *@*; do
		local pkgname="${i%%@*}"

		[ ! -d "$pkgname" ] || continue

		# parse SPDX
		local found="0" version=""
		while read tag value; do
			case "$found:$tag" in
				0:PackageName:)
					[ "$value" = "$pkgname" ] || continue;
					found=1;;
				1:PackageName:)
					[ "$value" != "$pkgname" ] || continue;
					found=0;;
				1:PackageVersion:)
					version="@$value";;
			esac
		done < "$spdx"

		# select matching recipe, if any
		while [ -n "$version" ]; do
			if [ -d "$pkgname$version" ]; then
				rm -rf "$pkgname"
				ln -sf "$pkgname$version" "$pkgname" || cp -r "$pkgname$version" "$pkgname"
				break
			fi
			version="${version%[@.]*}"
		done
	done
}

################################################################################
### configuration parsing
################################################################################

defs=" "
config="unknown"
set_define() {
	local name="$1" type="$2" val="$3"
	if [ -n "$val" ]; then
		eval "[ -n \"\$defs_$name\" ] || defs=\"\$defs\$name \""
		eval "defs_$name=\"\$type:\$val\""
	elif eval "[ -n \"\$defs_$name\" ]"; then
		unset defs_$name
		defs="${defs% $name *} ${defs#* $name } "
	fi
}

reset_build_if_changed() {
	local file="$1"
	if [ -f "$cachefile" -a "$file" -nt "$cachefile" ]; then
		echo "Configuration has changed."
		"$fbemaindir/scripts/clean.sh" "$config/forte"
	fi
}

deps=" "
deploy=""
forte_io=""
io_process=""
preset=""
load_config() {
	local var val file="$1" config="${1%.txt}" oldpwd="$PWD"
	config="${config##*/}"

	if [ -f "$FBE_FORTE_SOURCE_DIR/CMakePresets.json" -a ! -f "$file" ]; then
		# assume that this is a preset name
		preset="$file"
		deps="$("$fbemaindir/toolchains/bin/jq" -r ".vendor.\"eclipse.dev/4diac/FBE/3.0\".dependencies.\"$preset\" | @tsv" "$FBE_FORTE_SOURCE_DIR/CMakePresets.json" 2>/dev/null || true)"
		return
	fi

	while read line || [ -n "$line" ]; do
		line="${line%
}" # this is a CR (ASCII 0x0d) character: be tolerant to windows line endings (important for WSL)
		var_type="${line%%=*}"
		val="${line#*=}"
		var="${var_type%%:*}"
		type="${var_type#*:}"
		if [ "$type" = "$var" ]; then
			type="STRING"
		fi

		replace val '${FBE_ROOT}' "$fberootdir"
		replace val '${FBE_MAIN}' "$fbemaindir"
		replace val '${PREFIX}' "$prefix"
		replace val '${HOME}' "$(echo ~)"
		replace val '${CONFIG}'  "$config"
		replace val '${}'  '$'

		case "$var" in
			//*|"#"*|"") ;;
			" "*|*" ") die "Extra spaces in config file not supported.";;

			DEPS)
				if [ "${val#-}" != "$val" ]; then
					val="${val#-}"
					deps="${deps%% $val *} ${deps#* $val }"
				else
					deps=" $val$deps"
				fi;;

			DEPLOY)
				if [ -n "$val" ]; then
					deploy="${deploy}
$val"
				else
					deploy=""
				fi;;

			include)
				cd "$(dirname "$file")"
				load_config "$val"
				cd "$oldpwd";;

			IO_PROCESS)
				[ -z "$io_process" ] || set_define "FORTE_MODULE_${io_process}" "BOOL" "OFF"
				[ -z "$val" ] || set_define "FORTE_MODULE_${val}" "BOOL" "ON"
				io_process="$val";;

			IO)
				if [ -n "$val" ]; then
					set_define "FORTE_IO" "BOOL" "ON"
					if [ "${val#-}" != "$val" ]; then
						val="${val#-}"
						set_define "FORTE_MODULE_${val}" "BOOL" "OFF"
					else
						set_define "FORTE_MODULE_${val}" "BOOL" "ON"
					fi
					forte_io="$forte_io _$val"
				else
					set_define "FORTE_IO" "BOOL" "OFF"
					for io in $forte_io; do
						set_define "FORTE_MODULE_$io" "BOOL" "OFF"
					done
					forte_io=""
				fi;;

			MODULE|COM)
				val="$val,"
				while [ "${val#*,}" != "$val" ]; do
					if [ "${val#-}" != "$val" ]; then
						val="${val#-}"
						set_define "FORTE_${var}_${val%%,*}" "BOOL" "OFF"
					else
						set_define "FORTE_${var}_${val%%,*}" "BOOL" "ON"
					fi
					val="${val#*,}"
				done;;

			PRESET)
				preset="$val";;

			FBE_FORTE_SOURCE_DIR)
				FBE_FORTE_SOURCE_DIR="$val";;

			*) set_define "$var" "$type" "$val";;
		esac
	done < "$file"
}

################################################################################
### build process
################################################################################

keep_going=
build_one() {
	local file="$1" config="${1%.txt}"
	config="${config##*/}"
	prefix="$builddir/$config"
	cachefile="$prefix/forte/build/CMakeCache.txt"

	reset_build_if_changed "$file"

	set_define ARCH STRING "native-toolchain"
	set_define "CMAKE_SKIP_RPATH" "BOOL" "ON"
	load_config "$file"

	prepare_recipe_dir "$prefix"

	target="${defs_ARCH#*:}"
	"$fbemaindir/toolchains/install-crosscompiler.sh" "$target"
	"$fbemaindir/toolchains/bin/cget" -p "$prefix" init -t "$fbemaindir/toolchains/$target.cmake" --ccache

	set_define ARCH
	set -- -DCMAKE_INSTALL_PREFIX:STRING="$prefix/output"
	for name in $defs; do
		eval "type=\"\$defs_$name\""
		val="${type#*:}"
		type="${type%%:*}"
		#echo "$name: $val"
		set -- "$@" "-D$name:$type=$val"
	done

	"$fbemaindir/toolchains/bin/cget" \
		-p "$prefix" install $verbose \
		$deps \
		"$@" \
		-DCMAKE_INSTALL_PREFIX:STRING="$prefix" \
		-G "$generator" \
		|| die "Dependencies of configuration '$config' failed"
	if [ -f "$prefix/forte/build/CMakeCache.txt" -a "$fbemaindir/dependencies/recipes/forte/CMakeLists.txt" -nt "$prefix/forte/build/CMakeCache.txt" ]; then
		rm -rf "$prefix/forte"
	fi

	[ -f "$prefix/forte/build/cmake_install.cmake" ] || rm -rf "$prefix/forte"

	"$fbemaindir/toolchains/bin/cget" \
		-p "$prefix" build -T install $verbose \
		${preset:+--preset} ${preset} \
		-B "$prefix" \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		"$@" forte \
		-G "$generator" \
		|| {
			[ -z "$keep_going" ] || return 0
			die "Build of configuration '$config' failed"
		}

	# print FORTE CMake warnings
	awk '/^.\[[0-9]*mCMake Warning/ { doprint=1; $_="=================================="; }  /^  Manually-specified variables/ { doprint=0; } /^.\[0m$/ { doprint = 0; } /[^ ]/ { if (doprint) print; } ' "$prefix/forte.log"

	"$fbemaindir/toolchains/etc/package-dynamic.sh" "$target" "$prefix/output/bin/forte" || true
	create_compile_commands_json "$config"

	if [ -n "$deploy" ]; then
		(
			cd "$prefix"
            echo "### [$config] Running DEPLOY command: $deploy"
			exec "$SHELL" -c "$deploy"
		)
		echo "### [$config] Deploy command exited successfully."
	fi
}

################################################################################
### main script
################################################################################

verbose=--log
generator=Ninja
while [ -n "$1" ]; do
	case "$1" in
		-v) verbose="-v";;
		-d)
			generator="Unix Makefiles";
			export MAKEFLAGS=-j1;
			export NINJAFLAGS=-j1;
			export CMAKE_BUILD_PARALLEL_LEVEL=1;
			set_define CMAKE_VERBOSE_MAKEFILE BOOL ON;;
		-c) compile_commands=1;;
		-s) FBE_FORTE_SOURCE_DIR="$2"; shift;;
		-k) keep_going=1;;
		-h) echo "Usage: $0 [-v] [-c] [-k] [-s source-dir] [config-name ...]" >&2; exit 0;;
		-*) echo "Unknown flag: $1 -- ignoring";;
		*) break;
	esac
	shift
done

if [ $# = 0 ]; then
	set -- configurations/*.txt
elif [ -d "$1" ]; then
	cd "$1"
	set -- *.txt
fi

for i in "$@"; do
	if [ -f "$i" ]; then
		config="$(cd "$(dirname "$i")"; echo "$PWD/$(basename "$i")")"
	elif [ -f "configurations/$i.txt" ]; then
		config="$PWD/configurations/$i.txt"
	elif "$fbemaindir/toolchains/bin/cmake" "$FBE_FORTE_SOURCE_DIR" --list-presets | grep "\"$i\"" > /dev/null; then
		config="$i"
	else
		echo "Configuration '$i' not found. Neither file '$i', file 'configurations/$i.txt' nor CMake preset '$i' exist."
		exit 1
	fi
	( cd "$fbemaindir"; build_one "$config"; )
done
