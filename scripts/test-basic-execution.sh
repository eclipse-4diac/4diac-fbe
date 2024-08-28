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

scripts="$(dirname "$0")"

die() { echo "$*" >&2; exit 1; }
run() {
	case "$1" in
		*.exe) wine "$@";;
		*) "$@";;
	esac
}

for i in "$@"; do (
	i="${i%/}"
	[ -f "$i.log" ] || die "Error in dependencies: $i"
	tail -n 1 "$i.log" | grep -B 1 "Exit Status: [^0]" && die
	run "$i"/output/bin/forte*  -f "$scripts"/HelloWorld.fboot > "$i.out" 2>&1 || die "Could not execute $i forte"
	mv helloworld.txt "$i.txt" || die "Forte $i did not run"
	grep "^'Hello World!';" "$i.txt" > /dev/null || die "Forte $i did not run correctly"
	echo "$i: OK"
); done
