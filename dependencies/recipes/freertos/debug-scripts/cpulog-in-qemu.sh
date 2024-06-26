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

script="$1"
shift
[ -x "$script" ] || { echo "Usage: $0 <path-to-run-script> <kernel>" >&2; exit 1; }
"$script" "$@" -singlestep -d nochain,cpu 2>&1| sed -e 's/R15=/                          /' > "$1".cpulog
