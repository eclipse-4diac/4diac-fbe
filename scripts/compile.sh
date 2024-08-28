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
### low-level helper variables/functions
################################################################################

set -e
exe="$0"
die() { trap "" EXIT; echo "$exe: $*" >&2; exit 1; }
trap '[ "$?" = 0 ] || die "Exiting due to error"' EXIT

basedir="$(cd "$(dirname "$0")"; pwd)"
buildroot="$PWD"
[ -d "$basedir/scripts" ] || basedir="${basedir%/scripts}"

[ -d "$basedir/toolchains" ] || exec "$(readlink -f "$0")" "$@"

srcdir="$buildroot/4diac-forte/"
[ -d "$srcdir" ] || srcdir="$buildroot/forte/"
[ -d "$srcdir" ] || srcdir="$basedir/forte/"
builddir="$buildroot/build"
extradepdir="$buildroot/dependencies/recipes/"

if [ ! -x "${basedir}/toolchains/bin/cget" ]; then
	( cd "${basedir}/toolchains" && "./etc/install-$(uname -s)-$(uname -m).sh"; )
fi

if [ "$PATH" != "${basedir}/toolchains/bin" ]; then
	PATH="${basedir}/toolchains/bin"
	exec "${basedir}/toolchains/bin/sh" "$0" "$@"
fi

export LANG=C
export LC_ALL=C
export CGET_CACHE_DIR="$basedir/toolchains/download-cache"
export CLICOLOR_FORCE=1

################################################################################
### helper functions
################################################################################

replace() { # replace varname "foo" "bar"
	eval "while [ -z \"\${$1##*\"\$2\"*}\" ]; do $1=\"\${$1%%\"\$2\"*}\"\$3\"\${$1#*\"\$2\"}\"; done";
}

update_forte_build_workaround() {
    mkdir -p "${builddir}/dependencies/recipes/forte/"
    cp -n "${basedir}/dependencies/recipes/forte/build.cmake" "${builddir}/dependencies/recipes/forte/"
    echo "$srcdir/ -X build.cmake" > "${builddir}/dependencies/recipes/forte/package.txt"
}

create_compile_commands_json() {
	# skip this on anything but the native "debug" build configuration
	[ "$1" = "debug" -o "$compile_commands" = "1" ] || return 0

	# if you have https://github.com/Sarcasm/compdb installed, header files will be included,
	# which improves the functionality of many tools that read compile_commands.json
	if type compdb > /dev/null 2>&1; then
		compdb -p "$prefix/forte/build" list > "$builddir/../compile_commands.json" 2>/dev/null
	else
		cp "$prefix/forte/build/compile_commands.json" "$builddir/.."
	fi
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
		replace val '${BASEDIR}' "$basedir"
		replace val '${BUILDROOT}' "$buildroot"
		replace val '${HOME}' "$(echo ~/)"
		replace val '$CONFIG'  "$config"
		eval "defs_$name=\"\$type:\$val\""
	elif eval "[ -n \"\$defs_$name\" ]"; then
		unset defs_$name
		defs="${defs% $name *} ${defs#* $name } "
	fi
}

reset_build_if_changed() {
	local file="$1"
	if [ -f "$cachefile" -a "$file" -nt "$cachefile" ]; then
		echo "Configuration has changed, rebuilding this configuration from scratch."
		rm -rf "$builddir"
	fi
}

