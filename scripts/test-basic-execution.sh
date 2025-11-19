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

scripts="$(cd "$(dirname "$0")"; pwd)"

die() { echo "$*" >&2; exit 1; }

run_isolated() {
	case "`file "$1"`" in
	*"shell script"*)
		# gnu toolchain wrapper script, isolate from system files
		cp "$scripts/../toolchains/bin/sh" bin
		unshare --user --map-root-user --mount-proc --pid --fork /usr/sbin/chroot . "$@";;
	*x86-64*)
		# native binary, isolate from system files
		unshare --user --map-root-user --mount-proc --pid --fork /usr/sbin/chroot . "$@";;
	*)
		# foreign binary, assume system has appropriate binfmt/qemu config
		"$@";;
	esac
}

run_wine() {
	export WINEPREFIX="$PWD/.wine"
	wine "$@"
}

run() {
	case "$1" in
		*.exe) run_wine "$@";;
		*) run_isolated "$@";;
	esac
}

for i in "$@"; do (
	i="${i%/}"
	cd "$i"
	[ -f "forte.log" ] || die "Forte dependencies did not build: $i"
	tail -n 1 "forte.log" | grep "### Finished successfully." > /dev/null || die "Forte did not build successfully: $i"
	case "$i" in
	*-minimal)
		cp "$scripts"/HelloWorld.fboot helloworld.fboot;;
	*)
		cp "$scripts"/HelloWorld-OPCUA.fboot helloworld.fboot;;
	esac
	run ./output/bin/forte* -f helloworld.fboot -op 61498 > "forte.out" 2>&1 || die "Could not execute $i forte"
	grep "^'Hello World!';" "helloworld.txt" > /dev/null || die "Forte $i did not run correctly"
	echo "$i: OK"
); done
