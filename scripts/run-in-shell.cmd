#!/bin/sh
echo \" <<'__________________________' >/dev/null ">NUL "
@echo off
REM ********************************************************************************
REM  Copyright (c) 2018, 2025 OFFIS e.V.
REM 
REM  This program and the accompanying materials are made available under the
REM  terms of the Eclipse Public License 2.0 which is available at
REM  http://www.eclipse.org/legal/epl-2.0.
REM 
REM  SPDX-License-Identifier: EPL-2.0
REM  
REM  Contributors:
REM     Jörg Walter - initial implementation
REM  *******************************************************************************/
REM 
rem CMD.EXE Batch File
cls

setlocal
set basedir=%~dp0\..

if not exist %basedir%\forte\CMakeLists.txt goto incomplete
if not exist %basedir%\toolchains\etc\install.cmd goto incomplete

if exist %basedir%\toolchains\bin\cget goto noinstall
	pushd %basedir%\toolchains
	call etc\install.cmd
	if errorlevel 1 exit /b
	popd

:noinstall

%basedir%\toolchains\bin\sh.exe %*
exit /b

:incomplete
echo ERROR: Your 4diac FBE directory seems to be incomplete. Please use a release download
echo or make sure you use the '--recursive' flag when cloning the git repository.
pause
exit /b
__________________________
# Shell Script
set -e

basedir="$(cd "$(dirname "$0")/.."; pwd)"
[ -d "$basedir/toolchains" ] || exec "$(readlink -f "$0")" "$@"

for i in forte/CMakeLists.txt toolchains/etc/install.sh; do
	if [ ! -f "$basedir/$i" ]; then
		echo "ERROR: Your 4diac FBE directory seems to be incomplete. Please use a release download" >&2
		echo "or make sure you use the '--recursive' flag when cloning the git repository." >&2
		exit 1
	fi
done

if [ ! -x "$basedir/toolchains/bin/cget" ]; then
	( cd "$basedir/toolchains" && "./etc/install.sh"; )
fi

exec "$basedir/toolchains/bin/sh" "$@"