deps=" "
deploy=""
forte_io=""
io_process=""
load_config() {
	local var val file="$1" config="${1%.txt}" oldpwd="$PWD"
	config="${config##*/}"

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
					set_define "FORTE_IO_$val" "BOOL" "ON"
					forte_io="_$val"
				else
					# FIXME: once there are multiple IO modules, revise this logic
					set_define "FORTE_IO" "BOOL" "OFF"
					set_define "FORTE_IO$forte_io" "BOOL" "OFF"
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

	local recipes="$prefix/etc/cget/recipes"
	mkdir -p "$recipes"

	# try to symlink, but if that fails (windows), copy instead -- and copy every time to keep recipes up to date
	if [ -d "$extradepdir" ]; then
		cd "$extradepdir"
		for i in */; do
			ln -sf "$extradepdir/$i" "$recipes/" || cp -r "$extradepdir/$i" "$recipes/"
		done
	fi
	cd "$basedir/dependencies/recipes"
	for i in */; do
		[ -d "$recipes/$i" ] || ln -sf "$PWD/$i" "$recipes/" || cp -r "$i" "$recipes/"
	done

	set_define ARCH STRING "native-toolchain"

	set_define "CMAKE_SKIP_RPATH" "BOOL" "ON"
	load_config "$file"

	target="${defs_ARCH#*:}"
	"$basedir/toolchains/install-crosscompiler.sh" "$target"
	"$basedir/toolchains/bin/cget" -p "$prefix" init -t "$basedir/toolchains/$target.cmake" --ccache

	set_define ARCH
	set -- -DCMAKE_INSTALL_PREFIX:STRING="$prefix/output"
	for name in $defs; do
		eval "type=\"\$defs_$name\""
		val="${type#*:}"
		type="${type%%:*}"
		#echo "$name: $val"
		set -- "$@" "-D$name:$type=$val"
	done

	( $trace
	"$basedir/toolchains/bin/cget" \
		-p "$prefix" install $verbose \
		$deps \
		"$@" \
		-DCMAKE_INSTALL_PREFIX:STRING="$prefix" \
		-G "$generator"; ) \
		|| die "Dependencies of configuration '$config' failed"
	if [ -f "$prefix/forte/build/CMakeCache.txt" -a "$basedir/dependencies/recipes/forte/build.cmake" -nt "$prefix/forte/build/CMakeCache.txt" ]; then
		rm -rf "$prefix/forte"
	fi
	( $trace
		set +e
		"$basedir/toolchains/bin/cget" \
			-p "$prefix" build -T install $verbose \
			-B "$prefix" \
			-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
			"$@" forte \
			-G "$generator"
		echo "Exit Status: $?"
	) 2>&1 | tee "$prefix.log"
	[ ! -f "$srcdir/__cget_sh_CMakeLists.txt" ] || mv "$srcdir/__cget_sh_CMakeLists.txt" "$srcdir/CMakeLists.txt"
	"$basedir/toolchains/etc/package-dynamic.sh" "$target" "$prefix/output/bin/forte" || true

	[ -z "$keep_going" ] || return 0
	[ "$(tail -n 1 "$prefix.log")" = "Exit Status: 0" ] || die "Build of configuration '$config' failed"

	create_compile_commands_json "$config"

	if [ -n "$deploy" ]; then
		(
			cd "$prefix"
			exec "$SHELL" -c "$deploy"
		)
	fi
}

################################################################################
### main script
################################################################################

trace=
verbose=
generator=Ninja
while [ -n "$1" ]; do
	case "$1" in
		-v) verbose="-v"; generator="Unix Makefiles"; export MAKEFLAGS=-j1; export NINJAFLAGS=-j1; set_define CMAKE_VERBOSE_MAKEFILE BOOL ON;; # export trace="set -x";;
		-d) export trace="set -x";;
		-c) compile_commands=1;;
		-k) keep_going=1;;
		-h) echo "Usage: $0 [-v] [-c] [-k] [config-name ...]" >&2; exit 0;;
		-*) echo "Unknown flag: $1 -- ignoring";;
		*) break;
	esac
	shift
done

update_forte_build_workaround

if [ $# = 0 ]; then
	set -- configurations/*.txt
elif [ -d "$1" ]; then
	cd "$1"
	set -- *.txt
fi

for i in "$@"; do
	[ -f "$i" ] || i="configurations/$i.txt"
	config="$(cd "$(dirname "$i")"; echo "$PWD/$(basename "$i")")"
	( cd "$basedir"; build_one "$config"; )
done
